require 'uri'
require 'json'

require_relative 'exceptions'
require_relative 'http/query_params'

module Angus
  module Remote

    module ProxyClientUtils

      ALLOWED_RESPONSE_HEADERS = ['content-type']

      def self.build_request(method, path, query, headers = {}, body = nil)
        uri = URI(path)
        uri.query = query

        full_uri = uri.to_s

        request = case method.to_s.downcase
        when 'get'
          Net::HTTP::Get.new(full_uri)
        when 'post'
          Net::HTTP::Post.new(full_uri)
        when 'put'
          Net::HTTP::Put.new(full_uri)
        when 'delete'
          Net::HTTP::Delete.new(full_uri)
        else
          raise MethodArgumentError.new(method)
        end

        headers.each do |k, v|
          request[k] = v
        end

        request.body = body

        request
      end

      def self.filter_response_headers(headers)
        headers.select { |h, v| ALLOWED_RESPONSE_HEADERS.include?(h) }
      end

      # Converts any header value that is an array to its first value.
      #
      # @param [Hash] header
      #
      # @return [Hash]
      #
      # @example
      #   normalize_headers({'content-type'=>['application/json;charset=utf-8']})
      #
      #   -> {'content-type'=>'application/json;charset=utf-8'}
      def self.normalize_headers(headers)
        normalized = headers.map do |h, v|
          if v.is_a?(Array)
           [h, v.first]
          else
           [h, v]
          end
        end

        Hash[normalized]
      end
    end

  end
end
