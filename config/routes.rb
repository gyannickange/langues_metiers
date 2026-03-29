Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: "users/sessions",
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  devise_scope :user do
    post "login/request_otp", to: "users/sessions#request_otp", as: :send_otp
    post "login/verify_otp", to: "users/sessions#verify_otp", as: :verify_otp
  end

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
  resource :onboarding, only: [ :show, :update ], controller: "onboarding"
  resources :careers, only: [ :index ]
  namespace :api do
    namespace :v1 do
      get "/profile", to: "profiles#show"
    end
  end

  # Diagnostics
  resources :diagnostics, only: [ :new, :show ] do
    member do
      get  :assessment
      post :submit_bloc
      get  :pay
      post :process_payment
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
  resources :mobile_operators, only: [ :index ]

  # Webhooks — CSRF exempt, handled in controller
  post "/webhooks/stripe",  to: "webhooks/stripe#receive"
  post "/webhooks/pawapay", to: "webhooks/pawapay#receive"

  namespace :admin do
    root to: "dashboard#index"
    resources :users, only: [ :index ]
    resources :careers
    resources :user_skills, only: [ :create, :destroy ]
    resources :skills

    resources :diagnostics,      only: [ :index, :show ]
    resources :trajectories
    resources :assessments do
      member do
        patch :activate
      end
      resources :assessment_questions do
        collection do
          patch :reorder
        end
      end
    end
    # Keep flat assessment_questions route for backward compatibility if needed, but we mostly use nested now
    resources :assessment_questions do
      collection do
        patch :reorder
      end
    end
    resources :mobile_operators
  end
end
