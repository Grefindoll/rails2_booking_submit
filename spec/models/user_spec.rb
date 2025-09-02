require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'バリデーション' do
    let(:user) { build(:user) }
    let(:user_without_name) { build(:user, name: nil) }
    let(:user_without_email) { build(:user, email: nil) }
    let(:user_without_password) { build(:user, password: nil) }
    let!(:existing_user) { create(:user, email: 'test@example.com') }
    let(:user_with_duplicate_email) { build(:user, email: 'test@example.com') }

    it '名前、メール、パスワードがあれば有効であること' do
      expect(user).to be_valid
    end

    it '名前がなければ無効であること' do
      expect(user_without_name).not_to be_valid
      expect(user_without_name.errors[:name]).to include("を入力してください")
    end

    it '名前は50文字以内であること' do
      user.name = "aaaaa" * 11
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("は50文字以内で入力してください")
    end

    it 'メールがなければ無効であること' do
      expect(user_without_email).not_to be_valid
      expect(user_without_email.errors[:email]).to include("を入力してください")
    end

    it '重複したメールアドレスは無効であること' do
      expect(user_with_duplicate_email).not_to be_valid
      expect(user_with_duplicate_email.errors[:email]).to include('はすでに存在します')
    end

    it 'パスワードがなければ無効であること' do
      expect(user_without_password).not_to be_valid
      expect(user_without_password.errors[:password]).to include("を入力してください")
    end

    it 'パスワードが6文字未満ならば、無効であること' do
      user.password = user.password_confirmation = "a" * 5
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("は6文字以上で入力してください")
    end

    it 'パスワードと確認用パスワードが一致しなければ無効であること' do
      user.password_confirmation = "wrongpassword"
      expect(user).not_to be_valid
    end
  end

  describe 'アソシエーション' do
    # テストデータの準備 (アソシエーションテストではDBに保存されたデータが必要なことが多い)
    let!(:user) { create(:user) }
    let!(:room) { create(:room, user: user) }
    let!(:reservation) { create(:reservation, user: user, room: room) }

    context 'Room モデルとの関連' do
      it '複数の Room を持つことができる (has_many)' do
        # user.rooms で関連する Room の配列が取得でき、作成した room が含まれることを確認
        expect(user.rooms).to include(room)
        # 新しい Room を追加しても user.rooms に含まれることを確認
        new_room = create(:room, user: user)
        expect(user.rooms).to include(new_room)
      end

      it 'User が削除された場合、関連する Room も削除されること (dependent: :destroy)' do
        # change マッチャーを使って、user.destroy の前後で Room.count が 1 減ることを確認
        expect { user.destroy }.to change { Room.count }.by(-1)
      end
    end

    context 'Reservation モデルとの関連' do
      it '複数の Reservation を持つことができる (has_many)' do
        expect(user.reservations).to include(reservation)
        new_reservation = create(:reservation, user: user, room: room)
        expect(user.reservations).to include(new_reservation)
      end

      it 'User が削除された場合、関連する Reservation も削除されること (dependent: :destroy)' do
        expect { user.destroy }.to change { Reservation.count }.by(-1)
      end
    end

    context 'ProfileImage との関連 (Active Storage)' do
      it 'profile_image メソッドを持つこと (has_one_attached)' do
        # respond_to マッチャーを使って、インスタンスがメソッドを持っているか確認
        expect(user).to respond_to(:profile_image)
      end
      # 実際にファイルがattachできるかなどはSystem Spec等でテストします
    end
  end
end
