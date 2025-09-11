module MemoryMonitor
  extend ActiveSupport::Concern

  included do
    after_action :log_memory_usage, if: -> { should_log_memory? }
  end

  private

  def should_log_memory?
    # Log every 100 requests or if memory is high
    rand(100) == 0 || current_memory_mb > 500
  end

  def log_memory_usage
    memory_mb = current_memory_mb
    gc_stats = GC.stat
    
    if memory_mb > 1000  # Log when > 1GB
      Rails.logger.error "HIGH_MEMORY: #{memory_mb}MB | " \
        "PID: #{Process.pid} | " \
        "Objects: #{ObjectSpace.count_objects[:T_OBJECT] + ObjectSpace.count_objects[:T_STRING] + ObjectSpace.count_objects[:T_ARRAY]} | " \
        "GC Pages: #{gc_stats[:heap_allocated_pages]} | " \
        "Controller: #{params[:controller]}##{params[:action]}"
      
      # Sample large object classes
      sample_large_objects if memory_mb > 2000
    elsif memory_mb > 200
      Rails.logger.warn "MEMORY_WATCH: #{memory_mb}MB | PID: #{Process.pid} | GC Pages: #{gc_stats[:heap_allocated_pages]}"
    end
  end

  def current_memory_mb
    `cat /proc/#{Process.pid}/status | grep VmRSS`.split[1].to_i / 1024 rescue 0
  end

  def sample_large_objects
    counts = Hash.new(0)
    ObjectSpace.each_object { |obj| counts[obj.class] += 1 rescue counts['BasicObject'] += 1 }
    large_counts = counts.select { |k,v| v > 50000 }.sort_by(&:last).reverse.first(5)
    Rails.logger.error "LARGE_OBJECTS: #{large_counts.to_h}"
    
    # Generate heap dump when memory is critically high
    if memory_mb > 2500
      generate_heap_dump
    end
  rescue => e
    Rails.logger.error "Error sampling objects: #{e}"
  end
  
  def generate_heap_dump
    return unless Rails.env.production?
    
    dump_path = "/tmp/heap_dump_#{Process.pid}_#{Time.now.to_i}.json"
    Rails.logger.error "GENERATING_HEAP_DUMP: #{dump_path}"
    
    # Start object allocation tracing if not already started
    ObjectSpace.trace_object_allocations_start
    
    # Dump the heap
    File.open(dump_path, 'w') do |f|
      ObjectSpace.dump_all(output: f)
    end
    
    Rails.logger.error "HEAP_DUMP_COMPLETE: #{dump_path} (#{File.size(dump_path)} bytes)"
    
    # Keep only the last 3 dumps to avoid filling disk
    cleanup_old_dumps
  rescue => e
    Rails.logger.error "Error generating heap dump: #{e}"
  end
  
  def cleanup_old_dumps
    dumps = Dir.glob("/tmp/heap_dump_*.json").sort
    dumps[0..-4].each { |dump| File.delete(dump) rescue nil }
  end
end
