# frozen_string_literal: true

module Shop
  module Regionalizable
    extend ActiveSupport::Concern

    REGIONS = {
      "US" => { name: "United States", countries: [ "US" ] },
      "EU" => { name: "EU + UK", countries: [ "AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR", "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL", "PL", "PT", "RO", "SK", "SI", "ES", "SE", "GB" ] },
      "IN" => { name: "India", countries: [ "IN" ] },
      "CA" => { name: "Canada", countries: [ "CA" ] },
      "AU" => { name: "Australia", countries: [ "AU", "NZ" ] },
      "XX" => { name: "Rest of World", countries: [] } # Special case - everything else
    }.freeze

    REGION_CODES = REGIONS.keys.freeze

    class_methods do
      def region_columns
        @region_columns ||= REGION_CODES.flat_map do |code|
          [ "enabled_#{code.downcase}", "price_offset_#{code.downcase}" ]
        end
      end
    end

    included do
      # Define scope methods for each region
      REGION_CODES.each do |code|
        scope :"enabled_in_#{code.downcase}", -> { where("enabled_#{code.downcase}" => true) }
        scope :"disabled_in_#{code.downcase}", -> { where("enabled_#{code.downcase}" => [ false, nil ]) }
      end
    end

    def enabled_in_region?(region_code)
      return false unless REGION_CODES.include?(region_code.upcase)
      send("enabled_#{region_code.downcase}")
    end

    def price_for_region(region_code)
      return ticket_cost unless REGION_CODES.include?(region_code.upcase)

      # If item is enabled for this region, use regional pricing
      if enabled_in_region?(region_code)
        offset = send("price_offset_#{region_code.downcase}") || 0
        return ticket_cost + offset
      end

      # If item is not enabled for this region but is enabled for XX, use XX pricing
      if enabled_in_region?("XX")
        offset = send("price_offset_xx") || 0
        return ticket_cost + offset
      end

      # Fallback to base price (though this shouldn't happen in practice)
      ticket_cost
    end

    def regions_enabled
      REGION_CODES.select { |code| enabled_in_region?(code) }
    end

    def self.country_to_region(country_code)
      return "XX" if country_code.blank?

      REGIONS.each do |region_code, config|
        next if region_code == "XX" # Skip "rest of world" in initial search
        return region_code if config[:countries].include?(country_code.upcase)
      end

      "XX" # Default to "rest of world"
    end

    def self.region_name(region_code)
      REGIONS.dig(region_code.upcase, :name) || "Unknown Region"
    end

    def self.countries_for_region(region_code)
      REGIONS.dig(region_code.upcase, :countries) || []
    end
  end
end
