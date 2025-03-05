# frozen_string_literal: true

require 'uri'

require_relative 'client'
require_relative 'response/builder'

module Angus
  module Remote
    module Settings
      @mutex = Mutex.new

      def self.add_option(name, default_value)
        define_singleton_method(name) do
          @mutex.synchronize do
            instance_variable_get(:"@#{name}") || default_value
          end
        end

        define_singleton_method(:"#{name}=") do |value|
          @mutex.synchronize do
            instance_variable_set(:"@#{name}", value)
          end
        end
      end

      add_option(:default_timeout, 60)
      add_option(:redis, {})
      add_option(:configuration_file, 'config/services.yml')
    end
  end
end
