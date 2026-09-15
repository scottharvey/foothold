Foothold::Engine.routes.draw do
  root to: "home#index"
  resources :terms, only: %i[index show create update destroy]
  resources :sweeps, only: %i[index create]
  resources :rivals, only: %i[index create destroy]
  resource :digest, only: :create
  resources :pages, only: :show
  resources :mentions, only: :index
  resources :leads, only: [ :show ] do
    member do
      post :done
      post :dismiss
      post :track
      post :approve
    end
    collection do
      post :bulk_done
      post :bulk_dismiss
    end
  end
end
