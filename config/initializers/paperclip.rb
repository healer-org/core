if Rails.env.test?
  Paperclip::Attachment.default_options.merge!({
    :url => "/system/:rails_env/:class/:attachment/:id_partition/:style/:filename",
    :path => ":rails_root/tmp:url"
  })
end