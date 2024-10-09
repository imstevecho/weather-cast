require 'rails_helper'

RSpec.describe GeocodeService do
  let(:service) { GeocodeService.new }

  describe '#coords_by_address' do
    it 'calls fetch_geo_info with correct arguments' do
      address = '123 Main St, Anytown, USA'
      expect(service).to receive(:fetch_geo_info).with('address', address, skip_cache: false)
      service.coords_by_address(address)
    end

    it 'passes skip_cache option to fetch_geo_info' do
      address = '123 Main St, Anytown, USA'
      expect(service).to receive(:fetch_geo_info).with('address', address, skip_cache: true)
      service.coords_by_address(address, skip_cache: true)
    end
  end

  describe '#coords_by_zipcode' do
    it 'calls fetch_geo_info with correct arguments' do
      zipcode = '12345'
      expect(service).to receive(:fetch_geo_info).with('zipcode', zipcode, skip_cache: false)
      service.coords_by_zipcode(zipcode)
    end

    it 'passes country_code to fetch_geo_info' do
      zipcode = 'H0H0H0'
      country_code = 'CA'
      expect(service).to receive(:fetch_geo_info).with('zipcode', zipcode, skip_cache: false)
      service.coords_by_zipcode(zipcode, country_code)
    end

    it 'passes skip_cache option to fetch_geo_info' do
      zipcode = '12345'
      expect(service).to receive(:fetch_geo_info).with('zipcode', zipcode, skip_cache: true)
      service.coords_by_zipcode(zipcode, skip_cache: true)
    end
  end

  describe '#fetch_geo_info' do
    let(:cache_key) { 'test_cache_key' }
    let(:geocode_result) { { lat: 40.7128, lon: -74.0060 } }

    before do
      allow(service).to receive(:cache_key).and_return(cache_key)
      allow(service).to receive(:geocode).and_return(geocode_result)
    end

    it 'uses CachingService with correct arguments' do
      expect(CachingService).to receive(:fetch).with(cache_key, expires_in: GeocodeService::CACHE_EXPIRATION, skip_cache: false)
      service.send(:fetch_geo_info, 'prefix', 'query')
    end

    it 'calls geocode with the provided query' do
      allow(CachingService).to receive(:fetch).and_yield
      expect(service).to receive(:geocode).with('query')
      service.send(:fetch_geo_info, 'prefix', 'query')
    end

    it 'handles errors and calls handle_error' do
      allow(CachingService).to receive(:fetch).and_raise(StandardError.new('Test error'))
      expect(service).to receive(:handle_error).with("Error in fetch_geo_info: Test error")
      service.send(:fetch_geo_info, 'prefix', 'query')
    end
  end

  describe '#fetch_geo_info with retries' do
    let(:cache_key) { 'test_cache_key' }
    let(:geocode_result) { { lat: 40.7128, lon: -74.0060 } }

    before do
      allow(service).to receive(:cache_key).and_return(cache_key)
      allow(CachingService).to receive(:fetch).and_yield
      # Stub out sleep to speed up tests
      allow(service).to receive(:sleep)
    end

    it 'retries up to MAX_RETRIES times on failure' do
      error = StandardError.new("API Error")
      call_count = 0

      allow(service).to receive(:geocode) do
        call_count += 1
        raise error if call_count < GeocodeService::MAX_RETRIES
        geocode_result
      end

      result = service.send(:fetch_geo_info, 'prefix', 'query')

      expect(call_count).to eq(GeocodeService::MAX_RETRIES)
      expect(result).to eq(geocode_result)
      expect(service).to have_received(:sleep).exactly(GeocodeService::MAX_RETRIES - 1).times
    end

    it 'raises an error if all retries fail' do
      allow(service).to receive(:geocode).and_raise(StandardError.new("API Error"))

      expect {
        service.send(:fetch_geo_info, 'prefix', 'query')
      }.to raise_error(GeocodeService::GeocodingError, /Error in fetch_geo_info: API Error/)

      expect(service).to have_received(:sleep).exactly(GeocodeService::MAX_RETRIES - 1).times
    end

    it 'does not retry or sleep on success' do
      allow(service).to receive(:geocode).and_return(geocode_result)

      result = service.send(:fetch_geo_info, 'prefix', 'query')

      expect(service).to have_received(:geocode).once
      expect(service).not_to have_received(:sleep)
      expect(result).to eq(geocode_result)
    end
  end
end
