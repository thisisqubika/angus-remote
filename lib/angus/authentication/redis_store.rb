require 'redis'

module Angus
  module Authentication

    class RedisStore

      def initialize(settings)
        @settings = settings
      end

      def store_session_key(key, data)
        redis.set(key, data)
      end

      def get_session_key(key)
        redis.get(key)
      end

      def redis
        @redis ||= Redis.new(@settings)
      end

    end

  end
end