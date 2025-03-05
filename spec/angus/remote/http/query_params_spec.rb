# frozen_string_literal: true

require 'spec_helper'

require 'angus/remote/http/query_params'

describe Http::QueryParams do
  describe '.to_params' do
    let(:params) do
      { name: 'Bob',
        address: {
          phones: %w[111-111-1111 222-222-2222],
          street: '111 Ruby Ave.',
          zone: {
            country: 'Ruby',
            city: 'Gem Central'
          }
        } }
    end

    it 'returns the expected string' do
      expect(described_class.to_params(params)).to eq(
        'name=Bob&address[phones][]=111-111-1111&address[phones][]=222-222-2222&address[street]=111+Ruby+Ave.' \
        '&address[zone][country]=Ruby&address[zone][city]=Gem+Central'
      )
    end
  end
end
