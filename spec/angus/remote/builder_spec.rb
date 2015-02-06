require 'spec_helper'

require 'angus/remote/client'
require 'angus/remote/builder'

require 'picasso-remote'

describe Angus::Remote::Builder do

  subject(:builder) { Angus::Remote::Builder }

  describe '.build' do

    let(:code_name) { 'vpos' }
    let(:operation) { double(:operation, :code_name=> 'get_users', :service_name => 'vpos', :path => '/users', :http_method => :get) }
    let(:proxy_operation) { double(:proxy_operation, :code_name=> 'get_users_proxy', :service_name => 'vpos', :path => '/users', :http_method => :get) }
    let(:glossary) { double(:glossary, :terms_hash_with_long_names => {}) }
    let(:service_definition) { double(:vpos, :name => 'Vpos', :operations => { 'users' => [operation] },
                                      :proxy_operations => [proxy_operation], :version => '0.1', :glossary => glossary) }

    let(:api_url) { 'http://localhost:8085/vpos/api/0.1/' }

    describe 'the returned class' do

      subject(:client) { builder.build(code_name, service_definition, api_url, {}) }

      it 'is of class Angus::Remote::Client' do
        should be_kind_of(Angus::Remote::Client)
      end

      it 'responds to the defined operation' do
        should respond_to(:get_users)
      end

      describe 'the generated operation' do

        let(:response) { double(:response, :code => 200, :body => JSON({ :status => 'success' })) }

        let(:service_configuration) {
          {
            'v0.1' => { 'doc_url' => 'some_url/doc', 'api_url' => 'some_url/api' }
          }
        }

        let(:service_def) {
          {
            'service' => { 'service' => 'vpos'  }, 'code_name' => 'vpos', 'version' => '0.1',
            'operations' => { 'users' => { 'get_users' => { 'name' => 'Obtener usuarios'} } }
          }

        }

        before do
          Angus::Remote::ServiceDirectory.stub(:service_configuration => service_configuration)
          Angus::Remote::ServiceDirectory.stub(:fetch_remote_service_definition => service_def)
        end

        it 'makes a request to the remote service' do
          client.should_receive(:make_request).and_return(response)

          client.get_users
        end

        describe 'the generated proxy operation' do

          before do
            Picasso::Remote::ServiceDirectory.stub(:service_configuration => { 'v0.1' => { 'doc_url' => 'some_url/doc', 'api_url' => 'some_url/api' } })
            Picasso::Remote::ServiceDirectory.stub(:fetch_remote_service_definition => { 'service' => { 'service' => 'vpos'  }, 'code_name' => 'vpos', 'version' => '0.1', 'operations' => { 'users' => { 'get_users_proxy' => { 'name' => 'Obtener usuarios' } } } })
            Picasso::Remote::Response::Builder.stub(:build_from_remote_response)
          end

          it 'makes a request to the remote service' do
            client.should_receive(:make_request).and_return(response)

            client.get_users_proxy
          end

        end

      end

    end

  end

  describe '.build_client_class' do

    let(:name) { 'Foo' }
    let(:url) { 'http://bar' }

    it 'returns a client class' do
      client_class = builder.build_client_class(name)

      client = client_class.new(url)

      client.should be_kind_of(Angus::Remote::Client)
    end

    describe 'the returned class' do
      subject { builder.build_client_class(name) }

      its(:name) { should include(name) }
      its(:to_s) { should include(name) }
    end

  end

end
