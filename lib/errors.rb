module Errors
  class ClientIdMissing < ActionController::ParameterMissing
    def initialize(param = "clientId")
      super
    end
  end
end
