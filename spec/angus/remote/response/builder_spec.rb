require 'spec_helper'

require 'angus/remote/response/builder'

describe Angus::Remote::Response::Builder do

  subject(:builder) { Angus::Remote::Response::Builder }

  let(:raw_response) { { 'user' => {} } }
  let(:email_field) { double(:email_field, name: :email, required: true, type: 'string',
                             elements_type: nil, optional: false) }
  let(:representations_hash) { { 'user' => double(:user_rep, fields: [email_field]) } }
  let(:glossary_terms_hash) { {} }
  let(:element) { double(:element, name: 'user', required: true, type: 'user') }

  describe '.build_response_method' do

    subject { builder.build_response_method(raw_response, representations_hash, glossary_terms_hash, element) }

    it { is_expected.to respond_to(:email) }

  end

  describe '.build_from_representation' do

    subject do
      Angus::Remote::Response::Builder.build_from_representation(nil, double(:type), double(:representations),
                                                                 double(:glossary_terms_hash))
    end

    context 'hash_value is nil' do
      it 'should return nil' do
        is_expected.to be_nil
      end
    end
  end
end
