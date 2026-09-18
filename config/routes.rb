Foothold::Engine.routes.draw do
  root to: "home#index"
  resources :terms, only: %i[index show create update destroy]
  resources :sweeps, only: %i[index create]
  resources :rivals, only: %i[index create destroy]
  resources :mutes, only: %i[index create destroy]
  resource :digest, only: :create
  resources :pages, only: :show
  resources :mentions, only: :index
  resources :leads, only: [ :show ] do
    member do
      post :act
      post :done
      post :dismiss
      post :snooze
      post :mute
    end
    collection do
      post :bulk_done
      post :bulk_dismiss
    end
  end
end
