module V1
  class TeamsController < BaseController
    def show
      team = Team.find_by!(id: params[:id])
      team_attributes = team.attributes

      render_one(team_attributes)
    end

    def create
      validate_json_request!

      team = Team.create!(team_params)

      render_one(team.attributes, :created)
    end

    private

    def team_params
      params.require(:team).permit(:name)
    end

    def render_one(attributes, status = :ok)
      render(
        json: Response.new(data: attributes, root: "team"),
        status: status
      )
    end
  end
end
