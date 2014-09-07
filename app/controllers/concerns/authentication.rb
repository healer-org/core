include ActionController::HttpAuthentication::Token::ControllerMethods

module Authentication
  extend ActiveSupport::Concern

  included do
    before_filter :authenticate
  end


  private

  def authenticate
    authenticate_token || render_unauthorized
  end

  def authenticate_token
    return true if Rails.env == "development"

    authenticate_with_http_token do |token, options|
      true
      # User.find_by(auth_token: token)
    end
  end

  def render_unauthorized
    self.headers["WWW-Authenticate"] = "Token realm='Application'"
    render_error(code: :unauthorized, message: "Bad credentials")
  end
end
