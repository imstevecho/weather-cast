require 'rails_helper'

RSpec.describe GeocodeService do
  let(:service) { described_class.new }
  let(:address) { '123 main st, New York, NY' }
  let(:cache_key) { "geocode_#{address.gsub(/\s+/, '_').downcase}" }

  let(:fake_http_response) do
    instance_double(HTTParty::Response,
                    body: JSON.generate(results: [{ geometry: { location: { lat: 'some_lat', lng: 'some_lon' } } }]),
                    code: 200,
                    success?: true)
  end

  describe '#address' do
    before do
      allow(HTTParty).to receive(:get).and_return(fake_http_response)
    end

    it 'fetches the geolocation using address' do
      result = service.address(address)

      expect(HTTParty).to have_received(:get).with(
        'https://maps.googleapis.com/maps/api/geocode/json',
        query: hash_including(address: address, key: ENV['GOOGLE_MAPS_API_KEY'])
      )

      expect(result).to eq(
        lat: 'some_lat',
        lon: 'some_lon'
      )
    end
  end

  context 'cache' do
    let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }
    let(:cache) { Rails.cache }

    before do
      allow(Rails).to receive(:cache).and_return(memory_store)
      Rails.cache.clear
    end

    it 'uses caching when skip_cache is false' do
      expect(Rails.cache).to receive(:fetch).with(cache_key, expires_in: 1.month).and_call_original
      service.address(address)
      expect(Rails.cache.exist?(cache_key)).to be true
    end

    it 'bypasses caching when skip_cache is true' do
      service.address(address, skip_cache: true)
      expect(Rails.cache.exist?(cache_key)).to be false
    end
  end
end
