module Retryable
  extend ActiveSupport::Concern

  def with_retries(max_retries:)
    retries = 0
    begin
      yield
    rescue StandardError, HTTParty::Error, JSON::ParserError => e
      retries += 1
      if retries < max_retries
        sleep_with_backoff(retries)
        retry
      else
        raise e
      end
    end
  end

  private

  def sleep_with_backoff(retries)
    sleep(2**retries) # exponential backoff
  end
end
