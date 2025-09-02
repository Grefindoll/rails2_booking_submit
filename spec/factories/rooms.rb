# spec/factories/rooms.rb
FactoryBot.define do
  factory :room do
    name { "テスト施設" }
    description { "テスト用の施設説明文です。" }
    price_per_night { 5000 }
    address { "東京都テスト区テスト1-2-3" }
    association :user
  end
end
