module V1
  class BaseController < ApplicationController

    use(Middleware::Authentication) do |config|
      config[:authenticator] = lambda do |req|
        auth_data = req.env["HTTP_AUTHORIZATION"]
        return false unless auth_data

        auth_data.match(/Token token="(?<client_id>.*)"$/) do |match|
          return Client.valid_key?(match[:client_id])
        end
      end
    end
  end
end
