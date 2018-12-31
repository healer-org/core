# frozen_string_literal: true

module V1
  class ProceduresController < BaseController
    def create
      validate_json_request!

      procedure = Procedure.create!(procedure_params)

      render_one(procedure.attributes, :created)
    end

    private

    def procedure_params
      params.require(:procedure).permit! # (danger: whitelisting)
    end

    def render_one(attributes, status = :ok)
      render(
        json: Response.new(data: attributes, root: "procedure"),
        status: status
      )
    end
  end
end
