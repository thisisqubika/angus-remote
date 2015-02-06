require 'digest'
require 'time'

module Angus
  module Authentication
    class Client

      BAAS_VERSION = 1

      AUTHENTICATION_HEADER = 'AUTHORIZATION'
      DATE_HEADER = 'DATE'

      # @param [Hash] opts
      # @option opts [String] :public_key
      # @option opts [String] :private_key
      # @option opts [String] :service_id
      def initialize(opts)
        @public_key = opts[:public_key]
        @private_key = opts[:private_key]

        if disabled?
          warn(
            "No authentication info provided, angus-authentication has been disabled for: " \
            "#{opts[:service_id]}"
          )
        end
      end

      def prepare_request(request, http_method, operation_path)
        return if disabled?

        now = Time.now

        request_signature = request_signature(@private_key, now, http_method, operation_path)
        auth_header = auth_header(@public_key, request_signature)

        request[DATE_HEADER] = now.httpdate
        request[AUTHENTICATION_HEADER] = auth_header
      end

      private
      def disabled?
        !(@public_key || @private_key)
      end

      def auth_header(public_key, request_signature)
        "BAAS v#{BAAS_VERSION} apps/#{public_key}:#{request_signature}"
      end

      def request_signature(private_key, time, http_method, operation_path)
        plain_signature = "#{private_key}\n#{time.httpdate}\n#{http_method}\n#{operation_path}"

        Digest::SHA1.hexdigest(plain_signature)
      end

    end
  end
end
