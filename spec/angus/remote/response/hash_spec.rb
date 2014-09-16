require 'spec_helper'

require 'angus/remote/response/hash'

describe Angus::Remote::Response::Hash do

  let(:response_class) do
    Class.new do
      include Angus::Remote::Response::Hash

      def initialize(elements)
        @elements = elements
      end

    end
  end

  subject(:response) { response_class.new(elements) }

  describe '#to_hash' do

    context 'when a elements has a single level' do
      let(:elements) { { :id => rand(1_000), :customer_fields => %w[a b c] } }

      it 'returns the flat elements' do
        expect(response.to_hash).to eq(elements)
      end
    end

    context 'when a nested responses elements as a hash' do
      let(:brand_elements) {  { :id => rand(1_000), :name => 'Acme' } }
      let(:elements) { { :id => rand(1_000), :brand => response_class.new(brand_elements) } }

      it 'returns the flat elements' do
        expect(response.to_hash).to include(:brand => brand_elements)
      end
    end

    context 'when a nested responses elements as an array' do
      let(:division_elements) {  { :id => rand(1_000), :name => 'Acme Division' } }
      let(:commission_elements) {  { :id => rand(1_000), :name => 'Acme Commission',
                                     :divisions => [response_class.new(division_elements)] } }

      let(:elements) { { :id => rand(1_000),
                         :commissions => [[commission_elements[:id],
                                           response_class.new(commission_elements)]] } }

      it 'returns the flat elements' do
        commission = commission_elements.merge(:divisions => [division_elements])
        expect(response.to_hash).to include(:commissions => [[commission[:id], commission]])
      end
    end

  end

end