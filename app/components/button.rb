# frozen_string_literal: true

class C::Button < C::ClickableBase
  prop :data_attrs, Hash, default: -> { {} }
  prop :button_type, String, default: "button"

  private

  def view_template
    btn_attrs = { type: @button_type, class: final_class }
    btn_attrs[:data] = @data_attrs unless @data_attrs.empty?

    button(**btn_attrs) { render_inner_content }
  end

  def text_class
    classes = [ "text-nowrap", "tracking-tight" ]
    classes << @text_attr[:class] if @text_attr[:class]
    classes.compact.join(" ")
  end
end
