# frozen_string_literal: true

class C::StyledButton < C::Base
  include Phlex::Rails::Helpers::ButtonTag
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::FormWith

  extend Literal::Properties

  prop :text, String
  prop :icon, _String?
  prop :link, _String?
  prop :link_target, String, default: ""
  prop :data, Hash, default: -> { {} }
  prop :kind, _Union?(String, Symbol), default: :primary
  prop :type, _Union?(String, Symbol), default: :button
  prop :fill_width, _Boolean, default: false
  prop :disabled, _Boolean, default: false
  prop :css_classes, String, default: ""
  prop :method, _Union?(String, Symbol)
  prop :onclick, _String?
  prop :id, _String?
  prop :title, _String?

  # Pre-computed class combinations for zero allocations
  KIND_CLASSES = {
    primary: "som-button-primary",
    secondary: "som-button-secondary",
    danger: "som-button-danger",
    buy: "som-button-buy"
  }.freeze

  ICON_CLASSES = "w-4 h-4"
  CONTENT_WRAPPER_CLASSES = "flex items-center justify-center gap-2"
  TEXT_WRAPPER_CLASSES = "flex items-center gap-1"

  private

  def view_template
    if @link
      if method_is_post?
        render_form_button
      else
        render_link_button
      end
    else
      render_button
    end
  end

  def render_form_button
    form_with(url: @link, method: :post, html: form_html_attrs) do
      button_tag(:submit, **button_attrs) { render_button_content }
    end
  end

  def render_link_button
    link_to(@link, **link_attrs) { render_button_content }
  end

  def render_button
    button_tag(@type, **button_attrs) { render_button_content }
  end

  def render_button_content
    div(class: CONTENT_WRAPPER_CLASSES) do
      render_icon if @icon
      span(class: TEXT_WRAPPER_CLASSES) { raw safe @text } # i trust you. sanitize whatever gets passed in here.
    end
  end

  def render_icon
    inline_svg("icons/#{@icon}", class: ICON_CLASSES)
  end

  def method_is_post?
    @method&.to_s&.downcase == "post"
  end

  def button_class
    parts = [ kind_class ]
    parts << "w-full" if @fill_width
    parts << "disabled" if @disabled
    parts << @css_classes unless @css_classes.empty?
    parts.join(" ")
  end

  def kind_class
    KIND_CLASSES[@kind.to_sym] || KIND_CLASSES[:primary]
  end

  def form_html_attrs
    attrs = { target: @link_target, class: "inline" }
    attrs.compact
  end

  def button_attrs
    attrs = {
      class: button_class,
      data: @data,
      disabled: @disabled,
      onclick: @onclick,
      id: @id,
      title: @title
    }
    attrs.compact
  end

  def link_attrs
    attrs = {
      class: button_class,
      data: @data,
      target: @link_target.empty? ? nil : @link_target,
      onclick: @onclick,
      id: @id,
      title: @title
    }
    attrs.compact
  end
end
