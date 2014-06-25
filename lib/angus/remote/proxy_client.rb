require 'json'
require 'persistent_http'

require_relative 'exceptions'
require_relative 'proxy_client_utils'

module Angus
  module Remote

    # A client for service invocation when proxing requests.
    class ProxyClient

      def initialize(url, timeout)
        url = url[0..-2] if url[-1] == '/'

        @connection = PersistentHTTP.new(
          :pool_size    => 4,
          :pool_timeout => 10,
          :warn_timeout => 0.25,
          :force_retry  => false,
          :url          => url,

          :read_timeout => timeout,
          :open_timeout => timeout
        )

        @api_base_path = @connection.default_path
      end

      # Makes a request to the service
      #
      def make_request(method, path, query, headers = {}, body = nil)
        full_path = @api_base_path + path

        request = ProxyClientUtils.build_request(method, full_path, query, headers, body)

        begin
          response = @connection.request(request)

          from_headers = ProxyClientUtils.normalize_headers(
             ProxyClientUtils.filter_response_headers(response.to_hash)
          )

          [response.code.to_i, from_headers, [response.body]]
        rescue Errno::ECONNREFUSED => e
          raise RemoteConnectionError.new("#{self.class.base_uri} - #{e.class}: #{e.message}")
        end
      end

      def to_s
        "#<#{self.class}:#{object_id}>"
      end
    end

  end
end
