require 'rails_helper'
require 'httparty'

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

  describe 'Retryable module' do
    it 'retries the specified number of times before raising an error' do
      max_retries = 3
      attempts = 0

      expect do
        service.with_retries(max_retries: max_retries) do
          attempts += 1
          raise StandardError, 'Test error'
        end
      end.to raise_error(StandardError, 'Test error')

      expect(attempts).to eq(max_retries)
    end

    it 'does not retry if the operation succeeds' do
      attempts = 0

      result = service.with_retries(max_retries: 3) do
        attempts += 1
        'Success'
      end

      expect(result).to eq('Success')
      expect(attempts).to eq(1)
    end

    it 'uses exponential backoff for retries' do
      max_retries = 3
      sleep_times = []

      allow(service).to receive(:sleep) { |time| sleep_times << time }

      expect do
        service.with_retries(max_retries: max_retries) do
          raise StandardError, 'Test error'
        end
      end.to raise_error(StandardError, 'Test error')

      expect(sleep_times).to eq([2, 4])
    end
  end

  describe '#geocode' do
    let(:query) { 'San Francisco' }
    let(:successful_response) do
      {
        'results' => [{
          'geometry' => { 'location' => { 'lat' => 37.7749, 'lng' => -122.4194 } },
          'address_components' => [
            { 'types' => ['postal_code'], 'short_name' => '94103' },
            { 'types' => ['country'], 'short_name' => 'US' }
          ]
        }]
      }
    end
    let(:expected_result) do
      {
        lat: 37.7749,
        lon: -122.4194,
        zip: '94103',
        country_code: 'US'
      }
    end

    context 'with successful geocoding' do
      it 'returns the geocoded information' do
        allow(service).to receive(:fetch_from_api).and_return(successful_response)
        result = service.send(:geocode, query)
        expect(result).to eq(expected_result)
      end
    end

    context 'with retries' do
      it 'succeeds after retrying' do
        call_count = 0
        allow(service).to receive(:fetch_from_api) do
          call_count += 1
          raise StandardError, 'API error' if call_count < 3
          successful_response
        end

        allow(service).to receive(:sleep) # stub sleep to speed up test

        result = service.send(:geocode, query)
        expect(result).to eq(expected_result)
        expect(call_count).to eq(3)
      end

      it 'raises a GeocodingError after max retries' do
        allow(service).to receive(:fetch_from_api).and_raise(StandardError, 'API error')
        allow(service).to receive(:sleep) # stub sleep to speed up test

        expect {
          service.send(:geocode, query)
        }.to raise_error(GeocodeService::GeocodingError, /Geocoding failed: API error/)
      end
    end

    context 'with different types of errors' do
      it 'retries on HTTParty errors' do
        call_count = 0
        allow(service).to receive(:fetch_from_api) do
          call_count += 1
          raise HTTParty::Error, 'HTTP error' if call_count < 3
          successful_response
        end

        allow(service).to receive(:sleep)

        result = service.send(:geocode, query)
        expect(result).to eq(expected_result)
        expect(call_count).to eq(3)
      end

      it 'retries on JSON parsing errors' do
        call_count = 0
        allow(service).to receive(:fetch_from_api) do
          call_count += 1
          raise JSON::ParserError, 'Invalid JSON' if call_count < 3
          successful_response
        end

        allow(service).to receive(:sleep)

        result = service.send(:geocode, query)
        expect(result).to eq(expected_result)
        expect(call_count).to eq(3)
      end
    end
  end
end
