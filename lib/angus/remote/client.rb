require 'json'
require 'persistent_http'

require_relative 'exceptions'
require_relative 'utils'

require_relative 'response/builder'
require_relative 'settings'

module Angus
  module Remote

    # A client for service invocation
    class Client
      def initialize(api_url, timeout = nil, options = {})
        api_url = api_url[0..-2] if api_url[-1] == '/'

        @connection = PersistentHTTP.new(
          :pool_size    => options['pool_size'] || 10,
          :pool_timeout => 10,
          :warn_timeout => 0.25,
          :force_retry  => false,
          :url          => api_url,

          :read_timeout => timeout,
          :open_timeout => timeout
        )

        @api_base_path = @connection.default_path

        store_namespace = "#{options['code_name']}.#{options['version']}"
        client_settings = { :public_key => options['public_key'],
                            :private_key => options['private_key'],
                            :service_id => store_namespace }

        @authentication_client = Authentication::Client.new(client_settings)
      end

      # Makes a request to the service
      #
      # @param [String] path The operation URL path. It can have place holders,
      #   ex: /user/:user_id/profile
      # @param [String] method The http method for the request: get, post, put, delete
      # @param [String] encode_as_json If true, the request params are encoded as json in the
      #   request body
      # @param [String] path_params Params that go into the path. This is an array, the first
      #   element in the array goes in the first path placeholder.
      # @param [String] request_params Params that go as url params or as data encoded in the body.
      #
      # @return [Net::HTTPResponse] The remote service response.
      #
      # @raise (see Utils.build_request)
      # @raise [RemoteSevereError] When the remote response status code is of severe error.
      #   see Utils.severe_error_response?
      # @raise [RemoteConnectionError] When the remote service refuses the connection.
      def make_request(path, method, encode_as_json, path_params, request_params)
        path = @api_base_path + Utils.build_path(path, path_params)

        request = Utils.build_request(method, path, request_params, encode_as_json)

        begin
          @authentication_client.prepare_request(request, method.upcase, path)

          response = @connection.request(request)

          if Utils.severe_error_response?(response)
            raise RemoteSevereError.new(get_error_messages(response.body))
          end

          response
        rescue Errno::ECONNREFUSED, PersistentHTTP::Error => e
          raise RemoteConnectionError.new("#@api_base_path - #{e.class}: #{e.message}")
        end
      end

      def to_s
        "#<#{self.class}:#{object_id}>"
      end

      private

      def get_error_messages(response_body)
        json_response = JSON(response_body) rescue { 'messages' => [] }
        Response::Builder::build_messages(json_response['messages'])
      end

    end

  end
end
