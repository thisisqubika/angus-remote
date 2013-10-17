require_relative 'response/hash'

module Angus
  module Remote

    # A service's response
    #
    # Acts as an array to store information at HTTP level, like the status_code
    class RemoteResponse
      include Angus::Remote::Response::Hash

      attr_accessor :status
      attr_accessor :status_code
      attr_accessor :messages

      def initialize
        @http_response_info = {}
      end

      def []=(key, value)
        @http_response_info[key] = value
      end

      def [](key)
        @http_response_info[key]
      end

      def to_s
        "#<#{self.class}:#{object_id}>"
      end

      def to_hash
        {
          :http_status_code => @http_response_info[:status_code],
          :body => @http_response_info[:body],
          :service_name => @http_response_info[:service_name],
          :operation_name => @http_response_info[:operation_name],
        }
      end

    end

  end
end