class CreatePatient < ActiveRecord::Migration
  def change
    create_table :patients, id: false do |t|
      t.integer :profile_id
      t.string  :gender, limit: 10
      t.date    :death
    end
    add_index :patients, :profile_id, name: "index_patients_profile", unique: true
  end
end