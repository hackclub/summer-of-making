namespace :memory do
  desc "Check memory usage once and trigger heap dumps if thresholds are exceeded"
  task check: :environment do
    threshold_mb = ENV.fetch("MEMORY_THRESHOLD_MB", "700").to_i
    dump_dir = ENV.fetch("DUMP_DIR", "/tmp")

    begin
      # In single container, look for puma/thrust processes
      puma_pids = `pgrep -f 'puma|thrust'`.split.map(&:to_i)

      puma_pids.each do |pid|
        # Get memory usage in KB from /proc/pid/status
        status_file = "/proc/#{pid}/status"
        next unless File.exist?(status_file)

        vmrss_line = File.readlines(status_file).find { |line| line.start_with?("VmRSS:") }
        next unless vmrss_line

        memory_kb = vmrss_line.match(/(\d+)/)[1].to_i
        memory_mb = memory_kb / 1024

        puts "[MLD] Puma PID #{pid}: #{memory_mb}MB"

        if memory_mb > threshold_mb
          puts "[MLD] Memory threshold exceeded for PID #{pid}! Triggering heap dump sequence..."

          # Send signal to start tracing
          Process.kill("TTIN", pid)
          puts "[MLD] Sent TTIN to PID #{pid} to start tracing"

          # Wait a bit for tracing to capture activity
          sleep 30

          # Take first heap dump
          Process.kill("TTOU", pid)
          puts "[MLD] Sent TTOU to PID #{pid} for first heap dump"

          sleep 5 # Allow dump to complete

          # Wait more to capture additional activity
          sleep 60

          # Take second heap dump
          Process.kill("TTOU", pid)
          puts "[MLD] Sent TTOU to PID #{pid} for second heap dump"

          sleep 5 # Allow dump to complete

          # Find and zip the recent heap dumps
          timestamp_pattern = Time.now.strftime("%Y%m%d")
          heap_files = Dir.glob("#{dump_dir}/heapdump-#{timestamp_pattern}*.json")

          if heap_files.any?
            zip_filename = "#{dump_dir}/memory-leak-dumps-#{Time.now.strftime('%Y%m%d-%H%M%S')}.zip"
            system("cd #{dump_dir} && zip #{zip_filename} #{heap_files.map { |f| File.basename(f) }.join(' ')}")
            puts "[MLD] Created zip file: #{zip_filename}"

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
              puts "[MLD] Uploaded to R2: #{file_url}"

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
                  puts "[MLD] Slack notification sent successfully"
                else
                  puts "[MLD] Failed to send Slack notification: #{response.code}"
                end
              end

              # Clean up local zip file
              File.delete(zip_filename)
              puts "[MLD] Cleaned up local zip file"

            rescue => e
              puts "[MLD] Failed to upload to R2: #{e.message}"
            end

            # Clean up individual dump files
            heap_files.each { |f| File.delete(f) }
            puts "[MLD] Cleaned up individual dump files"
          end
        end
      end

    rescue => e
      puts "[MLD] Error in memory check: #{e.message}"
    end
  end

  desc "Take a heap dump manually"
  task dump: :environment do
    puma_pids = `pgrep -f 'puma|thrust'`.split.map(&:to_i)

    if puma_pids.empty?
      puts "[MLD] No Puma processes found"
      exit 1
    end

    puts "[MLD] Found Puma PIDs: #{puma_pids.join(', ')}"

    puma_pids.each do |pid|
      puts "[MLD] Taking heap dump for PID #{pid}..."
      Process.kill("TTOU", pid)
    end
  end

  desc "Start memory tracing for all Puma processes"
  task trace: :environment do
    puma_pids = `pgrep -f 'puma|thrust'`.split.map(&:to_i)

    if puma_pids.empty?
      puts "[MLD] No Puma processes found"
      exit 1
    end

    puts "[MLD] Found Puma PIDs: #{puma_pids.join(', ')}"

    puma_pids.each do |pid|
      puts "[MLD] Starting memory tracing for PID #{pid}..."
      Process.kill("TTIN", pid)
    end
  end
end
