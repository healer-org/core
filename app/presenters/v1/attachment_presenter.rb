module V1
  class AttachmentPresenter < BasePresenter
    SIMPLE_ATTRIBUTES = %i(
      id
      description
      documentContentType
      documentFileName
      documentFileSize
      createdAt
    )

    def initialize(attributes)
      @attributes = HashWithIndifferentAccess.new(attributes)
    end

    def present
      {}.tap do |presented|
        SIMPLE_ATTRIBUTES.each do |k|
          presented[k] = attributes[k.to_s.underscore]
        end
      end
    end

    private

    attr_reader :attributes
  end
end
