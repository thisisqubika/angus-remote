# frozen_string_literal: true

require 'net/http/persistent'

module Net
  class HTTP
    class Persistent
      class Pool < ConnectionPool
        def checkout(net_http_args)
          stacks = Thread.current[@key] ||= {}
          stack  = stacks[net_http_args] ||= []

          conn = if stack.empty?
                   @available.pop connection_args: net_http_args, timeout: 10
                 else
                   stack.last
                 end

          stack.push conn

          conn
        end
      end
    end
  end
end
