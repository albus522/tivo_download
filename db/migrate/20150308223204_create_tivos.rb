class CreateTivos < ActiveRecord::Migration
  def change
    create_table :tivos do |t|
      t.string :name
      t.string :mac
      t.string :host
      t.string :ip
      t.boolean :online

      t.timestamps
    end
  end
end
