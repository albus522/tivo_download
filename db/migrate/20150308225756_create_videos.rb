class CreateVideos < ActiveRecord::Migration
  def change
    create_table :videos do |t|
      t.integer :tivo_id
      t.datetime :captured_at
      t.string :title
      t.string :episode
      t.boolean :downloaded
      t.boolean :queued
      t.text :data

      t.timestamps
    end
  end
end
