Rails.application.routes.draw do
  get   "profiles"      => "profiles#index"
  get   "profiles/:id"  => "profiles#show"
  post  "profiles"      => "profiles#create"
  put   "profiles/:id"  => "profiles#update"
  get   "patients"      => "patients#index"
  get   "patients/:id"  => "patients#show"
end
