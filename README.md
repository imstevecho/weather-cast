# Weather Forecasting App

This Ruby on Rails application provides weather forecast information based on a given address. Utilizing the OpenWeatherMap API for weather data and Google Maps Geocoding API for location services, the app delivers current weather conditions, including temperature, and optionally, high/low temperatures and an extended forecast. It features caching of forecast data to optimize performance and reduce API calls.

## Demo

Explore the live demo of the Weather Forecasting App: [https://weathercast-8552d655ca7b.herokuapp.com](https://weathercast-8552d655ca7b.herokuapp.com). This demo showcases the app's capabilities to input an address, retrieve, and display the forecast data with caching functionality.

## Features

- **Address Input:** Users can input any address to retrieve the current weather forecast.
- **Forecast Data:** Displays current temperature, with optional high/low and extended forecasts.
- **Caching:** Forecast details are cached for 30 minutes using zip codes to reduce redundant API calls, enhancing performance.
- **Error Handling:** Implements error handling for API failures and invalid addresses.

## Design Patterns Used

This application employs several design patterns to ensure code modularity, scalability, and ease of maintenance:

- **Service Objects:** For encapsulating the business logic of fetching weather and geocoding information, thereby keeping the controllers slim and focused on request handling.
- **Singleton Pattern:** Utilized in the `CachingService` class to provide a global point of access to the caching functionality and ensure only one instance of the cache manager is created.
- **Module Mixin:** The `CacheKeyGenerator` module is mixed into services that require generating a standardized cache key, promoting DRY (Don't Repeat Yourself) principles and code reuse.
- **Strategy Pattern:** Demonstrated through the use of different services (`ForecastService`, `GeocodeService`) that can be easily swapped or extended without affecting the client code, allowing for flexible handling of various APIs.
- **Decorator Pattern:** While not explicitly shown in the provided code, this pattern could be applied to extend the functionality of objects dynamically, such as adding formatting or additional data processing to the weather data before presenting it to the user.

These patterns contribute to the application's robust architecture, making it easier to add new features, maintain the code, and handle complex functionalities with ease.

## Getting Started

### Prerequisites

- Ruby on Rails
- A valid OpenWeatherMap API key (set as `OPENWEATHER_API_KEY` in your environment variables)
- A valid Google Maps Geocoding API key (set as `GOOGLE_MAPS_API_KEY` in your environment variables)

### Installation

1. Clone the repository to your local machine.
2. Install the required gems by running `bundle install`.
3. Set up your environment variables for `OPENWEATHER_API_KEY` and `GOOGLE_MAPS_API_KEY`.
4. Start the Rails server with `rails s`.

## Usage

Navigate to the application URL, input an address, and submit to retrieve the weather forecast. The application will display the current temperature and, if implemented, high/low temperatures and an extended forecast. If the forecast for the given zip code is cached, an indicator will show the data is pulled from the cache.

## Contributing

Contributions are welcome! For major changes, please open an issue first to discuss what you would like to change. Please ensure to update tests as appropriate.

## License

[MIT](https://choosealicense.com/licenses/mit/)
