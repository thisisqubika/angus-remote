require 'spec_helper'

require 'picasso/remote/response/builder'

require 'picasso/remote/remote_response'

describe Picasso::Remote::Response::Builder do

  subject(:builder) { Picasso::Remote::Response::Builder }

  let(:raw_response) { { 'user' => {} } }
  let(:response_class) { builder.build_response_class('Get user') }
  let(:response) { Picasso::Remote::RemoteResponse.new() }
  let(:email_field) { double(:email_field, :name => :email, :required => true, :type => 'string',
                             :elements_type => nil) }
  let(:representations_hash) { { 'user' => double(:user_rep, :fields => [email_field]) } }
  let(:glossary_terms_hash) { {} }
  let(:element) { double(:element, :name => 'user', :required => true, :type => 'user') }

  describe '.build_response_method' do

    it 'adds the method to the response class' do
      builder.build_response_method(raw_response, response_class, response, representations_hash,
                                    glossary_terms_hash, element)

      response_class.new.should respond_to(:user)
    end

  end

  describe '.build_from_representation' do

    context 'hash_value is nil' do
      it 'should return nil' do
        Picasso::Remote::Response::Builder.build_from_representation(
          nil,
          double(:type),
          double(:representations),
          double(:glossary_terms_hash)
        ).should be_nil
      end
    end
  end

  describe '.build_response_class' do
    let(:operation_name) { 'foo' }

    it 'should return a client class' do
      response_class = Picasso::Remote::Response::Builder.build_response_class(operation_name)

      response = response_class.new

      response.should be_kind_of(Picasso::Remote::RemoteResponse)
    end

    it 'the response_class#name should include the operation\'s name' do
      response_class = Picasso::Remote::Response::Builder.build_response_class(operation_name)

      response_class.name.should include(operation_name)
    end

    it 'the response_class#to_s should include the operation\'s name' do
      response_class = Picasso::Remote::Response::Builder.build_response_class(operation_name)

      response_class.to_s.should include(operation_name)
    end
  end

end