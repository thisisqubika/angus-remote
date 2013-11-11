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
      DEFAULT_PUBLIC_KEY = '1234567'
      DEFAULT_PRIVATE_KEY = 'CHANGE ME!!'

      add_option(:default_timeout, DEFAULT_TIMEOUT)
      add_option(:public_key, DEFAULT_PUBLIC_KEY)
      add_option(:private_key, DEFAULT_PRIVATE_KEY)
      add_option(:redis, {})

    end

  end
end