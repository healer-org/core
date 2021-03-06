class AddTimestampsToPatientsAndCases < ActiveRecord::Migration[4.2]
  def change
    add_column :patients, :created_at, :datetime
    add_column :patients, :updated_at, :datetime
    add_column :cases, :created_at, :datetime
    add_column :cases, :updated_at, :datetime
  end
end
