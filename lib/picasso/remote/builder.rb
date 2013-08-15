require 'uri'

require_relative 'client'
require_relative 'response/builder'

module Picasso
  module Remote

    module Builder

      DEFAULT_TIMEOUT = 60

      # Builds a client for a specific service.
      #
      # @param [String] code_name The service's name known to the service directory
      # @param [Picasso::SDoc::Definitions::Service] service_definition
      # @param api_url Base service api url
      #
      # @return [Remote::Client] object that implements each method specified as operation
      #   in the service metadata
      def self.build(code_name, service_definition, api_url)
        remote_service_class = build_client_class(service_definition.name)

        service_definition.operations.each do |operation|
          self.define_operation(remote_service_class, operation, code_name, service_definition)
        end

        service_definition.proxy_operations.each do |operation|
          self.define_proxy_operation(remote_service_class, operation, code_name,
                                      service_definition)
        end

        remote_service_class.new(api_url, self.default_timeout)
      end

      def self.define_operation(client_class, operation, service_code_name, service_definition)
        client_class.send :define_method, operation.code_name do |encode_as_json = false,
                                                                  path_params = nil,
                                                                  request_params = nil|

          args = [encode_as_json, path_params, request_params]

          request_params = Picasso::Remote::Builder.extract_var_arg!(args, Hash) || {}
          path_params = Picasso::Remote::Builder.extract_var_arg!(args, Array) || []
          encode_as_json = Picasso::Remote::Builder.extract_var_arg!(args, TrueClass) || false

          request_params = Picasso::Remote::Builder.apply_glossary(service_definition.glossary, request_params)
          request_params = Picasso::Remote::Builder.escape_request_params(request_params)

          response = make_request(operation.path, operation.method, encode_as_json, path_params,
                                  request_params)

          Picasso::Remote::Response::Builder.build_from_remote_response(response,
                                                                        service_code_name,
                                                                        service_definition.version,
                                                                        operation.code_name)
        end
      end

      def self.define_proxy_operation(client_class, operation, service_code_name, service_definition)
        client_class.send :define_method, operation.code_name do |encode_as_json = false,
                                                                  path_params = nil,
                                                                  request_params = nil|

          service_definition = Picasso::Remote::ServiceDirectory.join_proxy(
            service_code_name,
            service_definition.version,
            operation.service_name
          )

          args = [encode_as_json, path_params, request_params]

          request_params = Picasso::Remote::Builder.extract_var_arg!(args, Hash) || {}
          path_params = Picasso::Remote::Builder.extract_var_arg!(args, Array) || []
          encode_as_json = Picasso::Remote::Builder.extract_var_arg!(args, TrueClass) || false

          request_params = Picasso::Remote::Builder.apply_glossary(service_definition.glossary,
                                                                   request_params)

          request_params = Picasso::Remote::Builder.escape_request_params(request_params)

          response = make_request(operation.path, operation.method, encode_as_json, path_params,
                                  request_params)

          Picasso::Remote::Response::Builder.build_from_remote_response(response,
                                                                        service_code_name,
                                                                        service_definition.version,
                                                                        operation.code_name)
        end
      end

      # Build a client class for the service
      #
      # @param [String] service_name the name of the service
      # @param [String] api_url the url for consuming the service's api
      #
      # @return [Class] A class client, that inherits from {Picasso::Remote::Client}
      def self.build_client_class(service_name)
        remote_service_class = Class.new(Picasso::Remote::Client)

        remote_service_class.class_eval <<-END
          def self.name
            "#<Client_#{service_name}>"
          end

          def self.to_s
            name
          end
        END

        remote_service_class
      end


      # Applies glossary to params.
      #
      # Converts the params that are long names to short names
      #
      # @param [Glossary] glossary of terms
      # @param [Hash] params
      #
      # @return [Hash] params with long names
      def self.apply_glossary(glossary, params)
        terms_hash = glossary.terms_hash_with_long_names

        applied_params = {}

        params.each do |name, value|
          if terms_hash.include?(name.to_s)
            term = terms_hash[name.to_s]
            applied_params[term.short_name.to_sym] = value
          else
            applied_params[name] = value
          end
        end

        applied_params
      end

      # Extract an argument of class +klass+ from an array of +args+
      #
      # Returns the first value from +args+ (starting from the end of args) whose class matches +klass+
      # @param args Array of arguments
      # @param klass Class that should match the returned value
      #
      def self.extract_var_arg!(args, klass)
        arg = nil
        arg_found = false

        i = args.length
        while !arg_found && i > 0
          i -= 1
          arg = args[i]
          arg_found = true if arg.is_a?(klass)
        end

        if arg_found
          args.delete_at(i)
          arg
        end
      end

      def self.escape_request_params(request_params)
        encoded = {}
        request_params.each do |name, value|
          encoded_name = URI.escape(name.to_s)
          if value.is_a? Hash
            value = self.escape_request_params(value)
          end
          encoded[encoded_name] = value
        end
        encoded
      end


      def self.default_timeout
        @default_timeout || DEFAULT_TIMEOUT
      end

      def self.default_timeout=(default_timeout)
        @default_timeout = default_timeout
      end

    end

  end
end
