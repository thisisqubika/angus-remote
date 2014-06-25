require 'digest'

require_relative 'redis_client'

module Angus
  module Authentication
    class Client

      AUTHENTICATION_HEADER = 'AUTHORIZATION'
      BAAS_AUTHENTICATION_HEADER = 'X-BAAS-AUTH'
      BAAS_SESSION_HEADER = 'X-Baas-Session-Seed'
      DATE_HEADER = 'DATE'

      def initialize(settings)
        unless settings[:public_key] && settings[:private_key]
          warn "No authentication info provided, angus-authentication has been disabled for: #{settings[:service_id]}"
          @enabled = false
          return
        end

        @enabled = true
        @public_key = settings[:public_key]
        @private_key = settings[:private_key]

        @store = RedisClient.new(settings[:store] || {})
      end

      def prepare_request(request, http_method, script_name)
        return unless @enabled

        date = Date.today

        auth_token = generate_auth_token(date, http_method, script_name)
        request[DATE_HEADER] = date.httpdate
        request[AUTHENTICATION_HEADER] = generate_auth_header(auth_token)

        session_auth_token = generate_session_auth_token(date, http_method, script_name)
        request[BAAS_AUTHENTICATION_HEADER] = generate_auth_header(session_auth_token)
      end

      def store_session_private_key(response)
        return unless @enabled

        session_key_seed = extract_session_key_seed(response)
        return unless session_key_seed

        session_key = generate_session_private(session_key_seed)

        @store.store_session_key(@public_key, session_key)
      end

      private

      def generate_session_auth_token(date, http_method, script_name)
        session_private_key = @store.get_session_key(@public_key)
        Digest::SHA1.hexdigest("#{session_private_key}\n#{auth_data(date, http_method, script_name)}")
      end

      def generate_auth_token(date, http_method, script_name)
        Digest::SHA1.hexdigest("#@private_key\n#{auth_data(date, http_method, script_name)}")
      end

      def extract_session_key_seed(response)
        response[BAAS_SESSION_HEADER]
      end

      def auth_data(date, http_method, script_name)
        "#{date.httpdate}\n#{http_method}\n#{script_name}"
      end

      def generate_session_private(key_seed)
        Digest::SHA1.hexdigest("#@private_key\n#{key_seed}")
      end

      def generate_auth_header(auth_token)
        "#@public_key:#{auth_token}"
      end

    end
  end
end