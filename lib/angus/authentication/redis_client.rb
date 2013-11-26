require 'redis'

module Angus
  module Authentication

    class RedisClient

      DEFAULT_NAMESPACE = ''

      def initialize(settings)
        settings = settings.dup
        @namespace = settings.delete(:namespace) || DEFAULT_NAMESPACE
        @settings = settings
      end

      def store_session_key(key, data)
        redis.set(add_namespace(key), data)
      end

      def get_session_key(key)
        redis.get(add_namespace(key))
      end

      def redis
        @redis ||= Redis.new(@settings)
      end

      def add_namespace(key)
        "#@namespace.angus-authentication-client.#{key}"
      end

    end

  end
end