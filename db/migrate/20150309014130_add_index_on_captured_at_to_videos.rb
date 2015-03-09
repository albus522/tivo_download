class AddIndexOnCapturedAtToVideos < ActiveRecord::Migration
  def change
    add_index :videos, :captured_at
  end
end
