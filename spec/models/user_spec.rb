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
end
