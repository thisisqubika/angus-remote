require 'json'

require_relative 'builder'

module Angus
  module Remote
    module Response

      module Serializer

        def self.serialize(response)
          h = {}
          h['status_code'] = response[:status_code]
          h['body'] = response[:body]
          h['service_code_name'] = response[:service_code_name]
          h['service_version'] = response[:service_version]
          h['operation_namespace'] = response[:operation_namespace]
          h['operation_code_name'] = response[:operation_code_name]

          h['body'].force_encoding('UTF-8')

          JSON(h)
        end

        def self.unserialize(s)
          s = JSON(s)

          service_code_name = s['service_code_name']
          version = s['service_version']

          operation_code_name = s['operation_code_name']
          operation_namespace = s['operation_namespace']
          status_code = s['status_code']
          body = s['body']

          Response::Builder.build(status_code, body, service_code_name, version,
                                  operation_namespace, operation_code_name)
        end
      end

    end
  end
end