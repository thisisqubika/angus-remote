# frozen_string_literal: true

require 'spec_helper'

require 'json'

require 'fakefs/spec_helpers'

require 'angus/remote/utils'

# rubocop:disable Metrics/BlockLength
describe Angus::Remote::Utils do
  include FakeFS::SpecHelpers

  subject(:utils) { described_class }

  describe '.build_request' do
    subject { utils.build_request(:get, '/listing', { q: 'spec' }) }

    it { is_expected.to be_a(Net::HTTPRequest) }

    context 'when not encoding as json' do
      subject { utils.build_request(:get, '/listing', { q: 'spec' }, false) }

      describe 'the built request' do
        its(:method) { is_expected.to eq('GET') }
        its(:path) { is_expected.to eq('/listing?q=spec') }
      end
    end

    context 'when encoding as json' do
      subject { utils.build_request(:get, '/listing', { q: 'spec' }, true) }

      describe 'the built request' do
        its(:method) { is_expected.to eq('GET') }
        its(:path) { is_expected.to eq('/listing') }
        its(:body) { is_expected.to eq(JSON({ q: 'spec' })) }
      end
    end
  end

  describe '.build_base_request' do
    let(:path) { '/' }

    context 'when invalid http method' do
      it 'raises MethodArgumentError' do
        expect do
          utils.build_base_request(:invalid, path)
        end.to raise_error(Angus::Remote::MethodArgumentError)
      end
    end

    shared_examples 'a client builder' do |method, kind_of|
      context "when #{method}" do
        let(:request) { utils.build_base_request(method, path) }

        it { expect(request).to be_a(kind_of) }
      end
    end

    it_behaves_like 'a client builder', :get,     Net::HTTP::Get
    it_behaves_like 'a client builder', :post,    Net::HTTP::Post
    it_behaves_like 'a client builder', :put,     Net::HTTP::Put
    it_behaves_like 'a client builder', :delete,  Net::HTTP::Delete
  end

  describe '.severe_error_response?' do
    shared_examples 'a status checker' do |code|
      let(:response) { double(:response, code: code) }

      it { expect(utils.severe_error_response?(response)).to be true }
    end

    it_behaves_like 'a status checker', 500
    it_behaves_like 'a status checker', 501
    it_behaves_like 'a status checker', 503
  end

  describe '.build_path' do
    let(:path) { '/users/:user_id/profile/:profile_id' }
    let(:path_params) { [4201, 2] }
    let(:builded_path) { utils.build_path(path, path_params) }

    it { expect(builded_path).to eq('/users/4201/profile/2') }

    context 'when received more args than needed' do
      path_params = %i[more args than needed]

      it { expect { utils.build_path(path, path_params) }.to raise_error(Angus::Remote::PathArgumentError) }
    end

    it 'raises a PathArgumentError when received less args than needed' do
      path_params = [:less]

      expect { utils.build_path(path, path_params) }.to raise_error(Angus::Remote::PathArgumentError)
    end
  end

  describe '.build_normal_request' do
    subject { utils.build_normal_request(:get, '/listing', { q: 'spec' }) }

    shared_examples 'a method without body' do |method|
      describe 'the built request' do
        subject { utils.build_normal_request(method, '/listing', { q: 'spec' }) }

        its(:method) { is_expected.to eq(method.upcase) }
        its(:path) { is_expected.to eq('/listing?q=spec') }
        its(:body) { is_expected.to be_nil }
      end
    end

    shared_examples 'a method with body' do |method|
      describe 'the built request' do
        subject { utils.build_normal_request(method, '/listing', { q: 'spec' }) }

        its(:method) { is_expected.to eq(method.upcase) }
        its(:path) { is_expected.to eq('/listing') }
        its(:body) { is_expected.to eq('q=spec') }
      end
    end

    it_behaves_like 'a method without body', 'get'
    it_behaves_like 'a method without body', 'delete'
    it_behaves_like 'a method with body', 'post'
    it_behaves_like 'a method with body', 'put'

    context 'when a param is an array' do
      subject(:request) { utils.build_normal_request('put', '/listing', { ids: %w[a b] }) }

      # Rack only rebuilds an Array server-side when the key ends in `[]`; without it,
      # a single-element array collapses into a bare string on the receiving end.
      its(:body) { is_expected.to eq('ids[]=a&ids[]=b') }
    end

    context 'when it is a multipart request' do
      let(:file_name) { 'some_file.txt' }

      let(:file) { File.new(file_name) }
      let(:tempfile) { Tempfile.new('tempfile', temp_dir) }
      let(:temp_dir) { '/tmp' }

      let(:request) { utils.build_normal_request('post', '/files', { file: file }) }

      before do
        Dir.mkdir('/tmp')

        File.new(file_name, 'w')
      end

      describe 'the built request' do
        subject { request }

        its(:method) { is_expected.to eq('POST') }
        its(:path) { is_expected.to eq('/files') }
      end
    end
  end

  describe '.build_json_request' do
    let(:method) { :post }
    let(:path)   { '/' }
    let(:params) { [0, 1, 2] }

    let(:request) do
      utils.build_json_request(method, path, params)
    end

    describe 'the returned request' do
      it { expect(request['Content-Type']).to eq('application/json') }
      it { expect(request.body).to eq(JSON(params)) }
    end
  end
end
# rubocop:enable Metrics/BlockLength
