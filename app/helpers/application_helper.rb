# frozen_string_literal: true

module ApplicationHelper
  include MarkdownHelper
  include Pagy::Frontend

  def mobile_device?
    request.user_agent&.match?(
      /Mobile|webOS|iPhone|iPad|iPod|Android|BlackBerry|IEMobile|Opera Mini/i
    )
  end

  def format_seconds(seconds, include_days: false)
    # 3660 => "1h 1m"
    # 3600 => "1h"
    # 60 => "1m"
    # 0 => "0h 0m"

    # 86400, include_days: true => "1d 0h 0m"

    return "0h 0m" if seconds.nil? || seconds.zero?

    days = seconds / 86_400 if include_days
    hours = seconds / 3600
    hours = hours % 24 if include_days
    minutes = (seconds % 3600) / 60

    result = []
    result << "#{days}d" if include_days && days.positive?
    result << "#{hours}h" if hours.positive?
    result << "#{minutes}m" if minutes.positive?
    result.join(" ")
  end

  def formal_seconds(seconds)
    # Mostly used on admin/reivewer pages where the underlying second count is important
    # 60 => "60 seconds (1 min)"

    pluralize(seconds, "second") + content_tag("em", " (#{format_seconds(seconds)})")
  end

  def admin_tool(class_name = "", element = "div", show_in_impersonate: false, **, &)
    return unless current_user&.admin_or_fraud_team_member? || (show_in_impersonate && current_impersonator&.admin_or_fraud_team_member?)

    concat content_tag(element,
                       class: "#{"p-2" unless element == "span"} border-2 border-dashed border-orange-500 bg-orange-500/10 w-fit h-fit #{class_name}", **, &)
  end

  def indefinite_articlerize(params_word)
    %w[a e i o u].include?(params_word[0].downcase) ? "an #{params_word}" : "a #{params_word}"
  end

  def shell_icon(width = "15px")
    image_tag("/shell.png", width:, style: "vertical-align:text-top")
  end

  def render_shells(amount)
    rounded_amount = amount.to_i
    (number_to_currency(rounded_amount, precision: 0) || "$?.??")
      .sub("$", shell_icon)
      .html_safe
  end

  def tab_unlocked?(tab)
    unlocked = current_user.identity_vault_id.present? && current_verification_status != :ineligible
    case tab
    when :campfire
      true
    when :explore
      unlocked
    when :my_projects
      unlocked
    when :vote
      unlocked
    when :map
      unlocked
    when :shop
      true
    else
      raise ArgumentError, "Unknown tab variant: #{tab}"
    end
  end

  def admin_user_visit(user)
    admin_tool("", "span") do
      render "shared/user_twiddles", user:
    end
  end

  def admin_project_visit(project)
    admin_tool("", "span") do
      render "shared/project_twiddles", project:
    end
  end

  def random_carousel_transform
    "rotate(#{rand(-3..3)}deg) scale(#{(rand(97..103).to_f / 100).round(2)}) translateY(#{rand(-8..8)}px)"
  end

  def sanitize_css(css)
    return "" if css.blank?
    Sanitize::CSS.stylesheet(css, Sanitize::Config::RELAXED)
  end
end
