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

      DEFAULT_TIMEOUT = 60

      add_option(:default_timeout, DEFAULT_TIMEOUT)
      add_option(:redis, {})

    end

  end
end