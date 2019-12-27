# frozen_string_literal: true

module V1
  class CasesController < BaseController
    def index
      cases = base_scope.where(status: filtered_param_status)
      presented = cases.map { |c| presented(c) }

      render(
        json: Response.new(data: presented, root: "cases"),
        status: :ok
      )
    end

    def show
      case_record = base_scope.find_by!(id: params[:id])

      render_one(case_record)
    end

    def create
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
      case_record = Case.active.find(params[:id])
      params = case_params
      params.delete(:patient_id) if params[:patient_id]

      case_record.update!(params)

      render_one(case_record)
    end

    def destroy
      case_record = Case.active.find(params[:id])
      case_record.delete!

      render(
        json: Response.new(data: { message: "Deleted" }),
        status: :ok
      )
    end

    private

    def base_scope
      scope = Case.active.includes(:patient).where.not(patients: { status: "deleted" })
      scope = scope.includes(:attachments) if show_attachments?
      scope = scope.includes(:procedures) if show_procedures?
      scope
    end

    def filtered_param_status
      params[:status] || "active"
    end

    def presented(case_record)
      attributes = case_record.attributes
      attributes[:patient] = case_record.patient.attributes
      attributes[:attachments] = case_record.attachments.map.map(&:attributes) if show_attachments?
      attributes[:procedures] = case_record.procedures.map(&:attributes) if show_procedures?

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
        json: Response.new(data: presented(case_record), root: "case"),
        status: status
      )
    end

    def show_attachments?
      params[:showAttachments] == "true"
    end

    def show_procedures?
      params[:showProcedures] == "true"
    end
  end
end
