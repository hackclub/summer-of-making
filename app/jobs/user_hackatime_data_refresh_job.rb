# frozen_string_literal: true

# This refreshes every user's Hackatime Project data.
class UserHackatimeDataRefreshJob < ApplicationJob
  include UniqueJob

  queue_as :literally_whenever

  WARNING_THRESHOLD = 9.hours.to_i
  MAXIMUM_THRESHOLD = 10.hours.to_i
  WARNING_COOLDOWN = 2.hours.to_i

  def perform
    Rails.logger.tagged("UserHackatimeDataRefreshJob") do
      Rails.logger.info("Starting")
    end

    warning_count = 0

    User.where(has_hackatime: true).find_each do |user|
      user.refresh_hackatime_data_now

      user.projects.where(is_deleted: false).each do |project|
        # skip projects without a valid hackatime key
        next unless project.hackatime_keys.present? &&
                   project.hackatime_keys.all?(&:present?) &&
                   user.user_hackatime_data.present?

        begin
          if should_send_unlogged_warning?(project)
            send_unlogged_warning(project)
            warning_count += 1
          end
        rescue => e
          Rails.logger.error "Failed to process unlogged time warning for project #{project.id} (#{project.title}): #{e.message}"
          Honeybadger.notify(e, context: {
            job: "UserHackatimeDataRefreshJob",
            project_id: project.id,
            project_title: project.title,
            user_id: user.id,
            slack_id: user.slack_id,
            hackatime_keys: project.hackatime_keys
          })
        end
      end
    end

    Rails.logger.tagged("UserHackatimeDataRefreshJob") do
      Rails.logger.info("Ended - sent #{warning_count} unlogged time warnings")
    end
  end

  private

  def should_send_unlogged_warning?(project)
    unlogged_seconds = project.unlogged_time
    return false unless unlogged_seconds >= WARNING_THRESHOLD && unlogged_seconds < MAXIMUM_THRESHOLD

    cache_key = "unlogged_time_warning:#{project.id}"
    !Rails.cache.exist?(cache_key)
  end

  def send_unlogged_warning(project)
    user = project.user
    cache_key = "unlogged_time_warning:#{project.id}"

    unlogged_seconds = project.unlogged_time
    unlogged_hours = (unlogged_seconds / 3600.0).round(1)
    remaining_hours = ((MAXIMUM_THRESHOLD - unlogged_seconds) / 3600.0).round(1)

    message = build_warning_message(project, unlogged_hours, remaining_hours)

    SendSlackDmJob.perform_later(user.slack_id, message)
    Rails.cache.write(cache_key, Time.current.to_i, expires_in: WARNING_COOLDOWN)

    Rails.logger.info "Sent unlogged time warning to #{user.display_name} for project '#{project.title}' - #{unlogged_hours}h unlogged"
  rescue => e
    Rails.logger.error "Failed to send unlogged time warning for project #{project.id}: #{e.message}"
    Honeybadger.notify(e, context: {
      project_id: project.id,
      user_id: user&.id,
      slack_id: user&.slack_id
    })
  end

  def build_warning_message(project, unlogged_hours, remaining_hours)
    <<~MESSAGE.strip
      :siren-real: *Time to post a devlog!* :siren-real:#{' '}

      Your project *#{project.title}* has #{unlogged_hours} hours of unlogged coding time!

      You need to post a devlog before you reach 10 hours of unlogged time. If you exceed 10 hours of unlogged time, your overflowed time won't count towards your payout!

      📝 *#{remaining_hours} hours remaining* before you hit the limit.

      Head over to your project and create a devlog: #{project_url(project)}
    MESSAGE
  end

  def project_url(project)
    Rails.application.routes.url_helpers.project_url(project, host: "summer.hackclub.com")
  end
end
