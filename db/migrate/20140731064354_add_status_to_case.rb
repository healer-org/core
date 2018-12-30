class AddStatusToCase < ActiveRecord::Migration[4.2]
  def change
    add_column :cases, :status, :string, default: "active"
    add_index :cases, :status
  end
end
