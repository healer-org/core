class V1::AttachmentPresenter < V1::BasePresenter

  def initialize(attributes)
    @attributes = HashWithIndifferentAccess.new(attributes)
  end

  def present
    {}.tap do |presented|
      presented[:id] = attributes["id"]
      presented[:description] = attributes["description"]
      presented[:documentContentType] = attributes["document_content_type"]
      presented[:documentFileName] = attributes["document_file_name"]
      presented[:documentFileSize] = attributes["document_file_size"]
      presented[:createdAt] = attributes["created_at"]
    end
  end


  private

  attr_reader :attributes

end