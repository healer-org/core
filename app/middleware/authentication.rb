require "rack/response"

module Middleware
  class Authentication
    UndefinedAuthenticatorError = Class.new(StandardError)

    DEFAULT_CONFIG = {
      failed_auth_message: "Not Authenticated"
    }.freeze

    attr_reader :config, :app, :failed_response

    def initialize(app, options = {})
      @app = app
      @config = DEFAULT_CONFIG.merge(options)

      yield config if block_given?

      raise UndefinedAuthenticatorError if config.fetch(:authenticator, nil).nil?
      @failed_response = Rack::Response.new(
        config[:failed_auth_message], 401, { "Content-Type" => "text/plain"}
      )
    end

    def call(env)
      req = Rack::Request.new(env)
      config[:authenticator].call(req) ? app.call(env) : failed_response
    end
  end
end