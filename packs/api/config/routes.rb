Api::Engine.routes.draw do
  scope module: :v1, path: "v1" do
    resources :customers, only: %i[index create show update destroy]
    resources :technicians, only: %i[index create show update destroy]
    resources :parts, only: %i[index create show update destroy]
    resources :users, only: %i[index create show update destroy]

    resources :jobs, only: %i[index create show update destroy] do
      member do
        post :transition
        post "parts" => "job_parts#create"
        post "invoice" => "invoice_records#create"
      end
    end

    resources :appointments, only: %i[index create show update destroy]
    delete "job-parts/:id" => "job_parts#destroy", as: :job_part

    get "stock-levels" => "stock_levels#index", as: :stock_levels
    post "stock-levels/:part_id/adjust" => "stock_levels#adjust", as: :stock_level_adjust

    resources :invoice_records, path: "invoice-records", only: %i[index show]
  end
end
