# frozen_string_literal: true

module C
  extend Phlex::Kit
end

Rails.autoloaders.main.push_dir(
  Rails.root.join("app/components"), namespace: C
)
