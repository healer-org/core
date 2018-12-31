class CreatePatient < ActiveRecord::Migration[4.2]
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
