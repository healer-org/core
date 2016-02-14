module V1
  class CasePresenter < BasePresenter
    SIMPLE_ATTRIBUTES = %i(id anatomy side).freeze

    def initialize(case_attributes)
      @case_attributes = case_attributes
      @patient_attributes = case_attributes[:patient] || {}
      @attachment_attributes = case_attributes[:attachments] || nil
      @procedure_attributes = case_attributes[:procedures] || nil
    end

    def present
      {}.tap do |presented|
        SIMPLE_ATTRIBUTES.each do |k|
          presented[k] = case_attributes[k.to_s]
        end
        presented[:patient] = PatientPresenter.new(patient_attributes).present
        presented[:attachments] = presented_attachments if attachment_attributes
        presented[:procedures] = presented_procedures if procedure_attributes
      end
    end

    private

    attr_reader :case_attributes
    attr_reader :patient_attributes
    attr_reader :attachment_attributes
    attr_reader :procedure_attributes

    def presented_attachments
      attachment_attributes.map { |attrs| AttachmentPresenter.new(attrs).present }
    end

    def presented_procedures
      procedure_attributes.map { |attrs| attrs }
    end
  end
end
