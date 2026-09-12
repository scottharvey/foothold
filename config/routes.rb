Foothold::Engine.routes.draw do
  root to: "home#index"
  resources :terms, only: %i[show create update destroy]
  resource :sweep, only: :create
  resources :rivals, only: %i[create destroy]
  resource :digest, only: :create
  resources :pages, only: :show
  resources :mentions, only: :index
  resources :leads, only: [] do
    member do
      post :done
      post :dismiss
      post :track
    end
  end
end
