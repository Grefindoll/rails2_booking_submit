# spec/factories/reservations.rb
FactoryBot.define do
  factory :reservation do
    check_in { Date.tomorrow }
    check_out { Date.tomorrow + 2.days }
    number_of_guests { 2 }
    association :user
    association :room
  end
end
