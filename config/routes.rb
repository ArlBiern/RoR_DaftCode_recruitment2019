Rails.application.routes.draw do
  resources :products, only: %i[index]
  resource :cart, only: %i[show] do
    scope module: :carts do
      resource :total, only: %i[show]
      resources :items, only: %i[create update]
      resources :discounts, only: %i[create update]
    end
  end
end
