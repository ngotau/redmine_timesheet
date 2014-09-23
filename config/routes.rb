# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

RedmineApp::Application.routes.draw do
  resources :timecards do
    collection do
      post :index
      post :autocomplete_work_on
      post :autocomplete_work_off
      post :autocomplete_work_break
    end
  end
end