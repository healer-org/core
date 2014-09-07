module Authentication
  extend ActiveSupport::Concern

  included do
    before_filter :authenticate
  end


  private

  def authenticate
    raise Errors::ClientIdMissing unless params[:clientId].present?
  end
end