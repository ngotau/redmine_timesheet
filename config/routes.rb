# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

RedmineApp::Application.routes.draw do
  match 'timecards/:action/:u', :to => 'timecards#index'
  match 'timecards/:action/:y/:m/:d/:u', :to => 'timecards#index'
  match 'timecards/:action/:y/:m', :to => 'timecards#show'
  match 'timecards/result', :to => 'timecards#result', :via => :get
  
  resources :timecards do
    collection do
      post :index
      post :autocomplete_work_on
      post :autocomplete_work_off
      post :autocomplete_work_break
    end
  end
end