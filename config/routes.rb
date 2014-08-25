Rails.application.routes.draw do
  get     "patients"     => "patients#index"
  get     "patients/:id" => "patients#show"
  post    "patients"     => "patients#create"
  put     "patients/:id" => "patients#update"
  delete  "patients/:id" => "patients#delete"

  get     "cases"     => "cases#index"
  get     "cases/:id" => "cases#show"
  post    "cases"     => "cases#create"
  put     "cases/:id" => "cases#update"
  delete  "cases/:id" => "cases#delete"

  get     "appointments"     => "appointments#index"
  # get     "appointments/:id" => "appointments#show"
  post    "appointments"     => "appointments#create"
  put     "appointments/:id" => "appointments#update"
  delete  "appointments/:id" => "appointments#delete"
end
