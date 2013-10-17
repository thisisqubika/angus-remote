require_relative 'response/hash'

module Angus
  module Remote

    class Representation
      include Angus::Remote::Response::Hash

      attr_accessor :elements

      def initialize
        @http_response_info = {}
        @elements = {}
      end
    end

  end
end