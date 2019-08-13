class CreateTasks < ActiveRecord::Migration[5.2]
  def change
    create_table :tasks do |t|
      t.integer :state, default: 0, null: false
      t.string :name, null: false

      t.timestamps
    end
  end
end
