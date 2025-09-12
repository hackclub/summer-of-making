# frozen_string_literal: true

class C::ButtonTo < C::ClickableBase
  include Phlex::Rails::Helpers::ButtonTo

  prop :target, _Union(String, Symbol)
  prop :method, Symbol, default: :post

  private

  def view_template
    button_to(@target, method: @method, class: final_class) { render_inner_content }
  end

  def text_class
    classes = [ "text-nowrap", "tracking-tight" ]
    classes << @text_attr[:class] if @text_attr[:class]
    classes.compact.join(" ")
  end
end
