module BlockKitHelpers
  def self.define_text_object(name, type, **defaults)
    define_method(name) do |text, **options|
      {
        type: type,
        text: text,
        **defaults,
        **options
      }.compact
    end
  end

  def self.define_block_element(name, type, &block)
    define_method(name) do |*args, **options|
      base_block = {
        type: type,
        block_id: options.delete(:block_id)
      }.compact

      result = if block_given?
          instance_exec(base_block, *args, **options, &block)
      else
          base_block.merge(options)
      end

      if defined?(@blocks) && @blocks
        @blocks << result
        result
      else
        result
      end
    end
  end

  def self.define_interactive_element(name, type, append_to_blocks: true, &block)
    define_method(name) do |*args, **options|
      base_element = {
        type: type
      }

      result = if block_given?
        instance_exec(base_element, *args, **options, &block)
      else
        base_element.merge(options)
      end.compact

      if append_to_blocks && defined?(@blocks) && @blocks
        @blocks << result
        result
      else
        result
      end
    end
  end

  def self.define_convenience_method(name, target_method, **defaults)
    define_method(name) do |*args, **options|
      send(target_method, *args, **defaults, **options)
    end
  end

  define_text_object :plain_text, "plain_text", emoji: false
  define_text_object :mrkdwn_text, "mrkdwn"

  define_block_element :header_block, "header" do |block, text, **options|
    block.merge(
      text: plain_text(text),
      **options,
    )
  end

  define_block_element :section_block, "section" do |block, text = nil, markdown: false, accessory: nil, fields: nil, **options|
    block[:text] = markdown ? mrkdwn_text(text) : plain_text(text) if text
    block[:accessory] = accessory if accessory
    block[:fields] = fields if fields
    block.merge(options)
  end

  define_block_element :divider_block, "divider" do |block, **options|
    block.merge(options)
  end

  define_block_element :context_block, "context" do |block, *elements, **options|
    block.merge(
      elements: elements.flatten,
      **options,
    )
  end

  define_block_element :actions_block, "actions" do |block, *elements, **options|
    block.merge(
      elements: elements.flatten,
      **options,
    )
  end

  define_interactive_element :button_element, "button", append_to_blocks: false do |element, text, action_id:, value: nil, url: nil, style: nil, confirm: nil, **options|
    element.merge(
      text: plain_text(text, emoji: true),
      action_id: action_id,
      value: value,
      url: url,
      style: style,
      confirm: confirm,
      **options,
    )
  end

  define_block_element :image_block, "image" do |block, image_url, alt_text, **options|
    block.merge(
      image_url: image_url,
      alt_text: alt_text,
      **options,
    )
  end

  define_interactive_element :static_select_element, "static_select" do |element, placeholder, action_id:, options: [], initial_option: nil, **opts|
    element.merge(
      placeholder: plain_text(placeholder),
      action_id: action_id,
      options: options,
      initial_option: initial_option,
      **opts,
    )
  end

  define_interactive_element :overflow_element, "overflow" do |element, action_id:, options: [], **opts|
    element.merge(
      action_id: action_id,
      options: options,
      **opts,
    )
  end

  define_method :option_object do |text, value, description: nil, url: nil, **options|
    {
      text: plain_text(text),
      value: value,
      description: description ? plain_text(description) : nil,
      url: url,
      **options
    }.compact
  end

  define_convenience_method :simple_section, :section_block, markdown: true

  define_method :section_with_button do |text, button_text, action_id:, button_value: nil, button_url: nil, markdown: true, **options|
    section_block(
      text,
      markdown: markdown,
      accessory: button_element(button_text, action_id: action_id, value: button_value, url: button_url),
      **options,
    )
  end

  define_convenience_method :header, :header_block
  define_convenience_method :divider, :divider_block
  define_convenience_method :section, :section_block
  define_convenience_method :context, :context_block
  define_convenience_method :actions, :actions_block
  define_convenience_method :button, :button_element
  define_convenience_method :image, :image_block
  define_convenience_method :select, :static_select_element
  define_convenience_method :overflow, :overflow_element

  def blocks(&block)
    @blocks = []
    instance_eval(&block)
    @blocks
  end
end
