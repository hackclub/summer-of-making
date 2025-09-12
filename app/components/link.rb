# frozen_string_literal: true

class C::Link < C::ClickableBase
  prop :target, _Union(String, Symbol)

  private

  def view_template
    a(href: @target, class: final_class) { render_inner_content }
  end

  def text_class
    classes = [ "text-nowrap", "tracking-tight", "pointer-events-none" ]
    classes << @text_attr[:class] if @text_attr[:class]
    classes.compact.join(" ")
  end
end
