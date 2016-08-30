class AddLocaitonAndLocationAdminToUsers < ActiveRecord::Migration
  def change
    add_column :users, :location_id, :integer
    add_column :users, :location_admin, :boolean, :default => false
  end
end
