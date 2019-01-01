# frozen_string_literal: true

module V1
  class BaseController < ApplicationController
    before_action :validate_content_type!, only: [:index, :show, :create, :update, :destroy]
    # use(Middleware::Authentication) do |config|
    #   config[:authenticator] = lambda do |req|
    #     auth_data = req.env["HTTP_AUTHORIZATION"]
    #     return false unless auth_data

    #     auth_data.match(/Token token="(?<client_id>.*)"$/) do |match|
    #       return Client.valid_key?(match[:client_id])
    #     end
    #   end
    # end

    def validate_content_type!
      return if request.content_type == "application/json"
      return if request.get? && request.content_type == "text/plain"
      return if !request.get? && request.content_type == "application/x-www-form-urlencoded"
      raise ActionController::BadRequest, "Invalid content type"
    end
  end
end