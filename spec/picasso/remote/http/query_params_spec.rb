require 'spec_helper'

require 'picasso/remote/http/query_params'

describe Http::QueryParams do

  describe '.to_params' do

    let(:params) {
      { :name => 'Bob',
        :address => {
          :phones => %w[111-111-1111 222-222-2222],
          :street => '111 Ruby Ave.',
          :zone => {
            :country => 'Ruby',
            :city => 'Gem Central',
          }
        }
      }
    }

    it 'returns the expected string' do
      Http::QueryParams.to_params(params).should eq('name=Bob&address[phones][]=111-111-1111&address[phones][]=222-222-2222&address[street]=111%20Ruby%20Ave.&address[zone][country]=Ruby&address[zone][city]=Gem%20Central')
    end

  end

end