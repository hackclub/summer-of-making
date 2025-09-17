# frozen_string_literal: true

class C::Card < C::Base
  extend Literal::Properties

  prop :title, _String?
  prop :subtitle, _String?
  prop :image, _String?
  prop :footer, _String?
  prop :padding, String, default: "md"
  prop :hover, _Boolean, default: false
  prop :shadow, String, default: "md"
  prop :css_classes, String, default: ""
  prop :data, Hash, default: -> { {} }

  BASE_CLASSES = "rounded-md border-2 border-[rgba(124,74,51,0.1)] bg-[radial-gradient(circle_at_50%_50%,_#F6DBBA,_#E6D4BE)] flex flex-col"

  PADDING_CLASSES = {
    "sm" => "p-3",
    "md" => "p-4",
    "lg" => "p-6"
  }.freeze

  SHADOW_CLASSES = {
    "sm" => "shadow-sm",
    "md" => "shadow-md",
    "lg" => "shadow-lg"
  }.freeze

  HOVER_CLASS = "transition-transform hover:-translate-y-1"

  IMAGE_WRAPPER_CLASSES = "relative w-full h-48 mb-4"
  IMAGE_CLASSES = "w-full h-full object-cover rounded-t-md"
  HEADER_WRAPPER_CLASSES = "mb-4"
  TITLE_CLASSES = "text-xl font-semibold"
  CONTENT_WRAPPER_CLASSES = "flex-1 flex flex-col"
  FOOTER_WRAPPER_CLASSES = "mt-4 pt-4 border-t border-gray-200"

  private

  def view_template(&block)
    div(class: final_classes, data: final_data_attrs) do
      render_image if @image
      render_header if @title || @subtitle
      render_content(&block)
      render_footer if @footer
    end
  end

  def render_image
    div(class: IMAGE_WRAPPER_CLASSES) do
      image_tag(@image, class: IMAGE_CLASSES)
    end
  end

  def render_header
    div(class: HEADER_WRAPPER_CLASSES) do
      h3(class: TITLE_CLASSES) { @title } if @title
      p { @subtitle } if @subtitle
    end
  end

  def render_content(&block)
    div(class: CONTENT_WRAPPER_CLASSES, &block)
  end

  def render_footer
    div(class: FOOTER_WRAPPER_CLASSES) { @footer }
  end

  def final_classes
    parts = [ BASE_CLASSES, padding_class, shadow_class ]
    parts << HOVER_CLASS if @hover
    parts << @css_classes unless @css_classes.empty?
    parts.join(" ")
  end

  def padding_class
    PADDING_CLASSES[@padding] || PADDING_CLASSES["md"]
  end

  def shadow_class
    SHADOW_CLASSES[@shadow] || SHADOW_CLASSES["md"]
  end

  def final_data_attrs
    {
      padding: @padding,
      hover: @hover,
      shadow: @shadow
    }.merge(@data)
  end
end
