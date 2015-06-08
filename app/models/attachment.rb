class Attachment < ActiveRecord::Base
  has_attached_file :document#, :styles => { :medium => "300x300>", :thumb => "100x100>" }, :default_url => "/images/:style/missing.png"
  validates_attachment_content_type :document, content_type: /\Aimage\/.*\Z/

  belongs_to :record, polymorphic: true
  validates :record, presence: true
end
