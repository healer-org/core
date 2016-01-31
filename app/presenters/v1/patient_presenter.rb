module V1
  class PatientPresenter < BasePresenter
    SIMPLE_ATTRIBUTES = %i(id name gender birth death)

    def initialize(attributes)
      @attributes = HashWithIndifferentAccess.new(attributes)
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
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
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    private

    attr_reader :attributes
  end
end
