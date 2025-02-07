# frozen_string_literal: true

module Angus
  module Remote
    class RemoteSevereError < Exception
      attr_reader :messages

      def initialize(messages)
        @messages = messages

        super(@messages)
      end
    end

    class RemoteConnectionError < Exception
      def initialize(url)
        @remote_url = url

        super(message)
      end

      def message
        "Remote Connection Error: #{@remote_url}"
      end
    end

    class MethodArgumentError < Exception
      def initialize(method)
        @method = method

        super(message)
      end

      def message
        "Invalid http method: #{@method}"
      end
    end

    class PathArgumentError < Exception
      def initialize(current, expected)
        @current = current
        @expected = expected

        super(message)
      end

      def message
        "Wrong number of arguments (#{@current} for #{@expected})"
      end
    end

    class ServiceConfigurationNotFound < Exception
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
