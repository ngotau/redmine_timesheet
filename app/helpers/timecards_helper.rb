module TimecardsHelper
  #convert full time format to HH:MM format
  def format_time(time)
      if (time != nil) 
        return time.strftime("%H:%M")
      else
        return ""
      end
  end
  
  #convert object
  def format_time_card(time_card)
    if (time_card == nil)
      return
    end
    time_card.work_in_time = format_time(time_card.work_in)
    time_card.work_out_time = format_time(time_card.work_out)
  end
  
  #calculate hours
  def calculate_hours(time_card)
    if (time_card == nil)
      return
    end
    if (time_card.work_in == nil || time_card.work_out == nil)
      return
    end
    #lunch time
    lunch_start = Time.parse(time_card.work_in.strftime("%Y-%m-%d") << " 12:00:00")
    lunch_end = Time.parse(time_card.work_in.strftime("%Y-%m-%d") << " 13:30:00")
    lunch_time = 0
    if time_card.work_in < lunch_start
      if time_card.work_out > lunch_end
        lunch_time = lunch_end - lunch_start
      else
        if time_card.work_out > lunch_start
          lunch_time = time_card.work_out - lunch_start
        end
      end
    else
      if (time_card.work_in < lunch_end && time_card.work_out > lunch_end)
        lunch_time = lunch_end - time_card.work_in
      end
    end
    #second to hour
    time_card.work_lunch = (lunch_time/3600).round(2)
    #break time in second
    if (time_card.work_break == nil)
      work_break_time = 0
    else
      work_break_time = time_card.work_break * 3600
    end
    #total work time in second
    work_total_time = time_card.work_out - time_card.work_in
    work_time = work_total_time - lunch_time - work_break_time
    time_card.work_hours = (work_time/3600).round(2)
  end
  
  #Get closed issue on that day and update pages to work_result
  def get_work_result(work_date,uid)
    issues = Issue.find(:all,
                      :joins => "INNER JOIN trackers  ON trackers.id = issues.tracker_id " + 
                                "INNER JOIN issue_statuses ON issue_statuses.id = issues.status_id ",
                      :conditions => ["issues.assigned_to_id=:u 
                                       AND trackers.name = 'Task'
                                       AND issue_statuses.is_closed = 1
                                       AND issues.done_ratio = 100
                                       AND DATE( closed_on)=:d",
                                       {:u=>uid, :d=>work_date}])
    work_result = 0
    issues.each do |issue|
      result = CustomValue.find(:first,
                               :joins => "INNER JOIN custom_fields ON custom_fields.id = custom_values.custom_field_id ",
                                :conditions => ["custom_values.customized_id=:t
                                       AND custom_fields.name = 'Pages'",
                                       {:t=>issue.id}])
      #get value of pages
      if result != nil 
        work_result = work_result + result.value.to_i
      end
    end
    return work_result
  end
  
  def update_work_result(work_date,uid) 
    work_result = get_work_result(work_date,uid)
    #update work_result
    tc = Timecards.where(["work_date = ? AND users_id = ?", work_date, uid]).first
    if (tc != nil)
      tc.work_result = work_result
      tc.save
    end
    
  end
  
end
