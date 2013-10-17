require_relative 'multipart_base'

module Http
  module MultipartMethods

    class Post < Net::HTTP::Post
      include MultipartBase
    end

  end
end