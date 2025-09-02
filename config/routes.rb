Rails.application.routes.draw do
  # ユーザー認証ルート
  devise_for :users
  
  # トップページ関連
  get 'top/index'
  # get "search" => "searches#search"

  root to: 'top#index'

  # ユーザーのプロフィール管理
  resources :users, only: [:show, :edit, :update]

  # 部屋と予約のルーティング（ネストされた予約リソース）
  resources :rooms, only: [:index, :show, :new, :create] do
    resources :reservations, only: [:new, :create]
    collection do
      get 'search'
    end
  end

  # 予約の個別アクション（確認ページ）
  resources :reservations, only: [] do
    member do
      get 'confirmation'
    end
  end

  # ユーザー専用ページ（予約一覧や部屋一覧）
  get 'my_reservations', to: 'reservations#my_reservations', as: 'my_reservations'
  get 'my_rooms', to: 'rooms#my_rooms', as: 'my_rooms'
end
