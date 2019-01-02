# frozen_string_literal: true

Rails.application.routes.draw do
  scope module: :v1, constraints: ApiVersion.new("v1", true) do
    resources :patients, only: [:index, :create, :show, :destroy, :update] do
      collection do
        get :search
      end
    end
    resources :cases, only: [:index, :create, :show, :destroy, :update]
    resources :appointments, only: [:index, :create, :show, :destroy, :update]
    resources :attachments, only: [:create]
    resources :missions, only: [:create, :show]
    resources :teams, only: [:show, :create]
    resources :missions, only: [:create, :show]
    resources :procedures, only: [:create]
  end

  # handle routing errors differently
  match "*path", to: "application#routing_error", via: :all
end
