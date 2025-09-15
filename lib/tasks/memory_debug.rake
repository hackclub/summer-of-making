namespace :memory do
  desc "Check memory usage once and trigger heap dumps if thresholds are exceeded"
  task check: :environment do
    def write_log(message) = puts "[MLD] #{Time.now.strftime("%Y-%m-%d %H:%M:%S")} #{message}"

    threshold_mb = ENV.fetch("MEMORY_THRESHOLD_MB", "700").to_i
    dump_dir = ENV.fetch("DUMP_DIR", "/tmp")

    begin
      write_log "Checking memory usage..."
      # In single container, look for puma/thrust processes
      puma_pids = `pgrep -f 'puma|thrust'`.split.map(&:to_i)

      unless puma_pids.any?
        write_log "No Puma processes found"
        exit 1
      end

      write_log "Found Puma PIDs: #{puma_pids.join(', ')}"

      puma_pids.each do |pid|
        # Get memory usage in KB from /proc/pid/status
        status_file = "/proc/#{pid}/status"
        next unless File.exist?(status_file)

        vmrss_line = File.readlines(status_file).find { |line| line.start_with?("VmRSS:") }
        next unless vmrss_line

        memory_kb = vmrss_line.match(/(\d+)/)[1].to_i
        memory_mb = memory_kb / 1024

        write_log "Puma PID #{pid}: #{memory_mb}MB"

        if memory_mb > threshold_mb
          write_log "Memory threshold exceeded for PID #{pid}! Triggering heap dump sequence..."

          # Send signal to start tracing
          Process.kill("TTIN", pid)
          write_log "Sent TTIN to PID #{pid} to start tracing"

          # Wait a bit for tracing to capture activity
          sleep 30

          # Take first heap dump
          Process.kill("TTOU", pid)
          write_log "Sent TTOU to PID #{pid} for first heap dump"

          sleep 5 # Allow dump to complete

          # Wait more to capture additional activity
          sleep 60

          # Take second heap dump
          Process.kill("TTOU", pid)
          write_log "Sent TTOU to PID #{pid} for second heap dump"

          sleep 5 # Allow dump to complete

          # Find and zip the recent heap dumps
          timestamp_pattern = Time.now.strftime("%Y%m%d")
          heap_files = Dir.glob("#{dump_dir}/heapdump-#{timestamp_pattern}*.json")

          if heap_files.any?
            zip_filename = "#{dump_dir}/memory-leak-dumps-#{Time.now.strftime('%Y%m%d-%H%M%S')}.zip"
            system("cd #{dump_dir} && zip #{zip_filename} #{heap_files.map { |f| File.basename(f) }.join(' ')}")
            write_log "Created zip file: #{zip_filename}"

            # Upload to Cloudflare R2 using ActiveStorage
            begin
              blob = ActiveStorage::Blob.create_and_upload!(
                io: File.open(zip_filename),
                filename: File.basename(zip_filename),
                content_type: "application/zip",
                service_name: Rails.application.config.active_storage.service
              )

              # Get the URL for the uploaded file
              file_url = Rails.application.routes.url_helpers.rails_blob_url(blob, host: ENV.fetch("RAILS_HOST", "localhost"))
              write_log "Uploaded to R2: #{file_url}"

              # Send Slack notification
              if ENV["SLACK_WEBHOOK_URL"]
                hostname = `hostname`.strip
                message = {
                  text: "🚨 Memory leak detected!",
                  attachments: [
                    {
                      color: "warning",
                      fields: [
                        {
                          title: "Server",
                          value: hostname,
                          short: true
                        },
                        {
                          title: "Memory Usage",
                          value: "#{memory_mb}MB (threshold: #{threshold_mb}MB)",
                          short: true
                        },
                        {
                          title: "Process PID",
                          value: pid.to_s,
                          short: true
                        },
                        {
                          title: "Heap Dump",
                          value: "<#{file_url}|Download ZIP>",
                          short: false
                        }
                      ],
                      footer: "Memory Leak Debugger",
                      ts: Time.now.to_i
                    }
                  ]
                }

                require "net/http"
                require "json"
                uri = URI(ENV["SLACK_WEBHOOK_URL"])
                http = Net::HTTP.new(uri.host, uri.port)
                http.use_ssl = true
                request = Net::HTTP::Post.new(uri)
                request["Content-Type"] = "application/json"
                request.body = message.to_json
                response = http.request(request)

                if response.code == "200"
                  write_log "Slack notification sent successfully"
                else
                  write_log "Failed to send Slack notification: #{response.code}"
                end
              end

              # Clean up local zip file
              File.delete(zip_filename)
              write_log "Cleaned up local zip file"

            rescue => e
              write_log "Failed to upload to R2: #{e.message}"
            end

            # Clean up individual dump files
            heap_files.each { |f| File.delete(f) }
            write_log "Cleaned up individual dump files"
          end
        end
      end

    rescue => e
      write_log "Error in memory check: #{e.message}"
    end
  end

  desc "Take a heap dump manually"
  task dump: :environment do
    puma_pids = `pgrep -f 'puma|thrust'`.split.map(&:to_i)

    if puma_pids.empty?
        write_log "No Puma processes found"
      exit 1
    end

    write_log "Found Puma PIDs: #{puma_pids.join(', ')}"

    puma_pids.each do |pid|
      write_log "Taking heap dump for PID #{pid}..."
      Process.kill("TTOU", pid)
    end
  end

  desc "Start memory tracing for all Puma processes"
  task trace: :environment do
    puma_pids = `pgrep -f 'puma|thrust'`.split.map(&:to_i)

    if puma_pids.empty?
      write_log "No Puma processes found"
      exit 1
    end

    write_log "Found Puma PIDs: #{puma_pids.join(', ')}"

    puma_pids.each do |pid|
      write_log "Starting memory tracing for PID #{pid}..."
      Process.kill("TTIN", pid)
    end
  end
end
