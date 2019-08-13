json.extract! task, :id, :state, :name, :created_at, :updated_at
json.url task_url(task, format: :json)
