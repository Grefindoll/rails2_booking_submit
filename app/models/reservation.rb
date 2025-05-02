class Reservation < ApplicationRecord
  belongs_to :user
  belongs_to :room

  validates :check_in, presence: true
  validates :check_out, presence: true
  validates :number_of_guests, presence: true, numericality: { greater_than: 0 }

  # エラーが存在する場合、レコードの保存を阻止します。
  validate :check_in_is_today_or_after
  validate :check_out_is_after_check_in

  # 支払い合計金額を計算するメソッド
  before_save :calculate_total_price

  private

  def check_in_is_today_or_after
    if check_in.present? && check_in < Date.today
      errors.add(:check_in, "は本日以降の日付でなければなりません")
    end
  end

  def check_out_is_after_check_in
    if check_out.present? && check_out <= check_in
      errors.add(:check_out, "はチェックイン日より後の日付でなければなりません")
    end
  end

  def calculate_total_price
    nights = (check_out.to_date - check_in.to_date).to_i
    self.total_price = nights * number_of_guests * room.price_per_night
  end
end
