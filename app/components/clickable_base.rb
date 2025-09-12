# frozen_string_literal: true

class C::ClickableBase < C::Base
  extend Literal::Properties

  prop :text, String
  prop :css_class, _String?
  prop :icon, _String?
  prop :highlight, _Boolean, default: false
  prop :content_attr, Hash, default: -> { {} }
  prop :text_attr, Hash, default: -> { {} }
  prop :icon_size, _String?
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

  BASE_CLASSES = "relative inline-block group py-2 cursor-pointer"
  BASE_CLASSES_LARGE = "relative inline-block group py-2 cursor-pointer text-2xl"
  CONTENT_BASE = "som-link-content"
  TEXT_BASE = "text-nowrap tracking-tight"
  UNDERLINE_BASE = "absolute transition-all duration-150 bottom-1 w-full pr-3 box-content bg-som-highlight rounded-full z-0 group-hover:opacity-100"
  UNDERLINE_LARGE = "#{UNDERLINE_BASE} h-6"
  UNDERLINE_SMALL = "#{UNDERLINE_BASE} h-4 -right-[6px]"
  UNDERLINE_HIDDEN_LARGE = "#{UNDERLINE_LARGE} opacity-0"
  UNDERLINE_HIDDEN_SMALL = "#{UNDERLINE_SMALL} opacity-0"

  def base_class
    @large ? BASE_CLASSES_LARGE : BASE_CLASSES
  end

  def final_class
    @css_class ? "#{base_class} #{@css_class}" : base_class
  end

  def icon_class
    size = @icon_size || (@large ? "8" : "6")
    base = "w-#{size} h-#{size}"
    @large ? "#{base} mr-4" : base
  end

  def content_class
    result = CONTENT_BASE
    result = "#{result} som-link-hop" if @hop
    result = "#{result} som-link-push" if @animate_push
    if @content_attr[:class]
      result = "#{result} #{@content_attr[:class]}"
    end
    result
  end

  def text_class
    @text_attr[:class] ? "#{TEXT_BASE} #{@text_attr[:class]}" : TEXT_BASE
  end

  def underline_class
    base = if @large
      @highlight ? UNDERLINE_LARGE : UNDERLINE_HIDDEN_LARGE
    else
      @highlight ? UNDERLINE_SMALL : UNDERLINE_HIDDEN_SMALL
    end

    @underline_attr[:class] ? "#{base} #{@underline_attr[:class]}" : base
  end

  def underline_data
    { kind: "underline" }.merge(@underline_attr[:data] || {})
  end
end
