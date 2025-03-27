class Room < ApplicationRecord
  validates :name, presence: true
  validates :description, presence: true
  validates :price_per_night, presence: true, numericality: { greater_than_or_equal_to: 1 }
  validates :address, presence: true


  has_one_attached :room_image
  belongs_to :user
  has_many :reservations, dependent: :destroy 
end
