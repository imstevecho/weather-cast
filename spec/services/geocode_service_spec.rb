require 'rails_helper'

RSpec.describe GeocodeService do
  let(:service) { described_class.new }
  let(:address) { '123 main st, New York, NY' }
  let(:zipcode) { 12_345 }
  let(:cache_key) { "geocode_#{address.gsub(/\s+/, '_').downcase}" }

  fake_http_response = {
    'results' => [
      {
        'geometry' => {
          'location' => {
            'lat' => 37.7749,
            'lng' => -122.4194
          }
        },
        'address_components' => [
          {
            'types' => ['locality'],
            'short_name' => 'SF'
          },
          {
            'types' => ['postal_code'],
            'short_name' => '94103'
          }
        ]
      }
    ]
  }

  describe '#coords_by_address' do
    before do
      allow(HTTParty).to receive(:get).and_return(double(body: fake_http_response.to_json, success?: true))
    end

    context 'when fetching geolocation using address' do
      it 'returns the correct result' do
        result = service.coords_by_address(address)

        expect(HTTParty).to have_received(:get).with(
          'https://maps.googleapis.com/maps/api/geocode/json',
          query: hash_including(address: address, key: ENV['GOOGLE_MAPS_API_KEY'])
        )

        expect(result).to eq({ data: { lat: 37.7749, lon: -122.4194, zip: '94103' }, is_from_cache: false })
      end
    end

    context 'when fetching geolocation using zipcode' do
      it 'returns the correct result' do
        result = service.coords_by_address(zipcode)

        expect(HTTParty).to have_received(:get).with(
          'https://maps.googleapis.com/maps/api/geocode/json',
          query: hash_including(address: zipcode, key: ENV['GOOGLE_MAPS_API_KEY'])
        )

        expect(result).to eq({ data: { lat: 37.7749, lon: -122.4194, zip: '94103' }, is_from_cache: false })
      end
    end
  end

  describe 'caching' do
    let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }
    let(:cache) { Rails.cache }

    before do
      allow(HTTParty).to receive(:get).and_return(double(body: fake_http_response.to_json, success?: true))
      allow(Rails).to receive(:cache).and_return(memory_store)
      Rails.cache.clear
    end

    context 'when skip_cache is false' do
      it 'uses caching and returns the correct result' do
        first_result = service.coords_by_address(address)
        expect(first_result[:is_from_cache]).to eq(false)

        second_result = service.coords_by_address(address)
        expect(second_result[:is_from_cache]).to eq(true)
      end
    end

    context 'when skip_cache is true' do
      it 'bypasses caching and returns the correct result' do
        result = service.coords_by_address(address, skip_cache: true)
        expect(result[:is_from_cache]).to eq(false)
      end
    end
  end
end
