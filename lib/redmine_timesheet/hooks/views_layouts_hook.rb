module RedmineTimesheet
  module Hooks
    class ViewsLayoutsHook < Redmine::Hook::ViewListener
      def view_layouts_base_html_head(context={})
        o = stylesheet_link_tag('time_sheet', :plugin => 'redmine_timesheet')
        o += javascript_include_tag("time_sheet", :plugin => 'redmine_timesheet')
        return o
      end
      
      def view_welcome_index_left(context={})
        context[:controller].send(:render, {:partial => 'hooks/view_welcome_index_left'})
      end
      
    end
  end
end