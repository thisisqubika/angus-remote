require 'spec_helper'

require 'picasso/remote/http/multipart_methods/multipart_base'

describe Http::MultipartMethods::MultipartBase do

  let :request_class do
    Class.new(Net::HTTP::Post) do
      include Http::MultipartMethods::MultipartBase
    end
  end

  context 'headers set by .body= are retained if .initialize_http_header is called afterwards' do
    def request_with_headers(headers)
      request_class.new('/path').tap do |request|
        request.body = { :some => :var }
        request.initialize_http_header(headers)
      end
    end

    context 'with a header' do
      subject { request_with_headers({'a' => 'header'}).to_hash }

      it { should include('content-length') }
      it { should include('a') }
    end

    context 'without a header' do
      subject { request_with_headers(nil).to_hash }

      it { should include('content-length') }
      it { should_not include('a') }
    end
  end

end