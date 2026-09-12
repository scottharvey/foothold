Foothold::Engine.routes.draw do
  root to: "home#index"
  resources :terms, only: %i[show create update destroy]
  resource :sweep, only: :create
end
