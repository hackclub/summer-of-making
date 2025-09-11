# Enable object allocation tracing in production when memory debugging is needed
if Rails.env.production? && ENV['ENABLE_MEMORY_DEBUGGING'] == 'true'
  Rails.logger.info "Enabling object allocation tracing for memory debugging"
  ObjectSpace.trace_object_allocations_start
end

# Add signal handler for manual heap dumps via USR2
if Rails.env.production?
  Signal.trap("USR2") do
    Thread.new do
      begin
        dump_path = "/tmp/heap_dump_signal_#{Process.pid}_#{Time.now.to_i}.json"
        Rails.logger.error "SIGNAL_HEAP_DUMP: Generating #{dump_path}"
        
        File.open(dump_path, 'w') do |f|
          ObjectSpace.dump_all(output: f)
        end
        
        Rails.logger.error "SIGNAL_HEAP_DUMP_COMPLETE: #{dump_path} (#{File.size(dump_path)} bytes)"
      rescue => e
        Rails.logger.error "SIGNAL_HEAP_DUMP_ERROR: #{e}"
      end
    end
  end
end
