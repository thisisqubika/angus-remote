require 'spec_helper'

require 'angus/remote/service_directory'

describe Angus::Remote::ServiceDirectory do

  subject(:service_directory) { Angus::Remote::ServiceDirectory }

  let(:code_name) { 'vpos' }
  let(:version) { '0.1' }
  let(:doc_url) { 'http://example.com/some_url/doc' }
  let(:api_url) { 'http://example.com/some_url/api' }

  before do
    Angus::Remote::ServiceDirectory.stub(:service_configuration => { "v#{version}" => {
      'doc_url' => doc_url, 'api_url' => api_url }
    })
  end

  describe '.lookup' do

    context 'when a definition hash is given' do
      before do
        service_directory.stub(:fetch_remote_service_definition => {})
        service_definition = Angus::SDoc::Definitions::Service.new
        Angus::SDoc::DefinitionsReader.stub(:build_service_definition => service_definition)
      end

      it 'returns the service definition' do
        service_directory.lookup(
          { :code_name => code_name, :version => version, :doc_url => version, :api_url => version}
        ).should be_kind_of(Angus::Remote::Client)
      end
    end

    context 'when the code name and version are given' do
      it 'returns the service definition' do
        service_directory.lookup(code_name, version).should be_kind_of(Angus::Remote::Client)
      end
    end

  end

  describe '.get_service_definition' do

    let(:service_definition) { Angus::SDoc::Definitions::Service.new }

    context 'when a file url' do
      let(:doc_url) { 'file://path/to/doc' }

      before do
        Angus::SDoc::DefinitionsReader.stub(:service_definition => service_definition)
      end

      it 'builds the service definition from the path' do
        Angus::SDoc::DefinitionsReader.should_receive(
          :service_definition
        ).with('path/to/doc')

        service_directory.get_service_definition(code_name, version)
      end

      it 'returns the service definition' do
        service_directory.get_service_definition(code_name, version).should eq(service_definition)
      end
    end

    context 'when a remote url' do
      let(:doc_url) { 'some_url/doc' }
      let(:definition_hash) { {} }

      before do
        service_directory.stub(:fetch_remote_service_definition => definition_hash)
        Angus::SDoc::DefinitionsReader.stub(:build_service_definition => service_definition)
      end

      it 'gets the definition hash from the remote service' do
        service_directory.should_receive(:fetch_remote_service_definition).with(
          doc_url, code_name, version
        ).and_return(definition_hash)

        service_directory.get_service_definition(code_name, version)
      end

      it 'builds the service definition from the definition hash' do
        Angus::SDoc::DefinitionsReader.should_receive(
          :build_service_definition
        ).with(definition_hash)

        service_directory.get_service_definition(code_name, version)
      end

      it 'returns the service definition' do
        service_directory.get_service_definition(code_name, version).should eq(service_definition)
      end
    end

  end

end