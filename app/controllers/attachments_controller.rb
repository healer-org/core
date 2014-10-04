class AttachmentsController < ApplicationController
  include Authentication

  def create
    raise ActionController::ParameterMissing.new("Missing record parameter") if record_params_missing?
    raise ActiveRecord::RecordNotFound if record_not_found?

    Attachment.create!(attachment_params)

    render status: :created, nothing: true
  end


  private

  def attachment_params
    return @attachment_params if @attachment_params

    prep_attachment_document
    @attachment_params = params.require(:attachment).permit(:record_id, :record_type, :document)
  end

  def record_not_found?
    attachment_params[:record_type].constantize.find_by_id(
      attachment_params[:record_id]
    ).nil?
  end

  def record_params_missing?
    ![attachment_params[:record_type], attachment_params[:record_id]].all?(&:present?)
  end

  def prep_attachment_document
    if params[:attachment] && params[:attachment][:data]
      data = StringIO.new(Base64.decode64(params[:attachment][:data]))
      data.class.class_eval { attr_accessor :original_filename, :content_type }
      data.original_filename = params[:attachment][:file_name]
      data.content_type = params[:attachment][:content_type]
      params[:attachment][:document] = data
    end
  end
end