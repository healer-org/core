# frozen_string_literal: true

class Attachment < ActiveRecord::Base
  has_attached_file :document
  validates_attachment_content_type :document, content_type: %r{\Aimage\/.*\Z}

  belongs_to :record, polymorphic: true
  validates :record, presence: true
end
