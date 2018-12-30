class CreateMissions < ActiveRecord::Migration[4.2]
  def change
    create_table :missions do |t|
      t.string :name, null: false
      t.string :country, limit: 2
      t.string :location
      t.string :facility
      t.date   :begin_date, index: true
      t.date   :end_date
    end

    create_table :missions_teams do |t|
      t.integer :mission_id, null: false
      t.integer :team_id, null: false, index: true
    end
  end
end
