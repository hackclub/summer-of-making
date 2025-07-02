# frozen_string_literal: true

module ApplicationHelper
  include MarkdownHelper
  include Pagy::Frontend

  def mobile_device?
    request.user_agent&.match?(
      /Mobile|webOS|iPhone|iPad|iPod|Android|BlackBerry|IEMobile|Opera Mini/i
    )
  end

  def format_seconds(seconds)
    return "0h 0m" if seconds.nil? || seconds.zero?

    hours = seconds / 3600
    minutes = (seconds % 3600) / 60

    "#{hours}h #{minutes}m"
  end

  def admin_tool(class_name = "", element = "div", **, &)
    return unless current_user&.is_admin?

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
    unlocked = current_user.identity_vault_id.present? && current_user.verification_status != :ineligible

    case tab
    when :campfire
      true
    when :explore
      unlocked
    when :my_projects
      unlocked
    when :vote
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
end
