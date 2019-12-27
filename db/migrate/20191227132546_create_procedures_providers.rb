class CreateProceduresProviders < ActiveRecord::Migration[5.2]
  def change
    create_table :procedures_providers do |t|
      t.integer :procedure_id, null: false, index: true
      t.integer :provider_id, null: false, index: true
    end
  end
end
