# frozen_string_literal: true

require 'bigdecimal'
require 'date'

module Angus
  module Unmarshalling
    def self.unmarshal_scalar(scalar, type)
      return nil if scalar.nil?

      case type
      when :string, :integer, :boolean, :object
        scalar
      when :date
        Date.iso8601(scalar)
      when :date_time
        DateTime.iso8601(scalar)
      when :decimal
        BigDecimal(scalar)
      else
        raise ArgumentError, "Unknown type: #{type}"
      end
    end
  end
end
