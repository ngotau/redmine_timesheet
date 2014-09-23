Redmine::Plugin.register :redmine_timesheet do
  name 'Redmine Timesheet plugin'
  author 'GMO RUNSYSTEM'
  description 'Management Timesheet of staff'
  version '0.0.1'
  url 'http://redmine.vn/plugin'
  author_url 'http://redmine.vn/'
  
  
  #settings :default => {
  #  :users_acl => {},
  #  :visibility => ''
  #}
  
  menu :top_menu, :timesheet, {:controller => 'timecards', :action => 'index', :project_id => nil}, :caption => :label_timesheet
  #menu :admin_menu, :timesheet, {:controller => 'timesheet_settings', :action => 'index'}, :caption => :label_timesheet
end
