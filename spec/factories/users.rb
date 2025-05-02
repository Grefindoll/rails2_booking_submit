# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    # Faker を使って名前を生成
    name { Faker::Name.name }

    # sequence を使って一意なメールアドレスを生成
    sequence(:email) { |n| "test_user_#{n}@example.com" }

    # 固定のパスワードを設定 (テストで扱いやすいように)
    # User モデル側で has_secure_password を使っていることを想定
    password { "password123" }
    password_confirmation { "password123" }
  end
end