require 'json'

require 'fakefs/spec_helpers'

require 'angus/remote/utils'

describe Angus::Remote::Utils do

  include FakeFS::SpecHelpers

  subject(:utils) { Angus::Remote::Utils }

  describe '.build_request' do

    let(:request) { utils.build_request(:get, '/listing', :q => 'spec') }

    it 'returns a Net::HTTPRequest object' do
      request.should be_kind_of(Net::HTTPRequest)
    end

    context 'when not encoding as json' do
      subject { utils.build_request(:get, '/listing', {:q => 'spec'}, false) }

      describe 'the built request' do

        its(:method) { should eq('GET') }
        its(:path) { should eq('/listing?q=spec') }

      end
    end

    context 'when encoding as json' do
      subject { utils.build_request(:get, '/listing', {:q => 'spec'}, true) }

      describe 'the built request' do

        its(:method) { should eq('GET') }
        its(:path) { should eq('/listing') }
        its(:body) { should eq(JSON({:q => 'spec'})) }

      end
    end

  end


  describe '.build_base_request' do

    let(:path) { '/' }

    context 'when invalid http method' do
      it 'raises MethodArgumentError' do
        expect {
          utils.build_base_request(:invalid, path)
        }.to raise_error(Angus::Remote::MethodArgumentError)
      end
    end

    shared_examples 'a client builder' do |method, multipart, kind_of|
      context "when #{method}, multipart = #{multipart}" do
        it "returns a kind_of #{kind_of}" do
          res = utils.build_base_request(method, path, multipart)

          res.should be_a(kind_of)
        end
      end
    end

    it_behaves_like 'a client builder', :get,     false,  Net::HTTP::Get
    it_behaves_like 'a client builder', :post,    false,  Net::HTTP::Post
    it_behaves_like 'a client builder', :post,    true,   Http::MultipartMethods::Post
    it_behaves_like 'a client builder', :put,     false,  Net::HTTP::Put
    it_behaves_like 'a client builder', :put,     true,   Http::MultipartMethods::Put
    it_behaves_like 'a client builder', :delete,  false,  Net::HTTP::Delete
  end

  describe '.severe_error_response?' do
    shared_examples 'a status checker' do |code|
      it "is true when code = #{code}" do
        response = double(:response, :code => code)
        utils.severe_error_response?(response).should be
      end
    end

    it_behaves_like 'a status checker', 500
    it_behaves_like 'a status checker', 501
    it_behaves_like 'a status checker', 503
  end

  describe '.build_path' do
    let(:path) { '/users/:user_id/profile/:profile_id' }

    it 'buils a path using the given params' do
      path_params = [4201, 2]

      res = utils.build_path(path, path_params)

      res.should eq('/users/4201/profile/2')
    end

    it 'raises a PathArgumentError when received more args than needed' do
      path_params = [:more, :args, :than, :needed]

      expect {
        utils.build_path(path, path_params)
      }.to raise_error(Angus::Remote::PathArgumentError)
    end

    it 'raises a PathArgumentError when received less args than needed' do
      path_params = [:less]

      expect {
        utils.build_path(path, path_params)
      }.to raise_error(Angus::Remote::PathArgumentError)
    end
  end

  describe '.build_normal_request' do

    subject { utils.build_normal_request(:get, '/listing', {:q => 'spec'}) }

    shared_examples 'a method without body' do |method|
      describe 'the built request' do
        subject { utils.build_normal_request(method, '/listing', {:q => 'spec'}) }

        its(:method) { should eq(method.upcase) }
        its(:path) { should eq('/listing?q=spec') }
        its(:body) { should be_nil }

      end
    end

    shared_examples 'a method with body' do |method|
      describe 'the built request' do
        subject { utils.build_normal_request(method, '/listing', {:q => 'spec'}) }

        its(:method) { should eq(method.upcase) }
        its(:path) { should eq('/listing') }
        its(:body) { should eq('q=spec') }

      end
    end

    it_behaves_like 'a method without body', 'get'
    it_behaves_like 'a method without body', 'delete'
    it_behaves_like 'a method with body', 'post'
    it_behaves_like 'a method with body', 'put'

    context 'a multipart request' do
      let(:file_name) { 'some_file.txt' }

      let(:file) { File.new(file_name) }
      let(:tempfile) { Tempfile.new('tempfile', temp_dir) }
      let(:temp_dir) { '/tmp' }
      let(:some_upload_io) { UploadIO.new(file, 'application/octet-stream') }

      let(:request) { utils.build_normal_request('post', '/files', {:file => some_upload_io}) }

      before do
        Dir.mkdir('/tmp')

        File.new(file_name, 'w')
      end

      describe 'the built request' do
        subject { request }

        it 'is of class Http::MultipartMethods::MultipartBase' do
          should be_kind_of(Http::MultipartMethods::MultipartBase)
        end

        its(:method) { should eq('POST') }
        its(:path) { should eq('/files') }
        its(:body) { should be_nil }

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

      it 'its Content-Type header = application/json' do
        request['Content-Type'].should eq('application/json')
      end

      it 'its body = JSON encoded params' do
        request.body.should eq(JSON(params))
      end

    end

  end

end