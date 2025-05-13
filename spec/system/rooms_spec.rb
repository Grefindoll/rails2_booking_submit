# spec/system/rooms_spec.rb
require 'rails_helper'

RSpec.describe "Rooms", type: :system do
  # テストで使用するユーザーと施設を事前に作成
  let!(:user) { create(:user, name: "テストユーザー", email: "room-spec-user@example.com", password: "password123", password_confirmation: "password123") }
  let!(:other_user) { create(:user, name: "別ユーザー", email: "other-room-spec-user@example.com", password: "password123", password_confirmation: "password123") }

  # 施設データ（価格などを固定値にしてテストしやすくする）
  let!(:room1_by_user) { create(:room, name: "ユーザーの素敵な宿", description: "快適な滞在をお約束します。", address: "東京都テスト区1-1-1", price_per_night: 10000, user: user) }
  let!(:room2_by_user) { create(:room, name: "ユーザーの静かな隠れ家", description: "リラックスできる空間です。", address: "東京都テスト区2-2-2", price_per_night: 8000, user: user) }
  let!(:room_by_other_user) { create(:room, name: "他ユーザーの豪華なホテル", description: "最高のサービスを提供します。", address: "大阪府テスト市3-3-3", price_per_night: 20000, user: other_user) }

  describe "施設一覧表示 (rooms#index)" do
    before do
      visit rooms_path
    end

    it "未ログインでもアクセスでき、全ての施設情報（名前、説明、住所、料金）が表示されること" do
      expect(page).to have_current_path rooms_path
      expect(page).to have_content "施設一覧" # app/views/rooms/index.html.erb のタイトル

      # room1_by_user の情報
      within ".rooms-grid" do # 施設が表示される範囲を特定するとより堅牢
        expect(page).to have_link room1_by_user.name, href: room_path(room1_by_user)
        expect(page).to have_content room1_by_user.description
        expect(page).to have_content "住所：#{room1_by_user.address}"
        expect(page).to have_content "宿泊料金：10,000" # number_with_delimiter(10000) の結果
      end

      # room_by_other_user の情報
      within ".rooms-grid" do
        expect(page).to have_link room_by_other_user.name, href: room_path(room_by_other_user)
        expect(page).to have_content "宿泊料金：20,000" # number_with_delimiter(20000) の結果
      end
    end

    it "検索フォーム（エリア名、フリーワード）が表示されていること" do
      expect(page).to have_field "エリア名で検索" # placeholder
      expect(page).to have_field "フリーワードで検索（ホテル名・説明文）" # placeholder
      expect(page).to have_button "検索"
    end

    context "未ログインの場合" do
      it "「新しい施設を投稿」リンクが表示され、クリックするとログインページにリダイレクトされること" do
        expect(page).to have_link "新しい施設を投稿", href: new_room_path
        click_link "新しい施設を投稿"
        expect(page).to have_current_path new_user_session_path
        expect(page).to have_content "ログインもしくはアカウント登録してください。" # Deviseのi18nメッセージに合わせる
      end
    end

    context "ログイン済みの場合" do
      before do
        sign_in user # Deviseのテストヘルパー
        visit rooms_path # ログイン状態を反映させるために再訪
      end

      it "「新しい施設を投稿」リンクが表示され、クリックすると新規施設登録ページに遷移すること" do
        expect(page).to have_link "新しい施設を投稿", href: new_room_path
        click_link "新しい施設を投稿"
        expect(page).to have_current_path new_room_path
      end
    end
  end

  describe "施設詳細表示 (rooms#show)" do
    it "未ログインでもアクセスでき、施設の詳細情報と「予約する」ボタンが表示されること" do
      visit room_path(room1_by_user)

      expect(page).to have_current_path room_path(room1_by_user)
      expect(page).to have_content "施設の詳細" # app/views/rooms/show.html.erb のタイトル
      expect(page).to have_content room1_by_user.name
      expect(page).to have_content room1_by_user.description
      expect(page).to have_content "宿泊料金: 10,000¥"
      expect(page).to have_content "住所: #{room1_by_user.address}"
      expect(page).to have_link "予約する", href: new_room_reservation_path(room_id: room1_by_user.id)
      expect(page).to have_link "前のページに戻る"
    end
  end

  describe "施設新規登録 (rooms#new, rooms#create)" do
    context "未ログインの場合" do
      it "新規施設登録ページにアクセスしようとするとログインページにリダイレクトされること" do
        visit new_room_path
        expect(page).to have_current_path new_user_session_path
        expect(page).to have_content "ログインもしくはアカウント登録してください。"
      end
    end

    context "ログイン済みの場合" do
      before do
        sign_in user
        visit new_room_path
      end

      it "新規施設登録ページが正しく表示され、フォーム要素が存在すること" do
        expect(page).to have_current_path new_room_path
        expect(page).to have_content "新しい施設を作成"
        expect(page).to have_field "施設名"
        expect(page).to have_field "紹介文"
        expect(page).to have_field "宿泊料金（/日）"
        expect(page).to have_field "住所"
        expect(page).to have_field "施設画像" # input type="file"
        expect(page).to have_button "施設を作成"
        expect(page).to have_link "施設一覧に戻る", href: rooms_path
      end

      context "有効な情報を入力した場合" do
        it "施設が作成され、施設一覧にリダイレクトし、成功メッセージが表示されること" do
          new_room_name = "システムテスト用 新規施設"
          fill_in "施設名", with: new_room_name
          fill_in "紹介文", with: "これはシステムテストで作成された施設です。"
          fill_in "宿泊料金（/日）", with: 15000
          fill_in "住所", with: "テスト県テスト市9-8-7"
          # 画像のアップロードテストは、attach_file を使います。
          # 例: attach_file "施設画像", Rails.root.join("spec/fixtures/files/sample_image.jpg")
          # 今回はフィールドの存在確認のみとし、実際のアップロードテストは省略します。
          click_button "施設を作成"

          expect(page).to have_current_path rooms_path # RoomsController#create のリダイレクト先
          expect(page).to have_content "施設が正常に作成されました。" # RoomsControllerのnotice
          expect(page).to have_content new_room_name # 作成した施設が一覧に表示されている
        end
      end

      context "無効な情報（施設名が空）を入力した場合" do
        it "エラーメッセージが表示され、新規登録ページが再描画され、入力内容は保持されること" do
          description_text = "説明文だけ入力"
          price_text = "5000"
          address_text = "エラー用住所"

          fill_in "施設名", with: "" # 施設名を空にする
          fill_in "紹介文", with: description_text
          fill_in "宿泊料金（/日）", with: price_text
          fill_in "住所", with: address_text
          click_button "施設を作成"

          expect(page).to have_content "新しい施設を作成" # newテンプレートが再描画される（見出しで確認）
          # バリデーションエラーメッセージの確認 (i18n設定による)
          expect(page).to have_content "Nameを入力してください" # または "施設名を入力してください"
          # 他の入力値がフォームに保持されていることを確認
          expect(page).to have_field "紹介文", with: description_text
          expect(page).to have_field "宿泊料金（/日）", with: price_text # number_fieldも文字列として値が取れる
          expect(page).to have_field "住所", with: address_text
        end
      end
    end
  end

  describe "自分が登録した施設一覧表示 (rooms#my_rooms)" do
    context "未ログインの場合" do
      it "アクセスしようとするとログインページにリダイレクトされること" do
        visit my_rooms_path
        expect(page).to have_current_path new_user_session_path
        expect(page).to have_content "ログインもしくはアカウント登録してください。"
      end
    end

    context "ログイン済みの場合" do
      before do
        sign_in user
        visit my_rooms_path
      end

      it "自分が登録した施設のみが表示され、他のユーザーの施設は表示されないこと" do
        expect(page).to have_current_path my_rooms_path
        expect(page).to have_content "あなたが登録した施設一覧" # app/views/rooms/my_rooms.html.erb のタイトル

        # 自分が登録した施設が表示されていることを確認
        expect(page).to have_link room1_by_user.name, href: room_path(room1_by_user)
        expect(page).to have_content room1_by_user.description
        expect(page).to have_link room2_by_user.name, href: room_path(room2_by_user)

        # 他のユーザーが登録した施設が表示されていないことを確認
        expect(page).not_to have_link room_by_other_user.name
        expect(page).not_to have_content room_by_other_user.description
      end

      it "ヘッダーのドロップダウンメニューから「登録済み一覧」に遷移できること" do
        visit root_path # ヘッダー操作のために一度トップページへ
        within "header .navbar-right" do
          find('button.dropdown-toggle').click
          within ".dropdown-menu" do # ドロップダウンメニューの範囲を特定
            click_link(href: my_rooms_path) # href属性で「登録済み一覧」リンクをクリック
          end
        end
        expect(page).to have_current_path my_rooms_path
        expect(page).to have_content "あなたが登録した施設一覧"
      end
    end
  end
end
