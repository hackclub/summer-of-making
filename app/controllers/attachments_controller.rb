# frozen_string_literal: true

class AttachmentsController < ApplicationController
  def upload
    render json: { error: "Summer of Making is archived. Uploads are closed." }, status: :gone
  end

  def download
    filename = params[:filename]

    safe = sanitize(filename)
    return head :not_found if safe.nil?

    temp_path = Rails.root.join("tmp", "uploads", safe)

    unless good_path?(temp_path)
      head :not_found
      return
    end

    if File.exist?(temp_path)
      send_file temp_path, disposition: "inline"
    else
      head :not_found
    end
  end

  private

  def sanitize(filename)
    return nil if filename.blank?

    sanitized = File.basename(filename)
    return nil unless sanitized.match?(/\A[a-zA-Z0-9._-]+\z/)
    return nil if sanitized.start_with?(".")

    sanitized
  end

  # double check that path to make sure its not funky
  def good_path?(path)
    uploads_dir = Rails.root.join("tmp/uploads").realpath
    begin
      path.realpath.to_s.start_with?(uploads_dir.to_s)
    rescue Errno::ENOENT
      false
    end
  end
end
