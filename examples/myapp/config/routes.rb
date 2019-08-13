Rails.application.routes.draw do
  root to: 'tasks#index'

  resources :tasks
  post 'task/import', to: 'import_tasks#create'
end
