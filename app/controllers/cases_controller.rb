class CasesController < ApplicationController

  def index
    cases = Case.includes(:patient).
      where(status: filtered_param_status)
    presented = cases.map { |c| presented(c) }

    render(
      json: Response.new(:data => presented, :root => "cases"),
      status: :ok
    )
  end

  def show
    case_record = Case.includes(:patient).
      where.not(patients: { status: "deleted" }).
      find_by!(id: params[:id])

    render_one(case_record)
  end

  def create
    # TODO this method is kinda filthy.
    #      there must be a more elegant way with strong params.
    case_record = Case.new(case_params)

    if case_record.patient_id
      patient = Patient.find(case_record.patient_id)
    elsif patient_params && !case_record.patient_id
      patient = Patient.create!(patient_params)
    end

    case_record.patient_id = patient.id
    case_record.save!
    render_one(case_record, :created)
  end

  def update
    case_record = Case.find(params[:id])
    params = case_params
    params.delete(:patient_id) if params[:patient_id]

    case_record.update_attributes!(params)

    render_one(case_record)
  end

  def delete
    case_record = Case.find(params[:id])
    case_record.delete!

    render(
      json: Response.new(:data => { message: "Deleted" }),
      status: :ok
    )
  end


  private

  def filtered_param_status
    params[:status] || "active"
  end

  def presented(case_record)
    attributes = case_record.attributes
    attributes[:patient] = case_record.patient.attributes
    CasePresenter.new(attributes).present
  end

  def case_params
    params.require(:case).permit(:patient_id, :anatomy, :side)
  end

  def patient_params
    params[:case].require(:patient).permit(:name, :birth, :death, :gender)
  end

  def render_one(case_record, status = :ok)
    render(
      json: Response.new(:data => presented(case_record), :root => "case"),
      status: status
    )
  end

end