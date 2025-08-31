class MoleBrowserService
  MOLE_HOST = "f4o0g8cgc8ckcogssw88ggsw.a.selfhosted.hackclub.com"
  DEFAULT_TIMEOUT = 300 # 5 minutes
  POLL_INTERVAL = 5 # seconds

  def initialize(timeout: DEFAULT_TIMEOUT)
    @timeout = timeout
    @max_attempts = timeout / POLL_INTERVAL
  end

  def execute_task(task_prompt, urls = [])
    # Submit job to mole service
    job_id = submit_job(task_prompt, urls)
    return { success: false, error: "Failed to submit job" } unless job_id

    Rails.logger.info "Submitted mole job #{job_id}"

    # Poll for completion
    poll_job(job_id)
  end

  def submit_batch_jobs(tasks)
    job_submissions = []

    tasks.each do |task|
      job_id = submit_job(task[:prompt], task[:urls])
      if job_id
        job_submissions << task.merge(job_id: job_id)
        Rails.logger.info "Submitted task as job #{job_id}"
      else
        Rails.logger.error "Failed to submit task: #{task[:name] || 'unnamed'}"
      end
    end

    job_submissions
  end

  def poll_batch_jobs(job_submissions)
    attempts = 0
    completed_jobs = Set.new

    while completed_jobs.size < job_submissions.size && attempts < @max_attempts
      attempts += 1

      job_submissions.each do |submission|
        next if completed_jobs.include?(submission[:job_id])

        job_data = check_job_status(submission[:job_id])
        next unless job_data

        case job_data["status"]
        when "completed"
          yield(submission, job_data, :completed) if block_given?
          completed_jobs.add(submission[:job_id])
        when "failed"
          yield(submission, job_data, :failed) if block_given?
          completed_jobs.add(submission[:job_id])
        when "running", "queued"
          # Still in progress, continue polling
        else
          Rails.logger.error "Unknown job status for #{submission[:job_id]}: #{job_data['status']}"
          completed_jobs.add(submission[:job_id])
        end
      end

      break if completed_jobs.size == job_submissions.size
      sleep(POLL_INTERVAL)
    end

    # Handle any remaining incomplete jobs
    incomplete_jobs = job_submissions.reject { |s| completed_jobs.include?(s[:job_id]) }
    incomplete_jobs.each do |submission|
      Rails.logger.error "Job #{submission[:job_id]} timed out"
      yield(submission, nil, :timeout) if block_given?
    end
  end

  private

  def submit_job(task_prompt, urls)
    uri = URI("https://#{MOLE_HOST}/run")

    response = make_authenticated_request(uri, Net::HTTP::Post, read_timeout: 30, open_timeout: 10) do |request|
      request["Content-Type"] = "application/json"
      request.body = {
        task: task_prompt,
        urls: urls,
        provider: "anthropic",
        model: "claude-3-5-haiku-latest",
        api_key: ENV["ANTHROPIC_API_KEY"]
      }.to_json
    end

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error "Failed to submit mole job: HTTP #{response.code}: #{response.body}"
      puts "ERROR: Failed to submit mole job: HTTP #{response.code}: #{response.body}"
      return nil
    end

    response_data = JSON.parse(response.body)
    response_data["job_id"]
  rescue => e
    Rails.logger.error "Mole job submission error: #{e.message}"
    puts "ERROR: Mole job submission error: #{e.message}"
    puts "ERROR: Backtrace: #{e.backtrace.first(5).join("\n")}"
    nil
  end

  def poll_job(job_id)
    attempts = 0

    loop do
      attempts += 1

      uri = URI("https://#{MOLE_HOST}/status/#{job_id}")
      response = make_authenticated_request(uri)

      unless response.is_a?(Net::HTTPSuccess)
        return { success: false, error: "Failed to check job status: #{response.code}" }
      end

      job_data = JSON.parse(response.body)

      case job_data["status"]
      when "completed"
        return job_data["result"] || { success: false, error: "No result in completed job" }
      when "failed"
        return { success: false, error: job_data["error"] || "Job failed" }
      when "running", "queued"
        if attempts >= @max_attempts
          return { success: false, error: "Job timed out after #{@timeout} seconds" }
        end

        log_polling_status(job_id, job_data["status"], attempts)
        sleep(POLL_INTERVAL)
        next
      else
        return { success: false, error: "Unknown job status: #{job_data['status']}" }
      end
    end
  rescue => e
    Rails.logger.error "Mole job polling error: #{e.message}"
    { success: false, error: e.message }
  end

  def check_job_status(job_id)
    uri = URI("https://#{MOLE_HOST}/status/#{job_id}")
    response = make_authenticated_request(uri)

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error "Failed to check job status for #{job_id}: #{response.code}"
      return nil
    end

    JSON.parse(response.body)
  rescue => e
    Rails.logger.error "Error checking job status for #{job_id}: #{e.message}"
    nil
  end

  protected

  def log_polling_status(job_id, status, attempts)
    puts "Job #{job_id} status: #{status} (attempt #{attempts}/#{@max_attempts})"
  end

  def make_authenticated_request(uri, request_type = Net::HTTP::Get, read_timeout: 10, open_timeout: 5)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = read_timeout
    http.open_timeout = open_timeout

    request = request_type.new(uri)
    request["Authorization"] = "Bearer #{ENV['MOLE_API_KEY']}"

    yield(request) if block_given?

    http.request(request)
  end
end
