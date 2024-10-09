require 'rails_helper'

RSpec.describe GeocodeService do
  let(:service) { described_class.new }

  describe '#coords_by_address' do
    context 'when fetching geolocation using address' do
      before do
        stub_request(:get, /maps\.googleapis\.com/)
          .to_return(status: 200, body: {
            results: [{
              geometry: { location: { lat: 37.7749, lng: -122.4194 } },
              address_components: [
                { types: ['postal_code'], short_name: '94103' },
                { types: ['country'], short_name: 'US' }
              ]
            }]
          }.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns the correct result' do
        result = service.coords_by_address('San Francisco')
        expect(result).to eq({ data: { lat: 37.7749, lon: -122.4194, zip: '94103', country_code: 'US' }, is_from_cache: false })
      end
    end
  end

  describe '#coords_by_zipcode' do
    context 'when fetching geolocation using zipcode' do
      before do
        stub_request(:get, /maps\.googleapis\.com/)
          .to_return(status: 200, body: {
            results: [{
              geometry: { location: { lat: 37.7749, lng: -122.4194 } },
              address_components: [
                { types: ['postal_code'], short_name: '94103' },
                { types: ['country'], short_name: 'US' }
              ]
            }]
          }.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns the correct result' do
        result = service.coords_by_zipcode('94103')
        expect(result).to eq({ data: { lat: 37.7749, lon: -122.4194, zip: '94103', country_code: 'US' }, is_from_cache: false })
      end
    end
  end
end
