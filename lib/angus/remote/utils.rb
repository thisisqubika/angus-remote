# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'
require 'securerandom'

require_relative 'exceptions'
require_relative 'http/query_params'

module Angus
  module Remote
    module Utils
      HTTP_METHODS_WITH_BODY = %w[post put].freeze
      RE_PATH_PARAM = /:\w+/.freeze
      SEVERE_STATUS_CODES = %w[500 501 503].freeze

      # Builds a request for the given method, path and params.
      #
      # @param [String] method
      # @param [String] path
      # @param [String] request_params
      # @param [String] encode_as_json
      #
      # @return (see .build_base_request)
      # rubocop:disable Style/OptionalBooleanParameter
      def self.build_request(method, path, request_params = {}, encode_as_json = false)
        if encode_as_json
          build_json_request(method, path, request_params)
        else
          build_normal_request(method, path, request_params)
        end
      end
      # rubocop:enable Style/OptionalBooleanParameter

      def self.build_normal_request(method, path, params)
        uri = URI(path)
        multipart_request = params.values.any? { |v| v.respond_to?(:read) }

        if multipart_request
          request = build_base_request(method, uri.to_s)
          request.body, boundary = build_multipart_body(params)
          request['Content-Type'] = "multipart/form-data; boundary=#{boundary}"
        elsif HTTP_METHODS_WITH_BODY.include?(method)
          request = build_base_request(method, uri.to_s)
          request.body = Http::QueryParams.to_params(params)
          request['Content-Type'] = 'application/x-www-form-urlencoded'
        else
          uri.query = Http::QueryParams.to_params(params)
          request = build_base_request(method, uri.to_s)
        end

        request
      end

      def self.build_base_request(method, uri)
        case method.to_s.downcase
        when 'get'
          Net::HTTP::Get.new(uri)
        when 'post'
          Net::HTTP::Post.new(uri)
        when 'put'
          Net::HTTP::Put.new(uri)
        when 'delete'
          Net::HTTP::Delete.new(uri)
        else
          raise MethodArgumentError, method
        end
      end

      def self.build_json_request(method, path, params)
        uri = URI(path)
        request = build_base_request(method, uri.to_s)
        request['Content-Type'] = 'application/json'
        request.body = params.to_json
        request
      end

      def self.build_multipart_body(params)
        boundary = "----RubyMultipartPost#{SecureRandom.hex}"
        body = +''

        params.each do |key, value|
          body << "--#{boundary}\r\n"
          if value.respond_to?(:read)
            body << "Content-Disposition: form-data; name=\"#{key}\"; filename=\"#{File.basename(value.path)}\"\r\n"
            body << "Content-Type: #{mime_type(value.path)}\r\n\r\n"
            body << value.read
          else
            body << "Content-Disposition: form-data; name=\"#{key}\"\r\n\r\n"
            body << value.to_s
          end
          body << "\r\n"
        end

        body << "--#{boundary}--\r\n"
        [body, boundary]
      end

      def self.mime_type(path)
        case File.extname(path)
        when '.jpg' then 'image/jpeg'
        when '.png' then 'image/png'
        when '.gif' then 'image/gif'
        else 'application/octet-stream'
        end
      end

      # Builds the URI path. It applies the params to the path
      #
      # @param [String] path the path with place holders
      # @param [Array<String>] path_params Array of params to be used as values in the path
      #
      # @return [String] the URI path
      #
      # @raise ArgumentError when the length of path_params doesn't match the count of placeholders
      #
      # @example
      #   path = "/users/:user_id/profile/:profile_id"
      #   path_params = [4201, 2]
      #
      #   build_path(path, path_params) #=> "/users/4201/profile/2"
      def self.build_path(path, path_params)
        matches = path.scan(RE_PATH_PARAM)
        raise PathArgumentError.new(path_params.length, matches.length) if matches.length != path_params.length

        matches.each_with_index do |match, index|
          path = path.sub(match, path_params[index].to_s)
        end

        path
      end

      # @param [#code] response
      def self.severe_error_response?(response)
        status_code = response.code.to_s
        SEVERE_STATUS_CODES.include?(status_code)
      end
    end
  end
end
