Rails.application.routes.draw do
  get   "patients"      => "patients#index"
  get   "patients/:id"  => "patients#show"
  post  "patients"      => "patients#create"
  put   "patients/:id"  => "patients#update"

  get   "cases"         => "cases#index"
  get   "cases/:id"     => "cases#show"
  post  "cases"         => "cases#create"
  put   "cases/:id"     => "cases#update"
end
