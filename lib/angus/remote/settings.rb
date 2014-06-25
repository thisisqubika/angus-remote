require 'uri'

require_relative 'client'
require_relative 'response/builder'

module Angus
  module Remote

    module Settings

      def self.add_option(name, default_value)
        define_singleton_method(name) do
          instance_variable_get("@#{name}") || default_value
        end

        define_singleton_method("#{name}=") do |value|
          instance_variable_set("@#{name}", value)
        end
      end

      add_option(:default_timeout, 60)
      add_option(:redis, {})
      add_option(:configuration_file, 'config/services.yml')

    end

  end
end