class CreateAttachments < ActiveRecord::Migration
  def change
    create_table :attachments do |t|
      t.integer     :record_id
      t.string      :record_type
      t.text        :description
      t.attachment  :document
      t.timestamps  null: false
    end
    add_index :attachments, :record_id
    add_index :attachments, [:record_type, :record_id]
  end
end
