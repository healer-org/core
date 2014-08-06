class CreateAppointments < ActiveRecord::Migration
  def change
    create_table :appointments do |t|
      t.integer :patient_id
      t.integer :trip_id
      t.date    :start_date
      t.time    :start_time
      t.integer :start_ordinal
      t.date    :end_date
      t.time    :end_time
      t.string  :location
    end
  end
end