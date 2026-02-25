Rails.application.routes.draw do
  resources :fields, only: [ :index, :show ], param: :slug, path: "filieres"
  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations",
    passwords: "users/passwords"
  }, path: "", path_names: {
    sign_in: "login",
    sign_out: "logout",
    sign_up: "register"
  }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"
  get "cle", to: "home#cle"

  require "sidekiq/web"
  authenticate :user, ->(u) { u.admin? } do
    mount Sidekiq::Web => "/sidekiq"
  end

  resource :profile, only: [ :show, :edit, :update ]

  namespace :api do
    namespace :v1 do
      get "/profile", to: "profiles#show"
    end
  end

  # Diagnostics
  resources :diagnostics, only: [:new, :create, :show] do
    member do
      get  :questionnaire
      post :submit_bloc
      get  :results
      get  :pdf_status
      get  :download_pdf
    end
  end

  # Pawapay waiting screen polling
  resources :payments, only: [] do
    member do
      get :status
    end
  end

  # Mobile operator list (Stimulus fetch)
  resources :mobile_operators, only: [:index]

  # Webhooks — CSRF exempt, handled in controller
  post "/webhooks/stripe",  to: "webhooks/stripe#receive"
  post "/webhooks/pawapay", to: "webhooks/pawapay#receive"

  namespace :admin do
    root to: "dashboard#index"
    resources :users, only: [ :index ]
    resources :careers
    resources :user_skills, only: [ :create, :destroy ]
    resources :skills

    resources :diagnostics,      only: [:index, :show]
    resources :profiles
    resources :trajectories
    resources :questions
    resources :mobile_operators

    resources :fields, path: "fields" do
      resources :roadmaps do
        resources :roadmap_steps
      end
    end
  end
end
