class CreateProcedures < ActiveRecord::Migration
  def change
    create_table :procedures do |t|
      t.integer :case_id, null: false
      t.integer :appointment_id
      t.jsonb :data
    end
  end
end
