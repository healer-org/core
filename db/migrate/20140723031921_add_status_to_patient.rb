class AddStatusToPatient < ActiveRecord::Migration[4.2]
  def change
    add_column :patients, :status, :string, default: "active"
    add_index :patients, :status
  end
end
