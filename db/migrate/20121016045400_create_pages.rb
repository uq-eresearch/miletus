class CreatePages < ActiveRecord::Migration
  def change
    create_table :pages do |t|
      t.string :name
      t.text :content
      t.datetime :created_at
      t.datetime :updated_at

      t.timestamps
    end
  end
end
