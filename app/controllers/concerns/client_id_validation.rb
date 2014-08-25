module ClientIdValidation
  extend ActiveSupport::Concern

  included do
    before_filter :enforce_client_id
  end


  private

  def enforce_client_id
    raise Errors::ClientIdMissing unless params[:client_id].present?
  end
end