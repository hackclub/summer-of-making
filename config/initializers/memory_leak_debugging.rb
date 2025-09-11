Signal.trap("SIGTTIN") do
  puts "[MLD] mmkay, slowing everything down..."
  ObjectSpace.trace_object_allocations_start
  puts "[MLD] trace_object_allocations_start-ed"
end

Signal.trap("SIGTTOU") do
  filename = "/tmp/heapdump-#{Time.now.strftime('%Y%m%d-%H%M%S')}.json"
  File.open(filename, "w",) { |f| ObjectSpace.dump_all(output: f) }
  puts "[MLD] heap dump written to #{filename}, good luck soldier"
end
