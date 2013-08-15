require_relative 'response/hash'

module Picasso
  module Remote

    class Representation
      include Picasso::Remote::Response::Hash

      attr_accessor :elements

      def initialize
        @http_response_info = {}
        @elements = {}
      end
    end

  end
end