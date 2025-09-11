# Memory Leak Debugging Flight Checklist

## 🚨 When Memory Issues Are Suspected

### Step 1: Confirm There's a Memory Leak

**Check server memory usage:**
```bash
# SSH into your production server
ssh your-production-server

# Check overall memory usage
free -h

# If using Docker, check container stats
docker stats --no-stream
```

**Signs of a memory leak:**
- Memory usage continuously growing over time
- Performance degradation (slower response times)
- Out of memory errors in logs
- Container/server restarts due to memory pressure

### Step 2: Identify Leaking Processes

**Find all running containers:**
```bash
docker ps
```

**Check memory usage of specific containers:**
```bash
# Replace 'web_container_name' with actual container name from docker ps
docker exec web_container_name cat /proc/1/status | grep VmRSS
```

**Find all Puma worker processes inside the container:**
```bash
# SSH into the container
docker exec -it web_container_name /bin/bash

# Find all Puma processes and their memory usage
find /proc -name cmdline -exec grep -l puma {} \; 2>/dev/null | while read f; do
  pid=$(echo $f | cut -d/ -f3)
  if [ -f "/proc/$pid/status" ]; then
    memory=$(cat /proc/$pid/status | grep VmRSS | awk '{print $2}')
    echo "PID $pid: ${memory} kB ($(($memory / 1024)) MB)"
  fi
done | sort -k3 -n
```

**Identify the highest memory consuming process:**
- Look for PIDs using > 1GB (> 1000000 kB)
- Note the PID of the worst offender

## 🔍 Generate Heap Dumps for Analysis

### Step 3: Take Initial Heap Dump

**Method A: Using Signal (Recommended)**
```bash
# Replace 'ACTUAL_PID' with the PID from Step 2
kill -USR2 ACTUAL_PID

# Check that the dump was created
ls -la /tmp/heap_dump_signal_*
```

**Method B: Using Rails Console**
```bash
# Only if Method A fails
docker exec web_container_name bundle exec rails memory:heap_dump
```

### Step 4: Wait and Take Second Heap Dump

**Wait 10-15 minutes for the leak to grow:**
```bash
# Check memory again to confirm it's still growing
cat /proc/ACTUAL_PID/status | grep VmRSS
```

**Take second dump:**
```bash
# Replace 'ACTUAL_PID' with same PID as before
kill -USR2 ACTUAL_PID

# List all dumps to identify the two files
ls -la /tmp/heap_dump_signal_* | sort
```

### Step 5: Copy Heap Dumps to Local Machine

**Copy files out of container:**
```bash
# Replace container_name and adjust timestamps
docker cp container_name:/tmp/heap_dump_signal_123_1641234567.json ./dump1.json
docker cp container_name:/tmp/heap_dump_signal_123_1641234890.json ./dump2.json

# Verify files copied
ls -la dump*.json
```

## 📊 Analyze the Heap Dumps

### Step 6: Compare Heap Dumps

**Install analysis tools:**
```bash
gem install sheap
```

**Compare the dumps:**
```bash
# Using our built-in comparison
docker exec web_container_name bundle exec rails memory:compare_dumps[/tmp/dump1.json,/tmp/dump2.json]
```

**Look for these warning signs:**
- Large increases in String, Array, or Hash objects
- Growing numbers of model instances (User, Project, etc.)
- Unusual object types with high counts

### Step 7: Deep Dive with Sheap

**Analyze the latest dump interactively:**
```bash
sheap dump2.json
```

**Key Sheap commands to run:**
```ruby
# Show object counts by class
puts "Top objects by count:"
diff.objects.group_by { |o| o["type"] }.map { |k,v| [k, v.count] }.sort_by(&:last).reverse.take(20).each { |k,v| puts "#{k}: #{v}" }

# Find retained objects (not garbage collected)
puts "\nRetained objects:"
diff.retained.group_by { |o| o["type"] }.map { |k,v| [k, v.count] }.sort_by(&:last).reverse.take(10).each { |k,v| puts "#{k}: #{v}" }

# Look for large strings
puts "\nLarge strings:"
diff.objects.select { |o| o["type"] == "STRING" && o["bytesize"].to_i > 1000 }.sort_by { |o| -o["bytesize"].to_i }.take(10).each { |o| puts "#{o["bytesize"]} bytes: #{o["value"]&.first(100)}..." }
```

## 🔧 Fix Common Memory Leak Patterns

### Pattern 1: Analytics/Tracking Objects

**Check for Ahoy events accumulating:**
```bash
# In Rails console
docker exec -it web_container_name bundle exec rails c

# Count recent Ahoy objects in memory
counts = Hash.new(0)
ObjectSpace.each_object { |obj| counts[obj.class] += 1 rescue nil }
puts "Ahoy::Event objects: #{counts[Ahoy::Event]}"
puts "Ahoy::Visit objects: #{counts[Ahoy::Visit]}"
```

**Fix:** Move analytics to background jobs or disable high-frequency tracking

### Pattern 2: External API Connection Leaks

**Check for unclosed HTTP connections:**
```bash
# Count file descriptors
ls /proc/ACTUAL_PID/fd/ | wc -l

# Check for many socket connections
ls -la /proc/ACTUAL_PID/fd/ | grep socket | wc -l
```

**Fix:** Ensure HTTP clients use connection pooling and timeouts

### Pattern 3: Large Object Retention

**Check for large cached objects:**
```ruby
# In sheap analysis
large_objects = diff.objects.select { |o| o["memsize"].to_i > 100000 }
large_objects.group_by { |o| o["type"] }.each { |k,v| puts "#{k}: #{v.count} objects, total: #{v.sum { |o| o["memsize"].to_i }} bytes" }
```

**Fix:** Review caching strategies, clear unused caches

## 🩹 Immediate Mitigation

### Step 8: Emergency Memory Release

**Force garbage collection:**
```bash
# In Rails console
docker exec web_container_name bundle exec rails runner "3.times { GC.start }; puts 'GC complete'"
```

**Restart individual workers (if using Puma):**
```bash
# Send TERM signal to highest memory worker
kill -TERM HIGHEST_MEMORY_PID

# Puma will automatically spawn a replacement
```

**Last resort - restart all workers:**
```bash
# Find master Puma process (usually PID 1 in container)
kill -USR1 1

# Or restart entire container
docker restart web_container_name
```

## 📈 Monitor and Prevent

### Step 9: Set Up Ongoing Monitoring

**Enable memory monitoring (already added to code):**
```bash
# Set environment variable in production
export ENABLE_MEMORY_DEBUGGING=true

# Restart to enable monitoring
docker restart web_container_name
```

**Monitor memory usage continuously:**
```bash
# Run in background to track memory over time
docker exec web_container_name bundle exec rails memory:monitor > memory_log.txt 2>&1 &
```

**Check logs regularly:**
```bash
# Look for HIGH_MEMORY warnings in Rails logs
docker logs web_container_name | grep "HIGH_MEMORY"

# Check for heap dump generation
docker logs web_container_name | grep "HEAP_DUMP"
```

### Step 10: Code Review Checklist

**Review recent changes for these patterns:**

- [ ] New caching that doesn't expire
- [ ] External API calls without connection limits  
- [ ] Large file processing without streaming
- [ ] Event tracking on high-traffic endpoints
- [ ] Global or class variables that accumulate data
- [ ] Circular references in object graphs
- [ ] Background jobs that don't clean up

**Prevention measures:**

- [ ] Add memory limits to image processing
- [ ] Use streaming for large file operations
- [ ] Implement connection pooling for external APIs
- [ ] Move heavy analytics to background jobs
- [ ] Regular heap dump analysis in staging
- [ ] Memory usage alerts in monitoring

## 📋 Emergency Contact Info

**When to escalate:**
- Memory usage > 4GB per worker
- Multiple workers affected simultaneously  
- Memory leak causes customer-facing downtime
- Unable to identify root cause within 2 hours

**Escalation checklist:**
- [ ] Gather heap dumps from steps above
- [ ] Document timeline of when leak started
- [ ] List recent deployments/changes
- [ ] Include memory monitoring logs
- [ ] Have staging environment ready for testing fixes

## 🧪 Testing Fixes

**Before deploying a fix:**

1. **Reproduce locally:**
   ```bash
   # Enable memory monitoring in development
   export ENABLE_MEMORY_DEBUGGING=true
   rails server
   ```

2. **Load test the suspected endpoint:**
   ```bash
   # Use simple load testing
   for i in {1..100}; do
     curl -s http://localhost:3000/suspected_endpoint > /dev/null
     echo "Request $i complete"
   done
   
   # Check memory usage
   rails memory:snapshot
   ```

3. **Deploy to staging first:**
   - Run heap dump analysis
   - Monitor for 2+ hours
   - Confirm memory is stable

4. **Deploy to production with monitoring:**
   - Deploy during low-traffic period
   - Monitor memory usage closely for 1 hour
   - Have rollback plan ready

---

**Remember:** Memory leaks are often subtle and may take time to manifest. Always monitor for at least 30 minutes after making changes.
