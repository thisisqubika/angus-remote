require_relative 'multipart_base'

module Http
  module MultipartMethods

    class Put < Net::HTTP::Put
      include MultipartBase
    end

  end
end