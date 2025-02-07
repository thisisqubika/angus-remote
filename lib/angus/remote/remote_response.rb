# frozen_string_literal: true

require_relative 'response/hash'

module Angus
  module Remote
    # A service's response
    #
    # Acts as an array to store information at HTTP level, like the status_code
    class RemoteResponse < Struct
      include Angus::Remote::Response::Hash

      attr_accessor :status, :status_code, :messages, :http_response_info

      def initialize(*args)
        @http_response_info = {}

        super(*args)
      end

      def to_hash
        {
          http_status_code: @http_response_info[:status_code],
          body: @http_response_info[:body],
          service_name: @http_response_info[:service_name],
          operation_name: @http_response_info[:operation_name]
        }
      end
    end
  end
end
