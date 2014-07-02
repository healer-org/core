Rails.application.routes.draw do
  get "profiles" => "profiles#index"
  get "profiles/:id" => "profiles#show"
end
