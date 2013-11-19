require 'digest'

require 'angus/authentication/redis_store'

module Angus
  module Authentication
    class Provider

      DEFAULT_PUBLIC_KEY = '1234567'
      DEFAULT_PRIVATE_KEY = 'CHANGE ME!!'

      AUTHENTICATION_HEADER = 'AUTHORIZATION'
      BAAS_AUTHENTICATION_HEADER = 'X-BAAS-AUTH'
      BAAS_SESSION_HEADER = 'X-Baas-Session-Seed'
      DATE_HEADER = 'DATE'

      def initialize(settings)
        @public_key = settings[:public_key] || DEFAULT_PUBLIC_KEY
        @private_key = settings[:private_key] || DEFAULT_PRIVATE_KEY
        @store = RedisStore.new(settings[:store] || {})
      end

      def prepare_request(request, http_method, script_name)
        date = Date.today

        auth_token = generate_auth_token(date, http_method, script_name)
        request[DATE_HEADER] = date.httpdate
        request[AUTHENTICATION_HEADER] = generate_auth_header(auth_token)

        session_auth_token = generate_session_auth_token(date, http_method, script_name)
        request[BAAS_AUTHENTICATION_HEADER] = generate_auth_header(session_auth_token)
      end

      def store_session_private_key(response)
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