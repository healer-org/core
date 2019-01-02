# frozen_string_literal: true

module V1
  class AttachmentsController < BaseController
    def create
      if required_params_missing?
        raise ActionController::ParameterMissing, @missing_params.join(", ")
      end
      raise ActiveRecord::RecordNotFound if record_not_found?

      Attachment.create!(attachment_params)

      render status: :created, nothing: true
    end

    private

    def attachment_params
      return @attachment_params if @attachment_params

      prep_document
      @attachment_params = params.require(:attachment).permit(:record_id, :record_type, :document)
    end

    def record_not_found?
      attachment_params[:record_type].constantize.find_by(
        id: attachment_params[:record_id]
      ).nil?
    end

    def required_params_missing?
      @missing_params = %i[record_id record_type data content_type file_name].reject do |req|
        params[:attachment][req].present?
      end

      @missing_params.present?
    end

    def prep_document
      return if !params[:attachment] && !params[:attachment][:data]

      data = StringIO.new(Base64.decode64(params[:attachment][:data]))
      data.class.class_eval { attr_accessor :original_filename, :content_type }
      data.original_filename = params[:attachment][:file_name]
      data.content_type = params[:attachment][:content_type]
      params[:attachment][:document] = data
    end
  end
end
