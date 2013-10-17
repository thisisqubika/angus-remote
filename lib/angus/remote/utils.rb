require 'json'
require 'uri'

require_relative 'exceptions'
require_relative 'http/query_params'
require_relative 'http/multipart'
require_relative 'http/multipart_methods/multipart_put'
require_relative 'http/multipart_methods/multipart_post'

module Angus
  module Remote

    module Utils

      HTTP_METHODS_WITH_BODY  = %w(post put)

      RE_PATH_PARAM = /:\w+/

      SEVERE_STATUS_CODES     = %w(500 501 503)

      # Builds a request for the given method, path and params.
      #
      # @param [String] method
      # @param [String] path
      # @param [String] request_params
      # @param [String] encode_as_json
      #
      # @return (see .build_base_request)
      def self.build_request(method, path, request_params = {}, encode_as_json = false)
        if encode_as_json
          build_json_request(method, path, request_params)
        else
          build_normal_request(method, path, request_params)
        end
      end

      def self.build_normal_request(method, path, params)
        multipart_request = Http::Multipart.hash_contains_files?(params)

        params = if multipart_request
                   Http::Multipart::QUERY_STRING_NORMALIZER.call(params)
                 else
                   Http::QueryParams.to_params(params)
                 end

        if HTTP_METHODS_WITH_BODY.include?(method)
          request = build_base_request(method, path, multipart_request)
          request.body = params
        else
          uri = URI(path)
          uri.query = params

          request = build_base_request(method, uri.to_s)
        end

        request
      end


      def self.build_base_request(method, path, multipart_request = false)
        case method.to_s.downcase
        when 'get'
          Net::HTTP::Get.new(path)
        when 'post'
          multipart_request ? Http::MultipartMethods::Post.new(path) : Net::HTTP::Post.new(path)
        when 'put'
          multipart_request ? Http::MultipartMethods::Put.new(path) : Net::HTTP::Put.new(path)
        when 'delete'
          Net::HTTP::Delete.new(path)
        else
          raise MethodArgumentError.new(method)
        end
      end

      def self.build_json_request(method, path, params)
        request = build_base_request(method, path)
        request.body = JSON(params)
        request['Content-Type'] = 'application/json'

        request
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
        if matches.length != path_params.length
          raise PathArgumentError.new(path_params.length, matches.length)
        end

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