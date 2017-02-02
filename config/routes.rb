Rails.application.routes.draw do
  resources :documents, only: [:create, :execute, :cancel] do
    member do
      put :execute
      put :cancel
    end
  end

  resources :accounts, only: [:create] do
    get 'balance'
    get 'history'
    get 'history_dates'
    put 'close'
    put 'unblock'
    post 'block'
  end

end
