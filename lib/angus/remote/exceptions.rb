# frozen_string_literal: true

module Angus
  module Remote
    class RemoteSevereError < StandardError
      attr_reader :messages

      def initialize(messages)
        @messages = messages

        super(@messages)
      end
    end

    class RemoteConnectionError < StandardError
      def initialize(url)
        @remote_url = url

        super(message)
      end

      def message
        "Remote Connection Error: #{@remote_url}"
      end
    end

    class MethodArgumentError < StandardError
      def initialize(method)
        @method = method

        super(message)
      end

      def message
        "Invalid http method: #{@method}"
      end
    end

    class PathArgumentError < StandardError
      def initialize(current, expected)
        @current = current
        @expected = expected

        super(message)
      end

      def message
        "Wrong number of arguments (#{@current} for #{@expected})"
      end
    end

    class ServiceConfigurationNotFound < StandardError
      def initialize(code_name, version = nil)
        @code_name = code_name
        @version = version

        super(message)
      end

      def message
        if @version
          "Config for #{@code_name} v#{@version} not found."
        else
          "Config for #{@code_name} not found."
        end
      end
    end
  end
end
