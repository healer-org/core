module Errors
  class ClientIdMissing < ActionController::ParameterMissing
    def initialize(param = "client_id")
      super
    end
  end
end
