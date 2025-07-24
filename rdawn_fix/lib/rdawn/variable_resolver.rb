# frozen_string_literal: true

module Rdawn
  module VariableResolver
    # Resolves variables in input data using the provided context
    # Supports ${...} syntax with nested hash access like ${task1.output.user.name}
    def self.resolve(input_data, context)
      return input_data unless input_data
      
      deep_resolve(input_data, context)
    end

    private

    def self.deep_resolve(data, context)
      case data
      when Hash
        data.each_with_object({}) do |(key, value), resolved|
          resolved[key] = deep_resolve(value, context)
        end
      when Array
        data.map { |item| deep_resolve(item, context) }
      when String
        resolve_string_variables(data, context)
      else
        data
      end
    end

    def self.resolve_string_variables(string, context)
      # If the entire string is just a single variable reference, return the actual value
      if string.match(/^\$\{([^}]*)\}$/)
        variable_path = $1.strip
        return resolve_variable_path(variable_path, context)
      end
      
      # Match ${...} patterns and replace them with resolved values
      string.gsub(/\$\{([^}]*)\}/) do |match|
        variable_path = $1.strip
        resolved_value = resolve_variable_path(variable_path, context)
        
        # Convert to string for interpolation within larger strings
        resolved_value.to_s
      end
    end

    def self.resolve_variable_path(path, context)
      # Handle empty path
      if path.nil? || path.strip.empty?
        raise Rdawn::Errors::VariableResolutionError, "Variable path cannot be empty"
      end
      
      # Split the path by dots and traverse the context
      parts = path.split('.')
      current = context
      
      parts.each do |part|
        case current
        when Hash
          # Try both string and symbol keys
          if current.has_key?(part)
            current = current[part]
          elsif current.has_key?(part.to_sym)
            current = current[part.to_sym]
          else
            raise Rdawn::Errors::VariableResolutionError, 
                  "Cannot resolve '#{part}' in path '#{path}'"
          end
        when Object
          # Try to call the method if it exists
          if current.respond_to?(part)
            current = current.public_send(part)
          else
            raise Rdawn::Errors::VariableResolutionError, 
                  "Cannot resolve '#{part}' in path '#{path}'"
          end
        else
          raise Rdawn::Errors::VariableResolutionError, 
                "Cannot resolve '#{part}' in path '#{path}' - current value is not navigable"
        end
      end
      
      current
    rescue NoMethodError => e
      raise Rdawn::Errors::VariableResolutionError, 
            "Failed to resolve variable path '#{path}': #{e.message}"
    end
  end
end 