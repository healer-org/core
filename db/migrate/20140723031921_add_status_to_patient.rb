class AddStatusToPatient < ActiveRecord::Migration
  def change
    add_column :patients, :status, :string, default: "active"
    add_index :patients, :status
  end
end
