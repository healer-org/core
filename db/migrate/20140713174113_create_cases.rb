class CreateCases < ActiveRecord::Migration
  def change
    create_table :cases do |t|
      t.integer :patient_id
      t.string  :anatomy
      t.string  :side
    end
  end
end
