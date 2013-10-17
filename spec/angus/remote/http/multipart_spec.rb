require 'spec_helper'

require 'fakefs/spec_helpers'

require 'angus/remote/http/multipart'

describe Http::Multipart do

  include FakeFS::SpecHelpers

  let(:file_name) { 'some_file.txt' }

  let(:file) { File.new(file_name) }
  let(:tempfile) { Tempfile.new('tempfile', temp_dir) }
  let(:temp_dir) { '/tmp' }
  let(:some_upload_io) { UploadIO.new(file, 'application/octet-stream') }

  before do
    Dir.mkdir('/tmp')

    File.new(file_name, 'w')
  end

  describe '.hash_contains_files?' do

    it 'should return true if one of the values in the passed hash is a file' do
      Http::Multipart.hash_contains_files?({:a => 1, :file => file}).should be_true
    end

    it 'should return true if one of the values in the passed hash is an upload io' do
      Http::Multipart.hash_contains_files?({:a => 1, :file => some_upload_io}).should be_true
    end

    it 'should return true if one of the values in the passed hash is a tempfile' do
      Http::Multipart.hash_contains_files?({:a => 1, :file => tempfile}).should be_true
    end

    it 'should return false if none of the values in the passed hash is a file' do
      Http::Multipart.hash_contains_files?({:a => 1, :b => 'nope'}).should be_false
    end

    it 'should return true if passed hash includes an a array of files' do
      Http::Multipart.hash_contains_files?({:files => [file, file]}).should be_true
    end

  end


  describe '.file_to_upload_io' do

    it 'should get the physical name of a file' do
      Http::Multipart.file_to_upload_io(file).original_filename.should == file_name
    end

    it 'should get the physical name of a file' do
      # Let's pretend this is a file upload to a rack app.
      tempfile.stub(:original_filename => 'stuff.txt')

      Http::Multipart.file_to_upload_io(tempfile).original_filename.should == 'stuff.txt'
    end

  end

  describe '.flatten_params' do

    it 'should handle complex hashs' do
      Http::Multipart.flatten_params({
                                       :foo => 'bar',
                                       :deep => {
                                         :deeper  => 1,
                                         :deeper2 => 2,
                                         :deeparray => [1,2,3],
                                         :deephasharray => [
                                           {:id => 1},
                                           {:id => 2}
                                         ]
                                       }
                                     }).sort_by(&:join).should == [
        ['foo',                         'bar'],
        ['deep[deeper]',                1],
        ['deep[deeper2]',               2],
        ['deep[deeparray][]',           1],
        ['deep[deeparray][]',           2],
        ['deep[deeparray][]',           3],
        ['deep[deephasharray][][id]',   1],
        ['deep[deephasharray][][id]',   2],
      ].sort_by(&:join)
    end

  end

  describe '::QUERY_STRING_NORMALIZER' do

    subject { Http::Multipart::QUERY_STRING_NORMALIZER }

    it 'should map a file to UploadIO' do
      (first_k, first_v) = subject.call({
                                          :file => file
                                        }).first

      first_v.should be_an UploadIO
    end

    it 'should map a Tempfile to UploadIO' do
      (first_k, first_v) = subject.call({
                                          :file => tempfile
                                        }).first

      first_v.should be_an UploadIO
    end

    it 'should map an array of files to UploadIOs' do
      subject.call({
                     :file => [file, tempfile]
                   }).each { |(k,v)| v.should be_an UploadIO }
    end

  end

end
