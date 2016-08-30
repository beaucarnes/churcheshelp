class CreateMinistries < ActiveRecord::Migration
  def change
    create_table :ministries do |t|
      t.string :title
      t.text :details
      t.text :when
      t.boolean :current_state
      t.boolean :spam, default: false
      t.boolean :email_on_approval, default: true
      t.references :location, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
