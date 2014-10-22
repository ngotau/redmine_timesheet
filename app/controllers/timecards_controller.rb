class TimecardsController < ApplicationController
  unloadable
  include TimecardsHelper
  
  skip_before_filter :check_if_login_required, :only => [:result]
  
  before_filter :find_person, :only => [:index,:show]
 
  #show controller
  def show
    require_login || return
    prepare_values
    #user_group = find_user_groups;
    #if (User.current.admin? || user_group.include?(l(:ts_label_director)) || user_group.include?(l(:ts_label_manager)) || user_group.include?(l(:ts_label_team_leader)))
    
    @people = find_people(false)
    @team_works = []
    @total_days = 0
    @total_hours = 0
    @total_result = 0
    @people.each do |member|
      ts = Timecards.select("COUNT(work_date) as wdays, SUM(work_hours) as whours, SUM(work_result) as wresult ").
           where("work_hours IS NOT NULL AND year(work_date)=#{@this_year} AND month(work_date)=#{@this_month}").
           group(:users_id).having("users_id = #{member.id}").first
      
      if (ts == nil) 
        m = Hash["name" => member.name, "workdays" => 0, "workhours" => 0.0, "workresult" => 0]
      else
        @total_days +=  ts.wdays
        @total_hours += ts.whours.round(1)
        @total_result += ts.wresult
        m = Hash["name" => member.name, "workdays" => ts.wdays, "workhours" => ts.whours.round(1), "workresult" => ts.wresult]
      end
      @team_works << m
    end
  end
  
  #index controller
  def index
    require_login || return
    prepare_values
    make_data
    
    @people = find_people
    
  end
  
  #update work_result
  def result
    today_str = Date.today.strftime("%Y/%m/%d")
    @people = find_people(false)
    @people.each do |member|
      update_work_result(today_str,member.id)
    end
    render(:layout=>false)
  end
  
  #make data for views
  def make_data
    @holidays = ['2014/09/02','2015/01/01']
    @wday_name = l(:ts_week_day_names).split(',')
    @month_names = l(:ts_month_names).split(',')
    @break_time_names = l(:ts_break_time_names).split(',')
    @break_time_values = l(:ts_break_time_values).split(',')
    #month data
    @month_sheet = []
    @total_hours = 0;
    @total_result = 0;
    (@first_date..@last_date).each do |date|
      date_str = date.strftime("%Y/%m/%d")
      date_id = date.strftime("%Y%m%d")
      date_sheet = Timecards.where(["work_date = ? AND users_id = ?", date_str, @this_uid]).first
      if (date_sheet == nil) 
        date_sheet = Timecards.new
        date_sheet.work_date = date
      end
      date_sheet.is_holiday = false
      if @holidays.include?(date_str)
        date_sheet.is_holiday = true
      end
      format_time_card(date_sheet)
      @month_sheet << date_sheet
      if (date_sheet.work_hours != nil)
        @total_hours = @total_hours + date_sheet.work_hours
      end
      if (date_sheet.work_result != nil)
        @total_result = @total_result + date_sheet.work_result
      end
    end
  end  
  #ajax method for auto insert work on
  def autocomplete_work_on
    prepare_values
    @check_in_time = params[:it]
    
    #set current time if nil
    if (@check_in_time == "")
       @check_in_time = @current_time 
    end
    #check if time is edit
    @edit_authorize = 0 if (@this_work.work_in !=nil) 
    if (@manager_mode == 1 || @edit_authorize == 1)
      #validate before save
      validate_date(@this_date_str)
      validate_work_in(@check_in_time)
      if (@error_message == nil)
        @old_hours = (@this_work.work_hours==nil) ? "" : @this_work.work_hours
        check_in(@check_in_time)
      end
    else
      @error_message = l(:ts_error_not_authorize) 
    end
    render(:layout=>false)
  end
  #ajax method for auto insert work off
  def autocomplete_work_off
    prepare_values
    @check_out_time = params[:ot]
    if (@check_out_time =="")
       @check_out_time = @current_time 
    end
    #check if time is edit
    @edit_authorize = 0 if (@this_work.work_out !=nil) 
    if (@manager_mode == 1 || @edit_authorize == 1)
      #validate before save
      validate_date(@this_date_str)
      validate_work_out(@this_work.work_in_time,@check_out_time)
      if (@error_message == nil)
       @old_hours = (@this_work.work_hours==nil) ? "" : @this_work.work_hours
        check_out(@check_out_time)
      end
    else
       @error_message = l(:ts_error_not_authorize) 
    end
    render(:layout=>false)
  end
  #ajax method for auto update work break
  def autocomplete_work_break
    prepare_values
    @break_time = params[:bt]
    #validate before save
    validate_date(@this_date_str)
    
    if (@error_message == nil)
      @old_hours = (@this_work.work_hours==nil) ? "" : @this_work.work_hours
      break_time(@break_time)
    end
    render(:layout=>false)
  end

#method for user find
  def find_person
    if (params[:u] == nil || params[:u] == '')
      require_login || return
      @person = User.current
    else
      @person = Person.find(params[:u])
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

#method for manager
  #find user groups name 
  def find_user_groups
    user_group = Group.where("id IN (SELECT gu.group_id FROM groups_users gu WHERE gu.user_id = ?)", User.current.id).all
    group_names = []
    user_group.each do |group|
      group_names << group.lastname
    end
    return group_names
  end
  
  def find_people(pages=true)
    #ecept customer
    allow_group = Group.named(l(:ts_label_allow_group)).first
    
    @status = params[:status] || 1
    scope = Person.logged.status(@status)
    scope = scope.staff
    scope = scope.seach_by_name(params[:name]) if params[:name].present?
    if (allow_group != nil)
      scope = scope.in_group(allow_group.id) 
    end
    scope = scope.in_department(params[:department_id]) if params[:department_id].present?
    scope = scope.where(:type => 'User')

    @people_count = scope.count
    @group = Group.find(params[:group_id]) if params[:group_id].present?
    @department = Department.find(params[:department_id]) if params[:department_id].present?
    if pages
      @limit =  per_page_option
      @people_pages = Paginator.new(self, @people_count,  @limit, params[:page])
      @offset = @people_pages.current.offset

      scope = scope.scoped :limit  => @limit, :offset => @offset
      @people = scope

      fake_name = @people.first.name if @people.length > 0 #without this patch paging does not work
    end

    scope
  end
    
private
  def prepare_values
    @error_message = nil
    @today = Date.today
    @today_str = @today.strftime("%Y/%m/%d")
    @current_time =DateTime.now.strftime("%H:%M")
    @this_year = params.key?(:y) ? params[:y].to_i : @today.year
    @this_month = params.key?(:m) ? params[:m].to_i : @today.month
    @this_day = params.key?(:d) ? params[:d].to_i : @today.day
    #check date parameter
    if Date.valid_date?(@this_year, @this_month, @this_day)
      @this_date = Date.new(@this_year, @this_month, @this_day)
    else
      @this_date = @today
      @this_year = @today.year
      @this_month = @today.month
      @this_day = @today.day
      @error_message = l(:ts_error_date_param)
    end
    @last_month = @today << 1
    @this_month_str = sprintf("%04d/%02d", @this_year, @this_month)
    @first_date = Date.new(@this_year, @this_month, 1)
    @last_date = (@first_date >> 1) - 1
  
    @this_uid = params.key?(:u) ? params[:u].to_i : User.current.id
    @this_date_str = @this_date.strftime("%Y/%m/%d")
    @this_date_id = @this_date.strftime("%Y%m%d")
    @this_work = Timecards.where(["work_date = ? AND users_id = ?", @this_date_str, @this_uid]).first
    if (@this_work == nil)
      @this_work = Timecards.new
      @this_work.users_id = @this_uid
      @this_work.work_date = @this_date_str
    end
    @edit_authorize = (User.current.id == @this_uid) ? 1: 0
    @manager_mode = 0
    if User.current.allowed_people_to?(:edit_timesheet, @person)
      @manager_mode = 1
    end
    format_time_card(@this_work)
  end
  
  #check in time 
  def check_in(time)
    if (@this_work == nil)
      return false
    else
      @this_work.work_in = time
    end
    @this_work.work_status = 1
    calculate_hours(@this_work)
    return @this_work.save
  end
  
  #check out time
  def check_out(time)
    if (@this_work == nil)
      return false
    else
      @this_work.work_out = time
    end
    calculate_hours(@this_work)
    @this_work.work_result = get_work_result(@this_work.work_date,@this_work.users_id)
    return @this_work.save
  end
  #break time
  def break_time(time)
    if (@this_work == nil)
      return false
    else
      @this_work.work_break = time
    end
    calculate_hours(@this_work)
    return @this_work.save
  end 
  #validation
  def validate_work_in(in_time)
    return if in_time.blank?
    unless in_time =~ /^([0-1][0-9]|[2][0-3]):[0-5][0-9]$/
      @error_message =l(:ts_error_time)
      return
    end
    now_time_str = DateTime.now.strftime("%Y/%m/%d %H:%M")
    this_time_str = @this_date_str << " " << in_time
    unless this_time_str <= now_time_str
      @error_message =l(:ts_error_time_too_big)
      return
    end
  end
  
  #validate work_out time
  def validate_work_out(in_time,out_time)
    return if out_time.blank?
    unless out_time =~ /^([0-1][0-9]|[2][0-3]):[0-5][0-9]$/
      @error_message =l(:ts_error_time)
      return
    end
    now_time_str = DateTime.now.strftime("%Y/%m/%d %H:%M")
    this_time_str = @this_date_str << " " << out_time
    unless this_time_str <= now_time_str
      @error_message =l(:ts_error_time_too_big)
      return
    end
    unless out_time > in_time
      @error_message = l(:ts_error_work_out_time)
      return
    end
  end
  
  #validate work date
  def validate_date (work_date)
    return if work_date.blank?
    date_arr = work_date.split('/')
    if Date.valid_date?(date_arr[0].to_i, date_arr[1].to_i, date_arr[2].to_i)
      #nothing
    else
      @error_message =  l(:ts_error_date)
    end
  end
  
  private
  def authorize_people
    allowed = case params[:action].to_s
      when "index", "show"
        User.current.allowed_people_to?(:edit_timesheet, @person)
      else
        false
      end

    if allowed
      true
    else
      deny_access
    end
  end
end
