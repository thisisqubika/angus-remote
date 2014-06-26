require 'bigdecimal'
require 'date'
require 'json'

require_relative '../message'
require_relative '../remote_response'

require_relative 'hash'

require_relative '../service_directory'


# TODO: move to another gem and possibly change its name
require_relative '../../unmarshalling'

module Angus
  module Remote
    module Response

      module Builder

        # Builds a Response
        #
        # The r parameter should contain in the body, encoded as json, the values / objects
        # specified in the operation response metadata
        #
        # @param [Integer] status_code HTTP status_code
        # @param [String] body HTTP body
        # @param [String] service_code_name Name of the service that the response belongs to
        # @param [String] service_version Version of the service that the response belongs to
        # @param [String] operation_namespace Namespace of the operation that the response belongs to
        # @param [String] operation_name Name of the operation that the response belongs to
        #
        # @return A Response object that responds to the methods:
        #   - status
        #   - messages
        #
        #   Also, provides one method for each value / object / array returned
        def self.build(status_code, body, service_code_name, service_version, operation_namespace,
                       operation_code_name)
          service_definition = Angus::Remote::ServiceDirectory.service_definition(
            service_code_name, service_version
          )

          self.build_from_definition(status_code, body, service_code_name, service_version,
                                     service_definition, operation_namespace, operation_code_name)
        end

        def self.build_from_definition(status_code, body, service_code_name, service_version,
                                       service_definition, operation_namespace, operation_code_name)
          representations = service_definition.representations
          glossary = service_definition.glossary

          operation_definition = service_definition.operation_definition(operation_namespace,
                                                                         operation_code_name)

          json_response = JSON(body)

          response_class = build_response_class(operation_definition.name)

          response = response_class.new

          # TODO use constants
          response[:status_code] = status_code
          response[:body] = body
          response[:service_code_name] = service_code_name
          response[:service_version] = service_version
          response[:operation_namespace] = operation_namespace
          response[:operation_code_name] = operation_code_name

          response.status = json_response['status']
          response.messages = self.build_messages(json_response['messages'])

          representations_hash = self.representations_hash(representations)
          glossary_terms_hash = glossary.terms_hash

          operation_definition.response_elements.each do |element|
            self.build_response_method(json_response, response_class, response,
                                       representations_hash, glossary_terms_hash, element)
          end

          response
        end

        # Builds the methods for each value / object / array
        #
        # The r parameter should contain in the body, encoded as json, the values / objects
        # specified in the operation response metadata
        def self.build_response_method(json_response, response_class, response,
                                       representations_hash, glossary_terms_hash, element)
          if (json_response.has_key?(element.name))
            hash_value = json_response[element.name]
          elsif (element.required == false)
            hash_value = element.default
          else
            return
          end

          object_value = nil

          if element.type && representations_hash.include?(element.type)
            object_value = self.build_from_representation(hash_value, element.type,
                                                          representations_hash, glossary_terms_hash)
          elsif element.elements_type
            object_value = self.build_collection_from_representation(hash_value,
                                                                     element.elements_type,
                                                                     representations_hash,
                                                                     glossary_terms_hash)
          elsif element.type && element.type.to_sym == :variable
            object_value = self.build_from_variable_fields(hash_value)
          elsif element.type
            begin
              object_value = Angus::Unmarshalling.unmarshal_scalar(hash_value,
                                                                     element.type.to_sym)
            rescue ArgumentError
              object_value = nil
            end
          end

          # Don't apply the glossary to response elements
          response.elements[element.name] = object_value

          # Instead, apply the glossary to method names
          getter_method_name = self.apply_glossary(element.name, glossary_terms_hash)

          response_class.send :define_method, getter_method_name do
            object_value
          end
        end

        # Builds a Response based on a service's response
        #
        # The remote_response parameter should contain in the body,
        # encoded as json, the values / objects
        # specified in the operation response metadata.
        #
        # @param [Http] remote_response HTTP response object, must respond to methods :body and :code
        # @param [String] service_name  Name of the invoked service
        # @param version [String] Version of the invoked service
        # @param operation_namespace [String] Namespace of the invoked operation
        # @param operation_name [String] Name of the invoked operation
        #
        # @return (see #build)
        def self.build_from_remote_response(remote_response, service_code_name, version,
                                            operation_namespace, operation_code_name)

          status_code = remote_response.code
          body = remote_response.body

          self.build(status_code, body, service_code_name, version, operation_namespace,
                     operation_code_name)
        end

        # Searches for a short name in the glossary and returns the corresponding long name
        #
        # If name is not a short name, returns the name
        #
        # @param [String] name
        # @param [Hash<String, GlossaryTerm>] glossary_terms_hash, where keys are short names
        #
        # @return long name
        def self.apply_glossary(name, glossary_terms_hash)
          if glossary_terms_hash.include?(name)
            name = glossary_terms_hash[name].long_name
          end

          return name
        end

        # Build a response class for the operation
        #
        # @param [String] operation_name the name of the operation
        #
        # @return [Class] A class client, that inherits from {Angus::Remote::Response}
        def self.build_response_class(operation_name)
          response_class = Class.new(Angus::Remote::RemoteResponse)
          response_class.class_eval <<-END
            def self.name
              "#<Response_#{operation_name.gsub(' ', '_')}>"
            end

            def self.to_s
              name
            end
          END

          response_class
        end

        # Receives an array of messages and returns an array of Message objects
        def self.build_messages(messages)
          messages ||= []

          messages.map do |m|
            message = Angus::Remote::Message.new
            message.description = m['dsc']
            message.key = m['key']
            message.level = m['level']

            message
          end
        end

        # Receives a hash, a type and an array of representations and
        # build an object that has one method for each attribute of the type.
        def self.build_from_representation(hash_value, type, representations, glossary_terms_hash)
          return nil if hash_value.nil?

          representation_class = Class.new do
            include Angus::Remote::Response::Hash
          end

          representation_object = representation_class.new

          if representations.include?(type)
            representation = representations[type]
            return nil if representation.nil?
            representation.fields.each do |field|
              field_raw_value = hash_value[field.name]
              field_value = nil
              unless field_raw_value.nil? && field.required == false
                if field.type && representations.include?(field.type)
                  field_value = self.build_from_representation(field_raw_value, field.type,
                                                               representations,
                                                               glossary_terms_hash)
                elsif field.elements_type
                  field_value = self.build_collection_from_representation(field_raw_value,
                                                                          field.elements_type,
                                                                          representations,
                                                                          glossary_terms_hash)
                elsif field.type && field.type.to_sym == :variable
                  field_value = self.build_from_variable_fields(field_raw_value)
                elsif field.type
                  field_value = Angus::Unmarshalling.unmarshal_scalar(field_raw_value,
                                                                        field.type.to_sym)
                end
              end

              # Don't apply the glossary to response elements
              representation_object.elements[field.name] = field_value

              # Instead, apply the glossary to method names
              getter_method_name = self.apply_glossary(field.name, glossary_terms_hash)

              representation_class.send :define_method, field.name.to_sym do
                field_value
              end
            end
          else
            if type.to_sym == :variable
              representation_object = self.build_from_variable_fields(hash_value)
            else
              begin
                representation_object = Angus::Unmarshalling.unmarshal_scalar(hash_value,
                                                                                type.to_sym)
              rescue ArgumentError
                representation_object = nil
              end
            end
          end


          return representation_object
        end

        # Builds an array of objects that corresponds to the received type
        def self.build_collection_from_representation(value_array, type, representations,
                                                      glossary_terms_hash)
          collection = []

          value_array.each do |raw_value|
            collection << build_from_representation(raw_value, type, representations,
                                                    glossary_terms_hash)
          end

          collection
        end

        # Builds an object from variable fields
        def self.build_from_variable_fields(variable_fields_hash)

          return nil if variable_fields_hash.nil?

          representation_class = Class.new do
            include Angus::Remote::Response::Hash
          end

          representation_object = representation_class.new

          variable_fields_hash.each do |key_name, field_value|
            representation_object.elements[key_name] = field_value
            representation_class.send :define_method, key_name.to_sym do
              field_value
            end
          end

          representation_object

        end

        # Receives an array of representations and returns a hash of representations where
        # the keys are the representation's names and the values are the representations
        def self.representations_hash(representations)
          hash = {}
          representations.each do |representation|
            hash[representation.name] = representation
          end
          hash
        end
      end

    end
  end
end