# frozen_string_literal: true

require 'erb'
require 'yaml'

class FlavorTextService
  def self.generate_mole_message_for_decision(decision, reason = nil)
    # Map decision types to YAML paths - easily extensible
    decision_mappings = {
      "missing" => "readme_check.missing.flavor",
      "templated" => "readme_check.template.flavor", 
      "ai_generated" => "readme_check.ai_usage.flavor",
      "specific" => "readme_check.specific.flavor"
    }
    
    path = decision_mappings[decision.to_s]
    if path
      transcript(path)
    else
      # Try a convention-based path as fallback
      transcript("readme_check.#{decision}.flavor")
    end
  end

  def self.transcript(path)
    value = get_nested_value(flavor_data, path.split('.'))
    
    if value.is_a?(Array)
      # Process ERB for a random element from the array
      raw_text = value.sample
      process_erb(raw_text)
    elsif value.is_a?(String)
      # Process ERB for the string
      process_erb(value)
    else
      # Return the original path if value doesn't exist
      path
    end
  end

  private

  def self.flavor_data
    @flavor_data ||= load_flavor_data
  end

  def self.load_flavor_data
    file_path = Rails.root.join('app', 'services', 'flavor_text', 'mole.yml')
    YAML.safe_load_file(file_path)
  end

  def self.get_nested_value(hash, keys)
    keys.reduce(hash) do |current, key|
      return nil unless current.is_a?(Hash) && current.key?(key)
      current[key]
    end
  end

  def self.process_erb(text)
    return text unless text.include?('#{')
    
    # Safe ERB processing - only allow specific predefined expressions
    evaluated_text = text.gsub(/#\{([^}]+)\}/) do |match|
      expression = $1.strip
      
      case expression
      when 'self.mole_parts.sample'
        flavor_data['mole_parts'].sample
      when /\Aself\.mole_parts\.sample\z/
        flavor_data['mole_parts'].sample
      else
        # For safety, return the original text if we don't recognize the expression
        match
      end
    end
    
    evaluated_text
  end
end
