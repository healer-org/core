Rails.application.routes.draw do
  get   "profiles" => "profiles#index"
  get   "profiles/:id" => "profiles#show"
  post  "profiles" => "profiles#create"
  put   "profiles/:id" => "profiles#update"
end
