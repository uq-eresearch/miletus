class CreateHarvestDocument < ActiveRecord::Migration
  def change
    create_table :harvest_documents do |t|
      t.string :type, :null => false
      t.string :url,  :null => false
      # HTTP metadata
      t.string :etag
      t.string :last_modified
      # Paperclip columns
      t.attachment :document
      # Audit
      t.timestamps
    end
  end
end
