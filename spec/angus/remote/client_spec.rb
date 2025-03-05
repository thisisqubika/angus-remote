# frozen_string_literal: true

require 'spec_helper'

require 'angus/remote/client'

# rubocop:disable Metrics/BlockLength
describe Angus::Remote::Client do
  subject(:client) { described_class.new(url) }

  let(:url) { 'http://bar' }

  describe '#to_s' do
    it 'returns the class name and the object id' do
      expect(client.to_s).to eq("#<#{client.class}:#{client.object_id}>")
    end
  end

  describe '#make_request' do
    let(:success_response) { double(:response, code: 200, body: '[]') }
    let(:authentication_client) { double(:authentication_client) }

    before do
      allow(Angus::Authentication::Client).to receive(:new).and_return(authentication_client)
      allow(authentication_client).to receive(:prepare_request)
      allow(authentication_client).to receive(:store_session_private_key)
      allow_any_instance_of(PersistentHTTP).to receive(:request).and_return(success_response)
    end

    it 'prepares the request with authentication' do
      client.make_request('/users', 'get', false, [], {})

      expect(authentication_client).to have_received(:prepare_request).with(kind_of(Net::HTTP::Get), 'GET', '//users')
    end

    it 'returns the remote service response' do
      expect(client.make_request('/users', 'get', false, [], {})).to eq(success_response)
    end

    context 'when an invalid method is used' do
      it 'raises MethodArgumentError' do
        expect do
          client.make_request('/', 'INVALID_METHOD', false, [], {})
        end.to raise_error(Angus::Remote::MethodArgumentError)
      end
    end

    context 'when less path_params that expected' do
      it 'raises PathArgumentError' do
        expect do
          client.make_request('/a/:b/c/:d', 'get', false, [], {})
        end.to raise_error(Angus::Remote::PathArgumentError)
      end
    end

    context 'when more path_params that expected' do
      it 'raises PathArgumentError' do
        expect do
          client.make_request('/a/:b/c/:d', 'get', false, [1, 2, 3], {})
        end.to raise_error(Angus::Remote::PathArgumentError)
      end
    end

    context 'when the remote service returns a severe error response' do
      let(:error_response) { double(:error_response, code: 500, body: '') }

      before { allow_any_instance_of(PersistentHTTP).to receive(:request).and_return(error_response) }

      it 'raises RemoteSevereError' do
        expect do
          client.make_request('/users', 'get', false, [], {})
        end.to raise_error(Angus::Remote::RemoteSevereError)
      end
    end

    context 'when the remote service rejects the connection' do
      before { allow_any_instance_of(PersistentHTTP).to receive(:request).and_raise(Errno::ECONNREFUSED) }

      it 'raises RemoteConnectionError' do
        expect do
          client.make_request('/users', 'get', false, [], {})
        end.to raise_error(Angus::Remote::RemoteConnectionError)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
