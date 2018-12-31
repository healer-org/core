# frozen_string_literal: true

module V1
  class PatientPresenter < BasePresenter
    SIMPLE_ATTRIBUTES = %i[id name gender birth death].freeze

    def initialize(attributes)
      @attributes = HashWithIndifferentAccess.new(attributes)
    end

    def present
      {}.tap do |presented|
        SIMPLE_ATTRIBUTES.each do |k|
          presented[k] = attributes[k.to_s]
        end
        if attributes[:cases]
          presented[:cases] =
            attributes[:cases].map do |c|
              {
                id: c[:id],
                anatomy: c[:anatomy],
                side: c[:side]
              }
            end
        end
      end
    end

    private

    attr_reader :attributes
  end
end
