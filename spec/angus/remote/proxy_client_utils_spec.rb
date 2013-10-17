require 'net/http'

require 'json'

require 'angus/remote/proxy_client_utils'

describe Angus::Remote::ProxyClientUtils do

  subject(:utils) { Angus::Remote::ProxyClientUtils }

  describe '.build_request' do

    let(:path) { '/' }
    let(:query) { 'q=listing' }

    shared_examples 'a request builder' do |method, kind_of|
      context "when #{method}" do
        it "returns a kind_of #{kind_of}" do
          res = utils.build_request(method, path, query)

          res.should be_a(kind_of)
        end
      end
    end

    it_behaves_like 'a request builder', :get,     Net::HTTP::Get
    it_behaves_like 'a request builder', :post,    Net::HTTP::Post
    it_behaves_like 'a request builder', :put,     Net::HTTP::Put
    it_behaves_like 'a request builder', :delete,  Net::HTTP::Delete

    context 'with headers' do
      it 'sets the to the request' do
        headers = { 'a' => 'A', 'b' => 'B' }

        res = utils.build_request(:get, path, query, headers)

        res['a'].should eq('A')
        res['b'].should eq('B')
      end
    end

    context 'with body' do
      it 'sets the body to the request' do
        body = 'BODY'

        res = utils.build_request(:get, path, query, {}, body)

        res.body.should eq(body)
      end
    end

    context 'when invalid http method' do
      it 'raises MethodArgumentError' do
        expect {
          utils.build_request(:invalid, path, query)
        }.to raise_error(Angus::Remote::MethodArgumentError)
      end
    end
  end

  describe '.filter_response_headers' do

    it 'rejects non allowed headers' do
      headers = {:not_allowed => 'header'}

      res = utils.filter_response_headers(headers)

      res.should_not include(:not_allowed)
    end

    it 'does not reject allowed headers' do
      headers = {'content-type' => 'header'}

      res = utils.filter_response_headers(headers)

      res.should include('content-type')
    end
  end

  describe '.normalize_headers' do
    context 'when a header value is an array' do
      it 'takes the first array element' do
        headers = {'content-type' => ['application/json', 'image/gif']}

        res = utils.normalize_headers(headers)

        res.should include('content-type' => 'application/json')
      end
    end

    context 'when simple headers' do
      it 'does not affect anything' do
        headers = {'content-type' => 'application/json'}

        res = utils.normalize_headers(headers)

        res.should include('content-type' => 'application/json')
      end
    end
  end

end
