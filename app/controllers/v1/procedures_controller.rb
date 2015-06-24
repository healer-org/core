class V1::ProceduresController < V1::BaseController

  def create
    validate_json_request!

    procedure = Procedure.create!(filter_params)

    render_one(procedure.attributes, :created)
  end


  private

  def filter_params
    params.require(:procedure).permit(:case_id)
  end

  def render_one(attributes, status = :ok)
    render(
      json: Response.new(:data => attributes, :root => "procedure"),
      status: status
    )
  end

end