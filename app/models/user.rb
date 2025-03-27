class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
          :recoverable, :rememberable, :validatable
  
  validates :name, presence: true, length: { maximum: 50 }

  has_one_attached :profile_image
  has_many :rooms, dependent: :destroy
  has_many :reservations, dependent: :destroy
end
