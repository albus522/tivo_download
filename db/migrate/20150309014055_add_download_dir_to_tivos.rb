class AddDownloadDirToTivos < ActiveRecord::Migration
  def change
    add_column :tivos, :download_dir, :string
  end
end
