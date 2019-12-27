class CreateProvidersTeams < ActiveRecord::Migration[5.2]
  def change
    create_table :providers_teams do |t|
      t.integer :provider_id, null: false, index: true
      t.integer :team_id, null: false, index: true
    end
  end
end
