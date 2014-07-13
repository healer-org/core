Rails.application.routes.draw do
  get   "patients"      => "patients#index"
  get   "patients/:id"  => "patients#show"
  post  "patients"      => "patients#create"
  put   "patients/:id"  => "patients#update"
end
