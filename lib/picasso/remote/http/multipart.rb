require 'tempfile'
require 'net/http/post/multipart'

module Http
  module Multipart

    TRANSFORMABLE_TYPES = [File, Tempfile, StringIO]

    QUERY_STRING_NORMALIZER = Proc.new do |params|
      Multipart.flatten_params(params).map do |(k,v)|
        [k, Multipart.transformable_type?(v) ? Multipart.file_to_upload_io(v) : v]
      end
    end

    def self.file_to_upload_io(file)
      if file.respond_to? :original_filename
        filename = file.original_filename
      else
        filename =  File.split(file.path).last
      end
      content_type = 'application/octet-stream'
      UploadIO.new(file, content_type, filename)
    end

    def self.hash_contains_files?(hash)
      hash.is_a?(Hash) && self.flatten_params(hash).select do |(k,v)|
        self.transformable_type?(v) || v.is_a?(UploadIO)
      end.size > 0
    end

    def self.transformable_type?(object)
      TRANSFORMABLE_TYPES.any? { |klass| object.is_a?(klass) }
    end

    def self.flatten_params(params={}, prefix='')
      flattened = []
      params.each do |(k,v)|
        if params.is_a?(Array)
          v = k
          k = ''
        end

        flattened_key = prefix == '' ? "#{k}" : "#{prefix}[#{k}]"
        if v.is_a?(Hash) || v.is_a?(Array)
          flattened += flatten_params(v, flattened_key)
        else
          flattened << [flattened_key, v]
        end
      end
      flattened
    end

  end
end