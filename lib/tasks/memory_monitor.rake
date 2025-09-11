namespace :memory do
  desc "Monitor memory usage in production"
  task monitor: :environment do
    puts "Starting memory monitoring (Ctrl-C to stop)..."
    
    while true
      puma_pids = `find /proc -name cmdline -exec grep -l puma {} \\; 2>/dev/null | grep -v task | head -20`.strip.split("\n")
      puma_pids = puma_pids.map { |path| path.split('/')[2] }.compact.uniq
      
      puma_pids.each do |pid|
        next unless File.exist?("/proc/#{pid}/status")
        
        memory_line = `cat /proc/#{pid}/status | grep VmRSS`.strip
        memory_mb = memory_line.split[1].to_i / 1024 if memory_line
        
        if memory_mb && memory_mb > 500
          puts "#{Time.now}: PID #{pid} using #{memory_mb}MB"
          
          if memory_mb > 1500
            puts "  WARNING: High memory usage detected!"
            
            # Count heap pages
            heap_count = `cat /proc/#{pid}/maps | grep -c "Ruby:GC" 2>/dev/null`.to_i
            puts "  Ruby GC heap pages: #{heap_count}"
            
            # Check file descriptors
            fd_count = `ls /proc/#{pid}/fd/ 2>/dev/null | wc -l`.to_i
            puts "  File descriptors: #{fd_count}"
          end
        end
      end
      
      sleep 30
    end
  end
  
  desc "Get current memory snapshot"
  task snapshot: :environment do
    memory_mb = `cat /proc/#{Process.pid}/status | grep VmRSS`.split[1].to_i / 1024
    gc_stats = GC.stat
    
    puts "Memory: #{memory_mb}MB"
    puts "GC Pages: #{gc_stats[:heap_allocated_pages]}"
    puts "Objects: #{ObjectSpace.count_objects.values.sum}"
    
    # Sample large objects
    counts = Hash.new(0)
    ObjectSpace.each_object { |obj| counts[obj.class] += 1 rescue counts['BasicObject'] += 1 }
    large_counts = counts.select { |k,v| v > 10000 }.sort_by(&:last).reverse.first(10)
    
    puts "\nLarge object classes (>10k instances):"
    large_counts.each { |k,v| puts "  #{k}: #{v}" }
  end
  
  desc "Generate heap dump for analysis"
  task :heap_dump, [:pid] => :environment do |t, args|
    pid = args[:pid] || Process.pid
    
    puts "Generating heap dump for PID #{pid}..."
    
    # Enable object allocation tracing
    ObjectSpace.trace_object_allocations_start
    
    dump_path = "/tmp/heap_dump_manual_#{pid}_#{Time.now.to_i}.json"
    
    File.open(dump_path, 'w') do |f|
      ObjectSpace.dump_all(output: f)
    end
    
    puts "Heap dump saved to: #{dump_path}"
    puts "Size: #{File.size(dump_path)} bytes"
    puts "\nTo analyze:"
    puts "  gem install sheap"
    puts "  sheap #{dump_path}"
  end
  
  desc "Compare two heap dumps"
  task :compare_dumps, [:dump1, :dump2] => :environment do |t, args|
    dump1, dump2 = args[:dump1], args[:dump2]
    
    unless dump1 && dump2 && File.exist?(dump1) && File.exist?(dump2)
      puts "Usage: rails memory:compare_dumps[dump1.json,dump2.json]"
      exit 1
    end
    
    puts "Comparing heap dumps..."
    puts "Dump 1: #{dump1} (#{File.size(dump1)} bytes)"
    puts "Dump 2: #{dump2} (#{File.size(dump2)} bytes)"
    
    # Simple comparison - count objects by class in each dump
    def count_objects_in_dump(file)
      counts = Hash.new(0)
      File.foreach(file) do |line|
        obj = JSON.parse(line) rescue next
        if obj["type"]
          counts[obj["type"]] += 1
        end
      end
      counts
    end
    
    counts1 = count_objects_in_dump(dump1)
    counts2 = count_objects_in_dump(dump2)
    
    puts "\nObject count differences (dump2 - dump1):"
    all_types = (counts1.keys + counts2.keys).uniq
    differences = all_types.map do |type|
      diff = counts2[type] - counts1[type]
      [type, diff, counts1[type], counts2[type]]
    end
    
    differences.sort_by { |_, diff, _, _| -diff }.first(10).each do |type, diff, c1, c2|
      next if diff == 0
      puts "  #{type}: #{c1} -> #{c2} (#{diff > 0 ? '+' : ''}#{diff})"
    end
  end
end
