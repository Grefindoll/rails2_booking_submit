# spec/system/top_page_spec.rb
require 'rails_helper'

RSpec.describe "TopPages", type: :system do
  describe "トップページの表示" do
    before do
      visit root_path
    end

    it "正しいタイトルが表示されること" do
      expect(page).to have_title "Booking2" # layouts/application.html.erb の <title> に合わせる
    end

    it "ヘッダーにロゴが表示されること" do
      expect(page).to have_selector "header .header-logo[alt='ロゴ']"
    end

    it "フッターにロゴとコピーライトが表示されること" do
      expect(page).to have_selector "footer .header-logo[alt='ロゴ']"
      expect(page).to have_content "Copyright © Potepan Share 2025 All rights reserved"
    end

    context "未ログインの場合" do
      it "ヘッダーに「ログイン」と「新規登録」のリンクが表示されること" do
        within "header .navbar-right" do
          expect(page).to have_link "ログイン", href: new_user_session_path
          expect(page).to have_link "新規登録", href: new_user_registration_path
        end
      end

      it "メインコンテンツが表示されること" do
        expect(page).to have_content "Potepan Shareでまだ体験したことのない旅をしよう"
        expect(page).to have_field "エリア名を入力" # Ransackの検索フィールド
        expect(page).to have_button "検索"
        expect(page).to have_link "全ての施設一覧", href: rooms_path
        expect(page).to have_content "おすすめのエリア"
        expect(page).to have_link "東京", href: rooms_path(q: { address_cont: '東京都' })
      end
    end

    context "ログイン済みの場合" do
      let(:user) { create(:user) } # FactoryBotでユーザーを作成

      before do
        sign_in user # Deviseのテストヘルパー (spec/support/devise.rb などに設定が必要)
        visit root_path
      end

      it "ヘッダーにユーザー名とドロップダウンメニューが表示されること" do
        within "header .navbar-right" do
          expect(page).to have_content "#{user.name}さん" # current_user.name を表示
          expect(page).to have_button type: "button", class: "dropdown-toggle" # ドロップダウンボタン
        end
      end

      it "ドロップダウンメニュー内に正しいリンクが表示されること" do
        within "header .navbar-right" do
          find('.dropdown-toggle').click # ドロップダウンを開く (JavaScriptが有効なドライバーが必要)

          expect(page).to have_link "施設の新規登録", href: new_room_path
          expect(page).to have_link "予約済み一覧", href: my_reservations_path
          expect(page).to have_link "登録済み一覧", href: my_rooms_path
          expect(page).to have_link "アカウントの編集", href: edit_user_registration_path
          expect(page).to have_link "プロフィールの詳細", href: user_path(user)
          expect(page).to have_button "ログアウト" # button_to
        end
      end
    end
  end
end
