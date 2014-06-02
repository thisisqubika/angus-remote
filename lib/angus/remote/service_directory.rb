require 'digest'
require 'json'
require 'yaml'

require 'angus/sdoc'
require 'angus/authentication/client'

require_relative 'builder'
require_relative 'exceptions'

module Angus
  module Remote

    module ServiceDirectory

      # Builds and returns a Client object for the service and version received
      def self.lookup(*args)
        if args.length == 1
          definition = args.first
          code_name = definition.delete(:code_name)
          version = definition.delete(:version)
          set_service_configuration(code_name, version, definition)
        else
          code_name, version = args
        end

        version ||= service_version(code_name)

        @clients_cache ||= {}
        if @clients_cache.include?([code_name, version])
          return @clients_cache[[code_name, version]]
        end

        begin
          service_definition = self.service_definition(code_name, version)
          client = Angus::Remote::Builder.build(code_name, service_definition,
                                                self.api_url(code_name, version),
                                                service_settings(code_name, version))
          @clients_cache[[code_name, version]] = client

        rescue Errno::ECONNREFUSED
          raise RemoteConnectionError.new(self.api_url(code_name, version))
        end
      end

      # Returns the documentation url from the configuration file
      #
      # @param [String] code_name Name of the service.
      # @param [String] version Version of the service.
      #
      # If no version given, it reads the version from the configuration file.
      #
      # @raise (see .service_version)
      def self.doc_url(code_name, version = nil)
        version ||= service_version(code_name)

        config = service_configuration(code_name)

        config["v#{version}"]['doc_url']
      end

      # Returns the documentation url for proxy operations hosted by the service.
      #
      # @param [String] code_name Service code name.
      # @param [String] version Service version.
      # @param [String] remote_code_name Service which implements proxy operations.
      #
      # @return [String]
      def self.proxy_doc_url(code_name, version, remote_code_name)
        doc_url = self.doc_url(code_name, version)

        "#{doc_url}/proxy/#{remote_code_name}"
      end

      # Returns the api url from the configuration file
      #
      # @param [String] code_name Name of the service.
      # @param [String] version Version of the service.
      #
      # If no version given, it reads the version from the configuration file.
      #
      # @raise (see .service_version)
      def self.api_url(code_name, version = nil)
        version ||= service_version(code_name)

        config = service_configuration(code_name)

        config["v#{version}"]['api_url']
      end

      # Returns the configured version.
      #
      # @param [String] code_name Service name
      #
      # @return [String] Version. Ex: 0.1
      #
      # @raise [TooManyServiceVersions] When there are more than one configured version.
      def self.service_version(code_name)
        versions = service_configuration(code_name).keys

        if versions.length == 1
          versions.first.gsub(/^v/, '')
        else
          raise TooManyServiceVersions.new(code_name)
        end
      end

      # Returns the service's definition for the given service name and version
      #
      # @param [String] code_name Service that acts as a proxy.
      # @param [String] version Service version.
      #
      # @raise (see .service_version)
      #
      # @return [Angus::SDoc::Definitions::Service]
      def self.service_definition(code_name, version = nil)
        version ||= service_version(code_name)

        @service_definitions_cache ||= {}
        if @service_definitions_cache.include?([code_name, version])
          return @service_definitions_cache[[code_name, version]]
        end

        service_definition = self.get_service_definition(code_name, version)
        @service_definitions_cache[[code_name, version]] = service_definition
      end

      # Queries a service for definitions of proxy operations for the given remote service.
      #
      # Merges those definitions and returns the result.
      #
      # @param [String] code_name Service that acts as a proxy.
      # @param [String] version Service version.
      # @param [String] remote_code_name Remote service that implements operations for
      #   the proxy service
      #
      # @return [Angus::SDoc::Definitions::Service]
      def self.join_proxy(code_name, version, remote_code_name)

        service_definition = self.service_definition(code_name, version)

        @service_definitions_proxies ||= []
        if @service_definitions_proxies.include?([code_name, version, remote_code_name])
          return service_definition
        end

        proxy_doc_url = self.proxy_doc_url(code_name, version, remote_code_name)

        definition_hash = fetch_remote_service_definition(proxy_doc_url, code_name, version)

        proxy_service_definition = Angus::SDoc::DefinitionsReader.build_service_definition(definition_hash)

        service_definition.merge(proxy_service_definition)

        service_definition
      end

      # Requests a service definition.
      #
      # @param [String] code_name Service code name
      # @param [String] version Service version
      #
      # @raise (see .service_version)
      #
      # @return [Angus::SDoc::Definitions::Service]
      def self.get_service_definition(code_name, version = nil)
        version ||= service_version(code_name)
        doc_url = self.doc_url(code_name, version)

        if doc_url.match('file://(.*)') || doc_url.match('file:///(.*)')
          Angus::SDoc::DefinitionsReader.service_definition($1)
        else
          definition_hash = fetch_remote_service_definition(doc_url, code_name, version)
          Angus::SDoc::DefinitionsReader.build_service_definition(definition_hash)
        end
      end

      # Fetches a service definition from a remote http uri.
      #
      # @param [String] uri URI that publishes a service definition.
      # @param [String] code_name Name of the service.
      # @param [String] version Version of the service.
      #
      # @return [Hash] Service definition hash
      def self.fetch_remote_service_definition(uri, code_name, version)
        uri = URI(uri)
        uri.query = URI.encode_www_form({:format => :json})

        connection = Net::HTTP.new(uri.host, uri.port)

        if uri.scheme == 'https'
          connection.use_ssl = true
          connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end

        response = connection.start do |http|
          request = Net::HTTP::Get.new(uri.request_uri)

          authentication_client(code_name, version).prepare_request(request, 'GET', uri.path)

          http.request(request)
        end

        authentication_client(code_name, version).store_session_private_key(response)

        JSON(response.body)
      rescue Exception
        raise RemoteConnectionError.new(uri)
      end
      private_class_method :fetch_remote_service_definition

      def self.authentication_client(code_name, version)
        @authentication_clients ||= {}

        unless @authentication_clients.include?([code_name, version])
          service_settings = service_settings(code_name, version)

          settings = { :public_key => service_settings['public_key'],
                       :private_key => service_settings['private_key'],
                       :store => Settings.redis.merge({ :namespace => "#{code_name}.#{version}" }) }

          @authentication_clients[[code_name, version]] = Angus::Authentication::Client.new(settings)
        end

        @authentication_clients[[code_name, version]]
      end
      private_class_method :authentication_client

      # Returns the documentation url from the configuration file
      #
      # @param [String] code_name Name of the service.
      # @param [String] version Version of the service.
      #
      # If no version given, it reads the version from the configuration file.
      #
      # @raise (see .service_version)
      def self.service_settings(code_name, version = nil)
        version ||= service_version(code_name)

        config = service_configuration(code_name)

        service_settings = config["v#{version}"] or
          raise ServiceConfigurationNotFound.new(code_name, version)

        service_settings['code_name'] = code_name
        service_settings['version'] = version

        service_settings
      end
      private_class_method :service_settings

      # Returns the connection configuration for a given service.
      #
      # @param [String] code_name Service name
      #
      # @return [Hash]
      #
      # @raise [ServiceConfigurationNotFound] When no configuration for the given service
      def self.service_configuration(code_name)
        @services_configuration ||= load_services_configuration_file

        @services_configuration[code_name] or
          raise ServiceConfigurationNotFound.new(code_name)
      end
      private_class_method :service_configuration

      def self.set_service_configuration(code_name, version, configuration)
        @services_configuration ||= load_services_configuration_file
        @services_configuration[code_name] ||= {}

        @services_configuration[code_name]["v#{version}"] = configuration.inject({}) do |config, entry|
          k, v = entry
          config.merge!({ k.to_s => v })
        end
      end
      private_class_method :set_service_configuration

      def self.load_services_configuration_file
        return {} unless File.exists?(Settings.configuration_file)
        configuration = YAML.load_file(Settings.configuration_file)

        configuration = {} unless configuration.is_a?(Hash)

        configuration
      end
      private_class_method :load_services_configuration_file

    end
  end
end