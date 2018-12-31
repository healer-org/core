# frozen_string_literal: true

module V1
  class AppointmentPresenter < BasePresenter
    SIMPLE_ATTRIBUTES = %i[
      id
      start
      order
      end
      location
    ].freeze

    def initialize(attributes)
      @attributes = attributes
      @patient_attributes = attributes[:patient] || {}
    end

    def present
      {}.tap do |presented|
        SIMPLE_ATTRIBUTES.each do |k|
          presented[k] = attributes[k.to_s]
        end
        presented[:patient] = PatientPresenter.new(patient_attributes).present
      end
    end

    private

    attr_reader :attributes, :patient_attributes
  end
end
