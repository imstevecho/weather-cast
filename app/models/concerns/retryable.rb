module Retryable
  extend ActiveSupport::Concern

  def with_retries(max_retries: 3)
    retries = 0
    begin
      yield
    rescue StandardError => e
      retries += 1
      if retries <= max_retries
        sleep(2**retries) # Exponential backoff
        retry
      else
        raise e
      end
    end
  end
end
