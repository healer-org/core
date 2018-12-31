class CreateAppointments < ActiveRecord::Migration[4.2]
  def change
    create_table :appointments do |t|
      t.integer  :patient_id
      t.integer  :trip_id
      t.integer  :order
      t.date     :date
      t.datetime :start
      t.datetime :end
      t.string   :location
    end

    add_index :appointments, :patient_id
    add_index :appointments, [:trip_id, :start, :location]
  end
end
