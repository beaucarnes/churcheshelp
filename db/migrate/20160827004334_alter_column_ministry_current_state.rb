class AlterColumnMinistryCurrentState < ActiveRecord::Migration
  def self.up
    change_table :ministries do |t|
      t.change :current_state, :integer
    end
  end
  def self.down
    change_table :ministries do |t|
      t.change :current_state, :boolean
    end
  end
end
