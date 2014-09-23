class CreateTimecards < ActiveRecord::Migration
  def change
    create_table :timecards do |t|
      t.date :work_date
      t.time :work_in
      t.time :work_out
      t.decimal :work_lunch,:precision=>4,:scale=>2
      t.decimal :work_break,:precision=>4,:scale=>2
      t.decimal :work_hours,:precision=>4,:scale=>2
      t.integer :work_status,:default => 0
      t.integer :work_result,:default => 0
      t.references :users, :null => false 
    end
  end
end