class IntegrateAppointmentStartAndEndTimes < ActiveRecord::Migration
  def change
    change_column :appointments, :start_time, :datetime
    change_column :appointments, :end_time, :datetime
    remove_column :appointments, :start_date
    remove_column :appointments, :end_date
    add_index :appointments, :patient_id
    add_index :appointments, [:trip_id, :start_time, :location]
  end
end