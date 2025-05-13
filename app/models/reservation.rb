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
    if check_in.present? && check_in.to_date < Date.today
      errors.add(:check_in, "は本日以降の日付でなければなりません")
    end
  end

  def check_out_is_after_check_in
    if check_in.present? && check_out.present? && check_out <= check_in
      errors.add(:check_out, "はチェックイン日より後の日付でなければなりません")
    end
  end

  def calculate_total_price
    # check_in, check_out, number_of_guests, room が存在することをまず確認
    return unless check_in.present? && check_out.present? && number_of_guests.present? && room.present?

    nights = (check_out.to_date - check_in.to_date).to_i
    # 泊数が負や0の場合の考慮（バリデーションで防がれる想定だが、コールバックでも安全に）
    nights = 0 if nights < 0 # 例: 0泊なら合計金額も0

    # room.price_per_night が nil の場合でも .to_i で 0 になる
    self.total_price = nights * number_of_guests * room.price_per_night.to_i
  end
end
