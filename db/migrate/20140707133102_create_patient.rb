class CreatePatient < ActiveRecord::Migration
  def change
    create_table :patients do |t|
      t.string  :name
      t.date    :birth
      t.string  :gender, limit: 10
      t.date    :death
    end
    add_index :patients, [:name, :birth]
  end
end