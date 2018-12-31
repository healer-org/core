# frozen_string_literal: true

module V1
  class MissionsController < BaseController
    def show
      render_one(Mission.find_by!(id: params[:id]).attributes)
    end

    def create
      mission = Mission.create!(mission_params)

      render_one(mission.attributes, :created)
    end

    private

    def mission_params
      params.require(:mission).permit(:name)
    end

    def render_one(attributes, status = :ok)
      render(
        json: Response.new(data: attributes, root: "mission"),
        status: status
      )
    end
  end
end
