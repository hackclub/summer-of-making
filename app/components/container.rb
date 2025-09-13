# frozen_string_literal: true

class C::Container < C::Base
  extend Literal::Properties
  include Phlex::Rails::Helpers::ImageTag


  prop :attr, Hash, default: -> { {} }
  prop :full_height, _Boolean, default: false
  prop :css_classes, String, default: ""
  prop :no_padding, _Boolean, default: false
  prop :no_parchment, _Boolean, default: false

  DEFAULT_CLASSES = "flex flex-col"
  ORGANIC_CARD_BASE = "organic-card"
  ORGANIC_CARD_FULL = "organic-card h-full"
  PARCHMENT_STYLE = "padding: 16px 16px 16px 0;"

  # Pre-computed class combinations
  HEADER_WRAPPER_BASE = "w-full h-[20px] flex relative"
  HEADER_FLEX_BASE = "flex w-full"
  HEADER_FLEX_NO_PADDING = "flex w-full h-min absolute z-10"

  MAIN_WRAPPER_BASE = "flex -mt-[1px] relative"
  MAIN_WRAPPER_FULL = "flex -mt-[1px] relative h-full"

  CONTENT_BG = "bg-linear-to-b from-[#E6D4BE] to-[#F6DBBA] h-full w-full flex-1"

  FOOTER_WRAPPER = "w-full flex ml-[1px]"

  private

  def view_template(&block)
    div(**container_attrs) do
      if @no_parchment
        render_simple_container(&block)
      else
        render_parchment_container(&block)
      end
    end
  end

  def render_simple_container(&block)
    div(class: organic_card_class, style: PARCHMENT_STYLE, &block)
  end

  def render_parchment_container(&block)
    render_header
    render_main_content(&block)
    render_footer
  end

  def render_header
    if @no_padding
      div(class: HEADER_WRAPPER_BASE) { render_header_content }
    else
      render_header_content
    end
  end

  def render_header_content
    div(class: header_flex_class) do
      div { image("container/container-tl.svg", class: "-mr-[1px] max-w-none") }
      image(header_middle_image, class: header_middle_class)
      div { image(header_right_image, class: "max-w-none") }
    end
  end

  def render_main_content(&block)
    div(class: main_wrapper_class) do
      # Left spacer
      div(class: left_spacer_class)

      # Left border with clipping
      div(class: left_border_wrapper_class, style: left_border_style) do
        image(left_border_image, class: left_border_image_class)
      end

      # Content area
      div(class: CONTENT_BG) do
        div(class: "parchment-texture") if @css_classes.include?("faq-con")
        yield if block
      end

      # Right spacer
      div(class: right_spacer_class)

      # Right border with clipping
      div(class: right_border_wrapper_class, style: right_border_style) do
        image(right_border_image, class: right_border_image_class)
      end
    end
  end

  def render_footer
    div(class: FOOTER_WRAPPER) do
      div { image("container/container-bl.svg", class: "-mr-[1px] max-w-none") }
      image("container/container-bm.svg", class: "w-full h-[54px] -mr-[1px]")
      div { image("container/container-br.svg", class: "max-w-none") }
    end
  end

  # Optimized class and attribute helpers
  def container_attrs
    @attr.merge(class: final_container_class)
  end

  def final_container_class
    classes = [ DEFAULT_CLASSES, @css_classes, @attr[:class] ].compact
    classes.empty? ? DEFAULT_CLASSES : classes.join(" ")
  end

  def organic_card_class
    @full_height ? ORGANIC_CARD_FULL : ORGANIC_CARD_BASE
  end

  def header_flex_class
    @no_padding ? HEADER_FLEX_NO_PADDING : HEADER_FLEX_BASE
  end

  def header_middle_image
    @no_padding ? "container/container-tm-np.svg" : "container/container-tm.svg"
  end

  def header_middle_class
    @no_padding ? "w-full h-[19px] -mr-[1px]" : "w-full h-[53px] -mr-[1px]"
  end

  def header_right_image
    @no_padding ? "container/container-tr-np.svg" : "container/container-tr.svg"
  end

  def main_wrapper_class
    @full_height ? MAIN_WRAPPER_FULL : MAIN_WRAPPER_BASE
  end

  def left_spacer_class
    @no_padding ? "w-[23px] h-full" : "w-[46px] h-full"
  end

  def left_border_wrapper_class
    "ml-[1px] h-full absolute top-0 bottom-0"
  end

  def left_border_style
    @no_padding ? "clip-path: inset(28px 0 0 0)" : nil
  end

  def left_border_image
    @no_padding ? "container/container-ml-np.svg" : "container/container-ml.svg"
  end

  def left_border_image_class
    width = @no_padding ? "25px" : "46px"
    "w-[#{width}] h-full bg-linear-to-b from-[#E6D4BE] to-[#F6DBBA]"
  end

  def right_spacer_class
    @no_padding ? "w-[18px] h-full" : "w-[36px] h-full"
  end

  def right_border_wrapper_class
    "h-full absolute top-0 bottom-0 right-0"
  end

  def right_border_style
    @no_padding ? "clip-path: inset(28px 0 0 0)" : nil
  end

  def right_border_image
    @no_padding ? "container/container-mr-np.svg" : "container/container-mr.svg"
  end

  def right_border_image_class
    width = @no_padding ? "21px" : "36px"
    "w-[#{width}] h-full bg-linear-to-b from-[#E6D4BE] to-[#F6DBBA]"
  end

  def image(src, **attrs)
    image_tag(src, **attrs)
  end
end
