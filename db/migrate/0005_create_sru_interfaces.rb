class CreateSruInterfaces < ActiveRecord::Migration

  def self.up
    create_table :sru_interfaces do |t|
      t.string :endpoint, :null => false
    end

  end

  def self.down
    drop_table :sru_interfaces
  end

end