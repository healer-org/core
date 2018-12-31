class CreateProcedures < ActiveRecord::Migration[4.2]
  def change
    create_table :procedures do |t|
      t.integer :case_id, null: false
      t.integer :appointment_id
      t.jsonb :data
    end
  end
end
