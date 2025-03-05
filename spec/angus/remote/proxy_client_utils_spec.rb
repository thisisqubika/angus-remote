# frozen_string_literal: true

require 'net/http'

require 'json'

require 'angus/remote/proxy_client_utils'

# rubocop:disable Metrics/BlockLength
describe Angus::Remote::ProxyClientUtils do
  subject(:utils) { described_class }

  describe '.build_request' do
    let(:path) { '/' }
    let(:query) { 'q=listing' }

    shared_examples 'a request builder' do |method, kind_of|
      context "when #{method}" do
        it "returns a kind_of #{kind_of}" do
          expect(utils.build_request(method, path, query)).to be_a(kind_of)
        end
      end
    end

    it_behaves_like 'a request builder', :get,     Net::HTTP::Get
    it_behaves_like 'a request builder', :post,    Net::HTTP::Post
    it_behaves_like 'a request builder', :put,     Net::HTTP::Put
    it_behaves_like 'a request builder', :delete,  Net::HTTP::Delete

    context 'with headers' do
      let(:headers) { { 'a' => 'A', 'b' => 'B' } }
      let(:request) { utils.build_request(:get, path, query, headers) }

      it { expect(request['a']).to eq('A') }
      it { expect(request['b']).to eq('B') }
    end

    context 'with body' do
      let(:body) { 'BODY' }
      let(:request) { utils.build_request(:get, path, query, {}, body) }

      it { expect(request.body).to eq(body) }
    end

    context 'when invalid http method' do
      it { expect { utils.build_request(:invalid, path, query) }.to raise_error(Angus::Remote::MethodArgumentError) }
    end
  end

  describe '.filter_response_headers' do
    context 'when non allowed headers' do
      let(:headers) { { not_allowed: 'header' } }
      let(:res) { utils.filter_response_headers(headers) }

      it { expect(res).not_to include(:not_allowed) }
    end

    context 'when allowed headers' do
      let(:headers) { { 'content-type' => 'header' } }
      let(:res) { utils.filter_response_headers(headers) }

      it { expect(res).to include('content-type') }
    end
  end

  describe '.normalize_headers' do
    context 'when a header value is an array' do
      let(:headers) { { 'content-type' => ['application/json', 'image/gif'] } }
      let(:res) { utils.normalize_headers(headers) }

      it { expect(res).to include('content-type' => 'application/json') }
    end

    context 'when simple headers' do
      let(:headers) { { 'content-type' => 'application/json' } }
      let(:res) { utils.normalize_headers(headers) }

      it { expect(res).to include('content-type' => 'application/json') }
    end
  end
end
# rubocop:enable Metrics/BlockLength
