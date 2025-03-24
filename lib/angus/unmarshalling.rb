require 'bigdecimal'
require 'date'


module Angus
  module Unmarshalling

    def self.unmarshal_scalar(scalar, type)
      return nil if scalar.nil?

      case type
      when :string
        #scalar.force_encoding(Encoding::UTF_8)
        scalar
      when :integer
        scalar
      when :boolean
        scalar
      when :date
        Date.iso8601(scalar)
      when :date_time
        DateTime.iso8601(scalar)
      when :decimal
        if BigDecimal.respond_to?(:new)
          BigDecimal.new(scalar) # Para Ruby < 2.6
        else
          BigDecimal(scalar) # Para Ruby 2.6+
        end
      when :object
        scalar
      else
        raise ArgumentError, "Unkonwn type: #{type}"
      end
    end

  end
end
