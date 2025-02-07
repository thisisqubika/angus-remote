# frozen_string_literal: true

module Angus
  module Remote
    # A message returned by the service's response
    class Message
      attr_accessor :description, :key, :level
    end
  end
end
