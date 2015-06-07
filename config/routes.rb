Rails.application.routes.draw do
  namespace :v1 do
    get     "appointments"     => "appointments#index"
    get     "appointments/:id" => "appointments#show"
    post    "appointments"     => "appointments#create"
    put     "appointments/:id" => "appointments#update"
    delete  "appointments/:id" => "appointments#delete"

    post    "attachments" => "attachments#create"

    get     "cases"     => "cases#index"
    get     "cases/:id" => "cases#show"
    post    "cases"     => "cases#create"
    put     "cases/:id" => "cases#update"
    delete  "cases/:id" => "cases#delete"

    get     "patients/search" => "patients#search"
    get     "patients"        => "patients#index"
    get     "patients/:id"    => "patients#show"
    post    "patients"        => "patients#create"
    put     "patients/:id"    => "patients#update"
    delete  "patients/:id"    => "patients#delete"
  end
end
