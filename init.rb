require 'redmine_timesheet'

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
  
  menu :top_menu, :timesheet, "/timecards", :caption => :label_timesheet,:after =>:home
  
end
