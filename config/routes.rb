Rails.application.routes.draw do

  resources :activity_feed, only: :index

  get 'profiles/:id' => 'profiles#show', as: 'profile'
  get 'profiles' => 'profiles#index', as: 'profiles'

  as :user do
    get "/register", to: "devise/registrations#new", as: :register
    get "/login", to: "devise/sessions#new", as: :login
    delete "/logout", to: "devise/sessions#destroy", as: :logout
  end

  devise_for :users, skip: [:sessions], controllers: { omniauth_callbacks: "callbacks", registrations: "registrations" }

  as :user do
    get "/login" => "devise/sessions#new", as: :new_user_session
    post "/login" => "devise/sessions#create", as: :user_session
    delete "/logout" => "devise/sessions#destroy", as: :destroy_user_session
  end

  resources :statuses do
    member do
      put "upvote", to: "statuses#upvote"
      put "downvote", to: "statuses#downvote"
    end
    resources :comments, only: [:create, :destroy]
  end

  resources :friendships do
    member do
      put :accept
      put :block
    end
  end

  root 'statuses#index'
end
