class AddStatusToCase < ActiveRecord::Migration
  def change
    add_column :cases, :status, :string, default: "active"
    add_index :cases, :status
  end
end
