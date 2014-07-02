class CreateProfile < ActiveRecord::Migration
  def change
    create_table :profiles do |t|
      t.string :name
      t.date :birth
    end
  end
end