# spec/system/user_profile_spec.rb
require 'rails_helper'

RSpec.describe "UserProfiles", type: :system do
  # テストで使用するユーザーを let! で事前に作成し、明確な初期値を設定します。
  let!(:user) { create(:user, name: "テストユーザー", email: "profile-test-user@example.com", password: "password123", password_confirmation: "password123", bio: "初期の自己紹介です。") }

  before do
    # 各テストケースの前にUIを経由してログインします。
    # (Deviseの sign_in ヘルパーが設定済みであれば、そちらを使用しても構いません)
    visit new_user_session_path
    fill_in "user_email", with: user.email
    fill_in "user_password", with: user.password
    click_button "ログイン"
    # ログイン後、意図したページにいることを確認してからテストを進めるのが堅牢です。
    # ここでは application_controller.rb の after_sign_in_path_for が root_path を返すと仮定。
    expect(page).to have_current_path root_path
  end

  describe "プロフィール詳細表示" do
    it "ヘッダーからプロフィール詳細ページに遷移し、情報が表示されること" do
      within "header .navbar-right" do # ヘッダー右側の範囲を特定
        find('button.dropdown-toggle').click # ドロップダウンボタンをクリックしてメニューを開く
        within ".dropdown-menu" do     # 開かれたドロップダウンメニューの範囲を特定
          click_link(href: user_path(user)) # href属性で「プロフィールの詳細」リンクをクリック
        end
      end

      expect(page).to have_current_path user_path(user)
      # app/views/users/show.html.erb の表示内容に基づいて検証します
      expect(page).to have_content "#{user.name}さんの詳細画面"
      expect(page).to have_content user.name
      expect(page).to have_content user.bio
      expect(page).to have_link "プロフィールを編集する", href: edit_user_path(user)
    end
  end

  describe "プロフィール編集" do
    before do
      # プロフィール編集ページへは、詳細ページ経由で遷移します
      visit user_path(user)
      click_link "プロフィールを編集する"
      # 編集ページに正しく遷移したことを確認
      expect(page).to have_current_path edit_user_path(user)
      expect(page).to have_content "プロフィールの編集" # app/views/users/edit.html.erb の見出し
    end

    it "プロフィール編集ページに既存の情報がフォームに表示されていること" do
      expect(page).to have_field "名前", with: user.name
      expect(page).to have_field "自己紹介", with: user.bio
      expect(page).to have_field "プロフィール画像" # input type="file"
      expect(page).to have_button "登録する" # app/views/users/edit.html.erb の submit ボタンのテキスト
    end

    context "有効な情報を入力した場合" do
      it "プロフィールが更新され、詳細ページにリダイレクトされ、ヘッダーの名前も更新されること" do
        new_name = "更新された名前"
        new_bio = "更新された自己紹介文です。これからよろしくお願いします。"

        fill_in "名前", with: new_name
        fill_in "自己紹介", with: new_bio
        # プロフィール画像の更新テストは、ファイルアップロードのテストとなり複雑なため、ここでは省略します。
        # 必要であれば別途テストケースを設けます。
        click_button "登録する"

        # UsersController#update で redirect_to user_path(@user) されることを期待します
        expect(page).to have_current_path user_path(user)

        # UsersController#update にflashメッセージの設定がないため、メッセージの確認は行いません。
        # もしflashメッセージを設定した場合は、以下のような確認を追加します。
        # expect(page).to have_content "プロフィールを更新しました。"

        # 詳細ページで更新後の情報が表示されていることを確認します
        expect(page).to have_content new_name
        expect(page).to have_content new_bio

        # データベースの情報も実際に更新されていることを確認します（任意ですが推奨）
        user.reload # データベースから最新のユーザー情報を読み込みます
        expect(user.name).to eq new_name
        expect(user.bio).to eq new_bio

        # ヘッダーに表示されるユーザー名も更新後の名前に変わっていることを確認します
        within "header .navbar-right" do
          expect(page).to have_content "#{new_name}さん"
        end
      end
    end

    context "無効な情報（例: 名前を空に）を入力した場合" do
      it "エラーメッセージが表示され、編集ページが再描画されること" do
        original_bio = user.bio # 自己紹介は変更しないので、元の値で確認

        fill_in "名前", with: "" # 名前を空にしてバリデーションエラーを発生させます
        click_button "登録する"

        # UsersController#update でバリデーションエラー時に render :edit, status: :unprocessable_entity されることを期待します
        # この場合、URLは変更されず、編集ページのコンテンツが再表示されます。
        expect(page).to have_content "プロフィールの編集" # 編集ページの見出しで再描画を確認

        # Userモデルのバリデーションエラーメッセージが表示されることを確認します
        # このメッセージは、config/locales/ja.yml やモデルのi18n設定に依存します
        expect(page).to have_content "名前を入力してください" # または "Name can't be blank" 等

        # 他のフィールド（自己紹介）の値は入力された（または元の）まま保持されていることを確認します
        expect(page).to have_field "自己紹介", with: original_bio # find_field("自己紹介").value でも可

        # データベースの値は変更されていないことを確認します
        user.reload
        expect(user.name).not_to eq "" # 空になっていないこと（元の名前のままのはず）
        expect(user.name).to eq "テストユーザー" # 元の値を具体的に指定
      end
    end
  end
end
