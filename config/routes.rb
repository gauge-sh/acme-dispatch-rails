Rails.application.routes.draw do
  devise_for :users

  root "dashboard#show"

  resources :customers
  resources :technicians do
    member do
      get :schedule
    end
  end
  resources :parts do
    member do
      post :adjust_stock
    end
  end
  resources :jobs do
    member do
      post :transition
      post :invoice
    end
    resources :appointments, only: %i[new create edit update destroy], shallow: true
    resources :job_parts, only: %i[create destroy], shallow: true
  end
  get "schedule" => "appointments#index", as: :schedule
  resources :invoice_records, only: %i[index show]
  resources :users do
    resources :api_tokens, only: %i[create destroy], shallow: true
  end

  # /api is mounted by Api::Engine (packs/api).

  get "up" => "rails/health#show", as: :rails_health_check
end
