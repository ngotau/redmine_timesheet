class Timecards < ActiveRecord::Base
  unloadable
  attr_accessor           :is_holiday,:work_in_time,:work_out_time
  attr_accessible         :is_holiday,:work_in_time,:work_out_time
  
end
