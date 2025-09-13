# frozen_string_literal: true

class C::Base < Phlex::HTML
  include Phlex::Rails::Helpers::Routes
  register_output_helper :inline_svg

  if Rails.env.development?
    def before_template
      comment { "before #{self.class.name}" }
      super
    end
  end
end
