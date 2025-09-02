require 'rails_helper'

RSpec.describe Reservation, type: :model do
  let(:user) { create(:user) }
  let(:room) { create(:room, user: user) } # Reservationの作成にはroomが必要

  describe 'バリデーション' do
    let(:reservation) do
      build(:reservation, user: user, room: room, check_in: Date.today + 1.day, check_out: Date.today + 3.days, number_of_guests: 2)
    end

    it 'ユーザー、ルーム、チェックイン日、チェックアウト日、宿泊人数があれば有効であること' do
      expect(reservation).to be_valid
    end

    it 'ユーザーがなければ無効であること' do
      reservation.user = nil
      expect(reservation).not_to be_valid
      expect(reservation.errors[:user]).to include("を入力してください") # もしくは "must exist"
    end

    it 'ルームがなければ無効であること' do
      reservation.room = nil
      expect(reservation).not_to be_valid
      expect(reservation.errors[:room]).to include("を入力してください") # もしくは "must exist"
    end

    it 'チェックイン日がなければ無効であること' do
      reservation.check_in = nil
      expect(reservation).not_to be_valid
      expect(reservation.errors[:check_in]).to include("を入力してください")
    end

    it 'チェックアウト日がなければ無効であること' do
      reservation.check_out = nil
      expect(reservation).not_to be_valid
      expect(reservation.errors[:check_out]).to include("を入力してください")
    end

    it '宿泊人数がなければ無効であること' do
      reservation.number_of_guests = nil
      expect(reservation).not_to be_valid
      expect(reservation.errors[:number_of_guests]).to include("を入力してください")
    end

    it '宿泊人数が0以下であれば無効であること' do
      reservation.number_of_guests = 0
      expect(reservation).not_to be_valid
      expect(reservation.errors[:number_of_guests]).to include("は0より大きい値にしてください")

      reservation.number_of_guests = -1
      expect(reservation).not_to be_valid
      expect(reservation.errors[:number_of_guests]).to include("は0より大きい値にしてください")
    end

    it '宿泊人数が数値でなければ無効であること' do
      reservation.number_of_guests = "abc"
      expect(reservation).not_to be_valid
      expect(reservation.errors[:number_of_guests]).to include("は数値で入力してください") # または "is not a number"
    end

    describe 'カスタムバリデーション' do
      context 'チェックイン日について' do
        it 'チェックイン日が本日より前なら無効であること' do
          reservation.check_in = Date.yesterday
          expect(reservation).not_to be_valid
          expect(reservation.errors[:check_in]).to include("は本日以降の日付でなければなりません")
        end

        it 'チェックイン日が本日なら有効であること' do
          reservation.check_in = Date.today
          reservation.check_out = Date.tomorrow # チェックアウト日も調整
          expect(reservation).to be_valid
        end

        it 'チェックイン日が本日以降なら有効であること' do
          reservation.check_in = Date.tomorrow
          reservation.check_out = Date.tomorrow + 2.days # チェックアウト日も調整
          expect(reservation).to be_valid
        end
      end

      context 'チェックアウト日について' do
        it 'チェックアウト日がチェックイン日以前なら無効であること' do
          reservation.check_out = reservation.check_in
          expect(reservation).not_to be_valid
          expect(reservation.errors[:check_out]).to include("はチェックイン日より後の日付でなければなりません")

          reservation.check_out = reservation.check_in - 1.day
          expect(reservation).not_to be_valid
          expect(reservation.errors[:check_out]).to include("はチェックイン日より後の日付でなければなりません")
        end

        it 'チェックアウト日がチェックイン日より後なら有効であること' do
          reservation.check_out = reservation.check_in + 1.day
          expect(reservation).to be_valid
        end
      end
    end
  end

  describe 'アソシエーション' do
    let(:reservation) { create(:reservation, user: user, room: room) }

    context 'User モデルとの関連' do
      it 'User に属すること (belongs_to)' do
        expect(reservation.user).to eq user
      end
    end

    context 'Room モデルとの関連' do
      it 'Room に属すること (belongs_to)' do
        expect(reservation.room).to eq room
      end
    end
  end

  describe 'コールバック' do
    describe 'before_save :calculate_total_price' do
      let(:room_for_callback) { create(:room, price_per_night: 1000) }
      let(:reservation_for_callback) do
        build(:reservation,
              room: room_for_callback,
              check_in: Date.today + 1.day,
              check_out: Date.today + 4.days, # 3泊
              number_of_guests: 2)
      end

      it '保存前に合計金額が正しく計算されること' do
        # (チェックアウト日 - チェックイン日).to_i で泊数を計算
        # ( (Date.today + 4.days) - (Date.today + 1.day) ).to_i = 3 泊
        # 3泊 * 宿泊人数2人 * 部屋の料金1000円 = 6000円
        expected_total_price = 3 * 2 * 1000
        reservation_for_callback.save
        expect(reservation_for_callback.total_price).to eq expected_total_price
      end

      it 'チェックイン日やチェックアウト日がnilの場合でもエラーにならないこと（バリデーションで弾かれる想定）' do
        reservation_for_callback.check_in = nil
        reservation_for_callback.check_out = nil
        # バリデーションで保存されないため、total_price は nil のままのはず
        expect(reservation_for_callback.save).to be_falsey # 保存に失敗することを確認
        expect(reservation_for_callback.total_price).to be_nil
      end

      it '宿泊人数がnilの場合でもエラーにならないこと（バリデーションで弾かれる想定）' do
        reservation_for_callback.number_of_guests = nil
        expect(reservation_for_callback.save).to be_falsey # 保存に失敗することを確認
        expect(reservation_for_callback.total_price).to be_nil
      end

      it '部屋の料金がnilの場合、total_priceが0として計算されること' do # テスト名と期待値を変更
        allow(reservation_for_callback.room).to receive(:price_per_night).and_return(nil)
        # save を呼ぶことで before_save コールバックが実行される
        # バリデーションが全て通れば保存される
        # ここでは calculate_total_price のロジックに注目
        reservation_for_callback.valid? # バリデーションを実行（エラーがないか確認のため）
        reservation_for_callback.save # 保存を実行し、コールバックをトリガー
        expect(reservation_for_callback.total_price).to eq(0)
      end
    end
  end
end
