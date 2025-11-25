# frozen_string_literal: true

require 'json'
require 'net/http/persistent'
require 'uri'
require 'openssl'

require_relative 'exceptions'
require_relative 'proxy_client_utils'

module Angus
  module Remote
    # A client for service invocation when proxing requests.
    class ProxyClient
      def initialize(url, timeout = 60)
        url = url[0..-2] if url[-1] == '/'

        @uri = URI.parse(url)

        @connection = Net::HTTP::Persistent.new(
          name: 'angus_proxy_client',
          pool_size: 4
        )

        @connection.verify_mode = OpenSSL::SSL::VERIFY_NONE if @uri.scheme == 'https'
        @connection.read_timeout = timeout if timeout
        @connection.open_timeout = timeout if timeout

        @api_base_path = @uri.path.empty? ? '' : @uri.path
      end

      # Makes a request to the service
      #
      def make_request(method, path, query, headers = {}, body = nil)
        request_path = @api_base_path + path

        request_uri = @uri.dup
        request_uri.path = request_path

        request = ProxyClientUtils.build_request(method, request_path, query, headers, body)

        begin
          response = @connection.request(request_uri, request)

          from_headers = ProxyClientUtils.normalize_headers(
            ProxyClientUtils.filter_response_headers(response.to_hash)
          )

          [response.code.to_i, from_headers, [response.body]]
        rescue Errno::ECONNREFUSED, Net::HTTP::Persistent::Error => e
          raise RemoteConnectionError, "#{request_uri.host} - #{e.class}: #{e.message}"
        end
      end

      def to_s
        "#<#{self.class}:#{object_id}>"
      end
    end
  end
end
