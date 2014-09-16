module Angus
  module Remote
    module Response

      module Hash

        def elements
          @elements ||= {}
        end

        # Creates a hash base on the object
        #
        # The object must have an instance variable @elements that is a hash
        #   that keys => element name, value => element value
        def to_hash
          hash = {}

          elements.each do |name, value|
            if value.is_a?(Angus::Remote::Response::Hash)
              hash[name] = value.to_hash
            elsif value.is_a?(Array)
              hash[name] = build_hash_from_array(value)
            else
              hash[name] = value
            end
          end

          hash
        end

        private

        def build_hash_from_array(elements)
          elements.map do |element|
            if element.is_a?(Angus::Remote::Response::Hash)
              element.to_hash
            elsif element.is_a?(Array)
              build_hash_from_array(element)
            else
              element
            end
          end
        end

      end

    end
  end
end