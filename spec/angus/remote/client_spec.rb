require 'spec_helper'

require 'angus/remote/client'

describe Angus::Remote::Client do

  let(:url) { 'http://bar' }
  subject(:client) { Angus::Remote::Client.new(url) }

  describe '#to_s' do

    it 'returns the class name and the object id' do
      client.to_s.should eq("#<#{client.class}:#{client.object_id}>")
    end

  end

  describe '#make_request' do

    let(:success_response) { double(:response, :code => 200, :body => '[]') }
    let(:authentication_client) { double(:authentication_client) }

    before do
      Angus::Authentication::Client.stub(:new => authentication_client)
      authentication_client.stub(:prepare_request => nil, :store_session_private_key => nil)
      PersistentHTTP.any_instance.stub(:request => success_response)
    end

    it 'prepares the request with authentication' do
      client.make_request('/users', 'get', false, [], {})

      authentication_client.should have_received(:prepare_request).with(kind_of(Net::HTTP::Get),
                                                                        'GET', '//users')
    end

    it 'extracts the authentication data from the response' do
      client.make_request('/users', 'get', false, [], {})

      authentication_client.should have_received(
                                     :store_session_private_key
                                   ).with(success_response)
    end


    it 'returns the remote service response' do
      client.make_request('/users', 'get', false, [], {}).should eq(success_response)
    end

    context 'when an invalid method is used' do
      it 'raises MethodArgumentError' do
        expect {
          client.make_request('/', 'INVALID_METHOD', false, [], {})
        }.to raise_error(Angus::Remote::MethodArgumentError)
      end
    end

    context 'when less path_params that expected' do
      it 'raises PathArgumentError' do
        expect {
          client.make_request('/a/:b/c/:d', 'get', false, [], {})
        }.to raise_error(Angus::Remote::PathArgumentError)
      end
    end

    context 'when more path_params that expected' do
      it 'raises PathArgumentError' do
        expect {
          client.make_request('/a/:b/c/:d', 'get', false, [1, 2, 3], {})
        }.to raise_error(Angus::Remote::PathArgumentError)
      end
    end

    context 'when the remote service returns a severe error response' do
      let(:error_response) { double(:error_response, :code => 500, :body => '') }

      before { PersistentHTTP.any_instance.stub(:request => error_response) }

      it 'raises RemoteSevereError' do
        expect {
          client.make_request('/users', 'get', false, [], {})
        }.to raise_error(Angus::Remote::RemoteSevereError)
      end
    end

    context 'when the remote service rejects the connection' do
      before { PersistentHTTP.any_instance.stub(:request).and_raise(Errno::ECONNREFUSED) }

      it 'raises RemoteConnectionError' do
        expect {
          client.make_request('/users', 'get', false, [], {})
        }.to raise_error(Angus::Remote::RemoteConnectionError)
      end
    end

  end

end