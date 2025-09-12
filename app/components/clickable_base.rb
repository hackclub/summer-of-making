# frozen_string_literal: true

class C::ClickableBase < C::Base
  extend Literal::Properties

  prop :text, String
  prop :css_class, String | NilClass, default: nil
  prop :icon, String | NilClass, default: nil
  prop :highlight, _Boolean, default: false
  prop :content_attr, Hash, default: -> { {} }
  prop :text_attr, Hash, default: -> { {} }
  prop :icon_size, String | NilClass, default: nil
  prop :underline_attr, Hash, default: -> { {} }
  prop :large, _Boolean, default: false
  prop :hop, _Boolean, default: false
  prop :animate_push, _Boolean, default: false

  private

  def render_inner_content
    span(class: content_class, **@content_attr.except(:class)) do
      render_icon if @icon
      span(class: text_class, **@text_attr.except(:class)) { @text }
    end

    div(class: underline_class, data: underline_data, **@underline_attr.except(:class, :data))
  end

  def render_icon
    inline_svg("icons/#{@icon}.svg", class: icon_class)
  end

  def base_class
    classes = [ "relative", "inline-block", "group", "py-2", "cursor-pointer" ]
    classes << "text-2xl" if @large
    classes.join(" ")
  end

  def final_class
    [ base_class, @css_class ].compact.join(" ")
  end

  def icon_class
    size = @icon_size || (@large ? "8" : "6")
    classes = [ "w-#{size}", "h-#{size}" ]
    classes << "mr-4" if @large
    classes.join(" ")
  end

  def content_class
    classes = [ "som-link-content" ]
    classes << "som-link-hop" if @hop
    classes << "som-link-push" if @animate_push
    classes << @content_attr[:class] if @content_attr[:class]
    classes.compact.join(" ")
  end

  def text_class
    classes = [ "text-nowrap", "tracking-tight" ]
    classes << @text_attr[:class] if @text_attr[:class]
    classes.compact.join(" ")
  end

  def underline_class
    base_underline = [
      "absolute", "transition-all", "duration-150", "bottom-1", "w-full",
      "pr-3", "box-content", "bg-som-highlight", "rounded-full", "z-0",
      "group-hover:opacity-100"
    ]

    if @large
      base_underline << "h-6"
    else
      base_underline.concat([ "h-4", "-right-[6px]" ])
    end

    base_underline << "opacity-0" unless @highlight
    base_underline << @underline_attr[:class] if @underline_attr[:class]

    base_underline.compact.join(" ")
  end

  def underline_data
    { kind: "underline" }.merge(@underline_attr[:data] || {})
  end
end
