require 'rails_helper'

RSpec.describe GeocodeService do
  describe '#coords_by_address' do
    context 'when fetching geolocation using address' do
      it 'returns the correct result' do
        VCR.use_cassette('geocode_service_address') do
          service = GeocodeService.new
          result = service.coords_by_address('1600 Amphitheatre Parkway, Mountain View, CA')

          expect(result[:data]).to include(
            lat: be_within(0.01).of(37.4224764),
            lon: be_within(0.01).of(-122.0842499),
            zip: '94043',
            country_code: 'US'
          )
        end
      end
    end
  end
end
