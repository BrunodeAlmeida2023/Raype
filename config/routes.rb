require 'sidekiq/web'

Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations',
    passwords: 'users/passwords',
    confirmations: 'users/confirmations'
  }

  root "home#index"

  resource :home, only: [:show], controller: 'home' do
    get :find_outdoor
    get :find_date
    get :choose_art
    get :finalize_budget
    post :post_find_outdoor
    post :post_find_date
    post :post_choose_art
    post :post_finalize_budget
  end

  get 'checkout/new', to: 'checkout#new', as: 'new_checkout'
  post 'checkout/create_payment', to: 'checkout#create_payment', as: 'create_payment'
  get 'checkout/:rent_id', to: 'checkout#show', as: 'checkout'
  post 'checkout/:rent_id/process', to: 'checkout#process_payment', as: 'process_payment'
  get 'checkout/success/:id', to: 'checkout#success', as: 'checkout_success'
  get 'pedido/:id/status', to: 'checkout#order_status', as: 'order_status'
  delete 'pedido/:id/cancelar', to: 'checkout#cancel_order', as: 'cancel_order'
  get 'pedido/whatsapp/:id', to: 'home#redirect_whatsapp', as: :pedido_whatsapp
  post 'webhooks/asaas', to: 'webhooks#asaas'

  # Sidekiq Web UI - Requer autenticação admin
  authenticate :user, ->(user) { user.admin? } do
    mount Sidekiq::Web => '/sidekiq', as: :sidekiq
  end

  # Flipper Web UI - Requer autenticação admin
  authenticate :user, ->(user) { user.admin? } do
    mount Flipper::UI.app(Flipper) => '/flipper', as: :flipper
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest


end
