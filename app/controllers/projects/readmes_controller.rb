class Projects::ReadmesController < ApplicationController
  include ActionView::Helpers::SanitizeHelper

  layout false

  def show
    @project = Project.find(params[:project_id])

    authorize @project, :show?


    if @project&.readme_link&.blank?
      @error_message = "No README link found"
      return
    end

    require "net/http"
    require "uri"
    require "redcarpet"

    begin
      uri = URI.parse(@project.readme_link)

      unless %w[http https].include?(uri.scheme&.downcase)
        @error_message = "Invalid URL scheme"
        return
      end

      response = nil
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 10) do |http|
        request = Net::HTTP::Get.new(uri)
        request["User-Agent"] = "HackClub-SummerOfMaking"
        response = http.request(request)
      end

      if response.is_a?(Net::HTTPSuccess)
        renderer = Redcarpet::Render::HTML.new(filter_html: true, no_images: false, no_styles: true)
        markdown = Redcarpet::Markdown.new(renderer)
        rendered_html = markdown.render(response.body)
        @readme_content = ActiveSupport::SafeBuffer.new(sanitize(rendered_html))

        expires_in 1.minute, public: true
      else
        @error_message = "Failed to fetch README: Status #{response.code}"
      end
    rescue URI::InvalidURIError
      @error_message = "Invalid README URL"
    rescue Net::OpenTimeout, Net::ReadTimeout
      @error_message = "Request timed out"
    rescue StandardError => e
      @error_message = "Failed to fetch README: #{e.message}"
    end
  end
end
