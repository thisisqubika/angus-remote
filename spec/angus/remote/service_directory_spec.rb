# frozen_string_literal: true

require 'spec_helper'

require 'angus/remote/service_directory'

# rubocop:disable Metrics/BlockLength
describe Angus::Remote::ServiceDirectory do
  let(:service_directory) { described_class }

  let(:code_name) { 'vpos' }
  let(:version) { '0.1' }
  let(:doc_url) { 'http://example.com/some_url/doc' }
  let(:api_url) { 'http://example.com/some_url/api' }

  before do
    allow(described_class).to receive(:service_configuration).and_return({ "v#{version}" => {
                                                                           'doc_url' => doc_url, 'api_url' => api_url
                                                                         } })
  end

  describe '.lookup' do
    context 'when a definition hash is given' do
      let(:service_definition) { Angus::SDoc::Definitions::Service.new }

      before do
        allow(service_directory).to receive(:fetch_remote_service_definition).and_return({})
        allow(Angus::SDoc::DefinitionsReader).to receive(:build_service_definition).and_return(service_definition)
      end

      it 'returns the service definition' do
        expect(service_directory.lookup({ code_name: code_name, version: version, doc_url: version, api_url: version }))
          .to be_a(Angus::Remote::Client)
      end
    end

    context 'when the code name and version are given' do
      it { expect(service_directory.lookup(code_name, version)).to be_a(Angus::Remote::Client) }
    end
  end

  describe '.get_service_definition' do
    let(:service_definition) { Angus::SDoc::Definitions::Service.new }

    context 'when a file url' do
      let(:doc_url) { 'file://path/to/doc' }

      before { allow(Angus::SDoc::DefinitionsReader).to receive(:service_definition).and_return(service_definition) }

      it 'builds the service definition from the path' do
        service_directory.get_service_definition(code_name, version)

        expect(Angus::SDoc::DefinitionsReader).to have_received(:service_definition).with('path/to/doc')
      end

      it { expect(service_directory.get_service_definition(code_name, version)).to eq(service_definition) }
    end

    context 'when a remote url' do
      let(:doc_url) { 'some_url/doc' }
      let(:definition_hash) { {} }

      before do
        allow(service_directory).to receive(:fetch_remote_service_definition).and_return(definition_hash)
        allow(Angus::SDoc::DefinitionsReader).to receive(:build_service_definition).and_return(service_definition)
      end

      it 'gets the definition hash from the remote service' do
        service_directory.get_service_definition(code_name, version)

        expect(service_directory).to have_received(:fetch_remote_service_definition).with(
          doc_url, code_name, version
        )
      end

      it 'builds the service definition from the definition hash' do
        service_directory.get_service_definition(code_name, version)

        expect(Angus::SDoc::DefinitionsReader).to have_received(:build_service_definition).with(definition_hash)
      end

      it { expect(service_directory.get_service_definition(code_name, version)).to eq(service_definition) }
    end
  end
end
# rubocop:enable Metrics/BlockLength
