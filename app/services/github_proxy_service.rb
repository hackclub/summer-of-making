# frozen_string_literal: true

require "net/http"
require "uri"
require "json"
require "timeout"

class GithubProxyService
  BASE_URL = "https://gh-proxy.hackclub.com/gh"

  class GithubProxyError < StandardError
    attr_reader :status_code, :response_body

    def initialize(message, status_code = nil, response_body = nil)
      super(message)
      @status_code = status_code
      @response_body = response_body
    end
  end

  def initialize(api_key: nil)
    @api_key = api_key || ENV["GH_PROXY_KEY"]
    raise ArgumentError, "GitHub proxy API key is required" unless @api_key
  end

  def get_repository_languages(owner, repo)
    path = "repos/#{owner}/#{repo}/languages"
    get_request(path)
  end

  def get_repository_info(owner, repo)
    path = "repos/#{owner}/#{repo}"
    get_request(path)
  end

  private

  def get_request(path)
    # Construct full URL directly to avoid URI.join issues
    full_url = "#{BASE_URL}/#{path}"
    uri = URI(full_url)
    Rails.logger.info "Making request to: #{uri}"

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri)
    request["X-API-Key"] = @api_key
    request["Accept"] = "application/json"
    request["User-Agent"] = "SOM-Rails-App/1.0"

    response = http.request(request)
    Rails.logger.info "Response status: #{response.code}"

    case response.code.to_i
    when 200..299
      JSON.parse(response.body)
    when 404
      raise GithubProxyError.new("Repository not found", 404, response.body)
    when 401, 403
      raise GithubProxyError.new("Authentication failed or rate limited", response.code.to_i, response.body)
    when 500..599
      raise GithubProxyError.new("GitHub proxy server error", response.code.to_i, response.body)
    else
      raise GithubProxyError.new("Unexpected response: #{response.code}", response.code.to_i, response.body)
    end
  rescue JSON::ParserError => e
    raise GithubProxyError.new("Invalid JSON response: #{e.message}")
  rescue Timeout::Error, Net::ReadTimeout, Net::OpenTimeout => e
    raise GithubProxyError.new("Request timeout: #{e.message}")
  rescue GithubProxyError
    raise # Re-raise our own errors without wrapping
  rescue StandardError => e
    raise GithubProxyError.new("Network error: #{e.message}")
  end
end
