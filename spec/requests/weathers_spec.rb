require 'rails_helper'

RSpec.describe "Weathers", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/weathers/index"
      expect(response).to have_http_status(:success)
    end
  end

end
