# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    sequence(:email) { |n| "test_user_#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
  end
end
