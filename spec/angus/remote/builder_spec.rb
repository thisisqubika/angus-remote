# frozen_string_literal: true

require 'spec_helper'

require 'angus/remote/client'
require 'angus/remote/builder'

# rubocop:disable Metrics/BlockLength
describe Angus::Remote::Builder do
  subject(:builder) { described_class }

  describe '.build' do
    let(:operation) do
      double(:operation, code_name: 'get_users', service_name: 'vpos', path: '/users', http_method: :get)
    end
    let(:proxy_operation) do
      double(:proxy_operation, code_name: 'get_users_proxy', service_name: 'vpos', path: '/users',
                               http_method: :get)
    end
    let(:glossary) { double(:glossary, terms_hash_with_long_names: {}) }
    let(:service_definition) do
      double(:vpos, name: 'Vpos', operations: { 'users' => [operation] },
                    proxy_operations: [proxy_operation], version: '0.1', glossary: glossary)
    end

    let(:client) { builder.build('vpos', service_definition, 'http://localhost:8085/vpos/api/0.1/', {}) }

    describe 'the returned class' do
      it { expect(client).to be_a(Angus::Remote::Client) }

      it { expect(client).to respond_to(:get_users) }
    end

    describe 'the generated operation' do
      let(:response) { double(:response, code: 200, body: JSON({ status: 'success' })) }

      let(:service_configuration) do
        {
          'v0.1' => { 'doc_url' => 'some_url/doc', 'api_url' => 'some_url/api' }
        }
      end

      let(:service_def) do
        {
          'service' => { 'service' => 'vpos' }, 'code_name' => 'vpos', 'version' => '0.1',
          'operations' => { 'users' => { 'get_users' => { 'name' => 'Obtener usuarios' } } }
        }
      end

      before do
        allow(Angus::Remote::ServiceDirectory).to receive_messages(service_configuration: service_configuration,
                                                                   fetch_remote_service_definition: service_def)
        allow(client).to receive(:make_request).and_return(response)
      end

      it 'makes a request to the remote service' do
        client.get_users
        expect(client).to have_received(:make_request)
      end

      describe 'the generated proxy operation' do
        let(:service_configuration) { { 'v0.1' => { 'doc_url' => 'some_url/doc', 'api_url' => 'some_url/api' } } }
        let(:service_def) do
          {
            'service' => { 'service' => 'vpos' },
            'code_name' => 'vpos',
            'version' => '0.1',
            'operations' => { 'users' => { 'get_users_proxy' => { 'name' => 'Obtener usuarios' } } }
          }
        end

        before do
          allow(Angus::Remote::ServiceDirectory).to receive_messages(service_configuration: service_configuration,
                                                                     fetch_remote_service_definition: service_def)

          allow(Angus::Remote::Response::Builder).to receive(:build_from_remote_response)
        end

        it 'makes a request to the remote service' do
          client.get_users_proxy

          expect(client).to have_received(:make_request)
        end
      end
    end
  end

  describe '.build_client_class' do
    subject { client_class.new(url) }

    let(:name) { 'Foo' }
    let(:url) { 'http://bar' }
    let(:client_class) { builder.build_client_class(name) }

    it { is_expected.to be_a(Angus::Remote::Client) }

    describe 'the returned class' do
      subject { builder.build_client_class(name) }

      its(:name) { is_expected.to include(name) }
      its(:to_s) { is_expected.to include(name) }
    end
  end
end
# rubocop:enable Metrics/BlockLength
