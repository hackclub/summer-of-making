# frozen_string_literal: true

# Preserve the existing controllers' redirects and API 404s for out-of-range pages.
Pagy::OPTIONS[:raise_range_error] = true
Pagy::OPTIONS.freeze
