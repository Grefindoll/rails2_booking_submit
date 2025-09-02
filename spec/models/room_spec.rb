require 'rails_helper'

RSpec.describe Room, type: :model do
  describe 'バリデーション' do
    let(:user) { create(:user) } # Roomの作成にはuserが必要なため用意します
    let(:room) { build(:room, user: user) }

    it '名前、説明、一泊あたりの料金、住所、ユーザーがあれば有効であること' do
      expect(room).to be_valid
    end

    it '名前がなければ無効であること' do
      room.name = nil
      expect(room).not_to be_valid
      expect(room.errors[:name]).to include("を入力してください")
    end

    it '説明がなければ無効であること' do
      room.description = nil
      expect(room).not_to be_valid
      expect(room.errors[:description]).to include("を入力してください")
    end

    it '一泊あたりの料金がなければ無効であること' do
      room.price_per_night = nil
      expect(room).not_to be_valid
      expect(room.errors[:price_per_night]).to include("を入力してください")
    end

    it '一泊あたりの料金が1未満であれば無効であること' do
      room.price_per_night = 0
      expect(room).not_to be_valid
      expect(room.errors[:price_per_night]).to include("は1以上の値にしてください")
    end

    it '一泊あたりの料金が数値でなければ無効であること' do
      room.price_per_night = "abc" # 文字列の場合
      expect(room).not_to be_valid
      expect(room.errors[:price_per_night]).to include("は数値で入力してください") # または "is not a number"
    end

    it '住所がなければ無効であること' do
      room.address = nil
      expect(room).not_to be_valid
      expect(room.errors[:address]).to include("を入力してください")
    end

    it 'ユーザーがなければ無効であること' do
      room_without_user = build(:room, user: nil)
      expect(room_without_user).not_to be_valid
      expect(room_without_user.errors[:user]).to include("を入力してください") # もしくは "must exist"
    end
  end

  describe 'アソシエーション' do
    let!(:user) { create(:user) }
    let!(:room) { create(:room, user: user) }

    context 'User モデルとの関連' do
      it 'User に属すること (belongs_to)' do
        expect(room.user).to eq user
      end
    end

    context 'Reservation モデルとの関連' do
      let!(:reservation) { create(:reservation, room: room, user: user) } # Reservationの作成にはroomとuserが必要

      it '複数の Reservation を持つことができる (has_many)' do
        expect(room.reservations).to include(reservation)
        new_reservation = create(:reservation, room: room, user: create(:user)) # 別のユーザーによる予約も可能
        expect(room.reservations).to include(new_reservation)
      end

      it 'Room が削除された場合、関連する Reservation も削除されること (dependent: :destroy)' do
        # 最初にReservationが存在することを確認
        expect { Reservation.find(reservation.id) }.not_to raise_error(ActiveRecord::RecordNotFound)
        # Roomを削除
        expect { room.destroy }.to change { Reservation.count }.by(-1)
        # Reservationも削除されたことを確認
        expect { Reservation.find(reservation.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'RoomImage との関連 (Active Storage)' do
      it 'room_image メソッドを持つこと (has_one_attached)' do
        expect(room).to respond_to(:room_image)
      end
    end
  end
end
