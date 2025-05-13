# spec/system/reservations_spec.rb
require 'rails_helper'

RSpec.describe "Reservations", type: :system do
  # テストで使用するユーザー、施設、予約データを事前に作成
  let!(:user) { create(:user, name: "予約ユーザー", email: "reservation-system-spec-user@example.com", password: "password123", password_confirmation: "password123") }
  let!(:other_user) { create(:user, name: "別ユーザー", email: "other-reservation-system-spec-user@example.com", password: "password123", password_confirmation: "password123") }
  let!(:room_owner) { create(:user, name: "施設オーナー", email: "room-owner-system-spec@example.com", password: "password123", password_confirmation: "password123") }
  let!(:room) { create(:room, name: "予約テスト用施設", description: "静かで快適な宿です。", address: "予約テスト県予約市1-2-3", price_per_night: 5000, user: room_owner) }
  let!(:other_room) { create(:room, name: "別の施設（予約一覧用）", user: room_owner, price_per_night: 7000) }

  # 他のユーザーによる予約データ（自分の予約一覧に表示されないことを確認するため）
  # 作成時刻をテストケース内の travel_to と明確にずらす
  let!(:reservation_by_other_user) do
    travel_to Time.zone.local(2025, 3, 15, 10, 0, 0) do # ★★★ 時刻を明確にずらす ★★★
      create(:reservation,
             room: room, # 同じ施設を予約するケース
             user: other_user,
             check_in: Time.zone.local(2025, 7, 20, 15, 0, 0),
             check_out: Time.zone.local(2025, 7, 22, 10, 0, 0),
             number_of_guests: 1)
    end
  end

  describe "施設予約 (reservations#new, reservations#create)" do
    context "未ログインの場合" do
      it "予約ページにアクセスしようとするとログインページにリダイレクトされること" do
        visit new_room_reservation_path(room_id: room.id)
        expect(page).to have_current_path new_user_session_path
        expect(page).to have_content "ログインもしくはアカウント登録してください。"
      end
    end

    context "ログイン済みの場合" do
      before do
        sign_in user
        # 時刻を固定 (Reservationモデルの check_in_is_today_or_after バリデーションのため)
        # テスト実行日を 2025-06-10 とする (他のlet!のtravel_toと重ならないように)
        travel_to Time.zone.local(2025, 6, 10, 10, 0, 0)
        visit room_path(room) # 施設詳細ページから開始
        click_link "予約する"
      end

      after do
        travel_back # 時刻固定を解除
      end

      it "予約ページが正しく表示され、フォーム要素が存在すること" do
        expect(page).to have_current_path new_room_reservation_path(room_id: room.id)
        expect(page).to have_content "#{room.name}さんの予約"
        expect(page).to have_field "チェックイン日"
        expect(page).to have_field "チェックアウト日"
        expect(page).to have_field "人数"
        expect(page).to have_button "予約する"
      end

      context "有効な情報を入力した場合" do
        it "予約が作成され、予約完了確認ページにリダイレクトし、情報が正しく表示されること" do
          check_in_datetime_str = "2025-07-01T15:00"
          check_out_datetime_str = "2025-07-03T10:00" # 2泊
          number_of_guests = 2

          # datetime_local_field には "YYYY-MM-DDTHH:MM" 形式で入力
          fill_in "チェックイン日", with: check_in_datetime_str
          fill_in "チェックアウト日", with: check_out_datetime_str
          fill_in "人数", with: number_of_guests

          click_button "予約する"

          # このテストケース内で作成された予約を特定する
          new_reservation = Reservation.where(user: user, room: room).order(created_at: :desc).first
          expect(new_reservation).not_to be_nil # 念のため取得確認

          expect(page).to have_current_path confirmation_reservation_path(new_reservation)
          expect(page).to have_content "予約が完了しました。" # ReservationsControllerのnotice

          # 予約完了確認ページの内容を確認
          check_in_dt_for_display = Time.zone.parse(check_in_datetime_str)
          check_out_dt_for_display = Time.zone.parse(check_out_datetime_str)

          expect(page).to have_content "施設名: #{room.name}"
          expect(page).to have_content "チェックイン日: #{check_in_dt_for_display.strftime('%Y-%m-%d %H:%M')}"
          expect(page).to have_content "チェックアウト日: #{check_out_dt_for_display.strftime('%Y-%m-%d %H:%M')}"
          expect(page).to have_content "宿泊日数: #{(check_out_dt_for_display.to_date - check_in_dt_for_display.to_date).to_i} 日"
          expect(page).to have_content "人数: #{number_of_guests} 人"
          expected_total_price = (check_out_dt_for_display.to_date - check_in_dt_for_display.to_date).to_i * number_of_guests * room.price_per_night
          # number_with_delimiter の結果を直接記述 (to_i で整数にしてからカンマ区切り)
          expect(page).to have_content "支払い金額: ¥#{expected_total_price.to_i.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, '\1,')}"
          expect(page).to have_link "全ての予約済み施設を確認する", href: my_reservations_path
        end
      end
    end
  end

  describe "自分の予約一覧表示 (reservations#my_reservations)" do
    # ログインユーザーuserによる予約データ (作成時刻を明確に設定し、他のデータと区別)
    let!(:reservation1_by_user) do
      travel_to Time.zone.local(2025, 6, 1, 12, 30, 0) do # ★★★ 他のtravel_toと重ならないように ★★★
        create(:reservation,
               room: room,
               user: user,
               check_in: Time.zone.local(2025, 8, 1, 14, 0, 0),
               check_out: Time.zone.local(2025, 8, 3, 11, 0, 0), # 2泊
               number_of_guests: 2, # total_price = 2 * 2 * 5000 = 20000
               created_at: Time.zone.local(2025, 6, 1, 12, 30, 0)) # created_atも明示
      end
    end
    let!(:reservation2_by_user) do
      travel_to Time.zone.local(2025, 6, 5, 14, 30, 0) do # ★★★ 他のtravel_toと重ならないように ★★★
        create(:reservation,
               room: other_room,
               user: user,
               check_in: Time.zone.local(2025, 9, 5, 16, 0, 0),
               check_out: Time.zone.local(2025, 9, 6, 10, 0, 0), # 1泊
               number_of_guests: 1, # total_price = 1 * 1 * 7000 = 7000
               created_at: Time.zone.local(2025, 6, 5, 14, 30, 0)) # created_atも明示
      end
    end

    context "未ログインの場合" do
      it "アクセスしようとするとログインページにリダイレクトされること" do
        visit my_reservations_path
        expect(page).to have_current_path new_user_session_path
        expect(page).to have_content "ログインもしくはアカウント登録してください。"
      end
    end

    context "ログイン済みの場合" do
      before do
        sign_in user
        visit my_reservations_path
      end

      it "自分が予約した施設のみが表示され、他のユーザーの予約は表示されないこと" do
        expect(page).to have_current_path my_reservations_path
        expect(page).to have_content "あなたの予約済み施設の一覧" # タイトル

        # テーブルヘッダーの確認 (代表的なもの)
        within "table.reservations-table thead" do
          expect(page).to have_content "施設名"
          expect(page).to have_content "チェックイン日"
          expect(page).to have_content "合計料金"
          expect(page).to have_content "予約日時"
        end

        # --- 自分の予約が存在することの確認 ---
        # reservation1_by_user (施設名 "予約テスト用施設", チェックイン "2025-08-01", 合計 ¥20,000, 予約日時 "2025-06-01 12:30")
        expect(page).to have_content reservation1_by_user.room.name
        expect(page).to have_content reservation1_by_user.check_in.strftime('%Y-%m-%d')
        expect(page).to have_content "¥20,000" # 事前に計算したフォーマット済み文字列
        expect(page).to have_content reservation1_by_user.created_at.strftime('%Y-%m-%d %H:%M')

        # reservation2_by_user (施設名 "別の施設（予約一覧用）", チェックイン "2025-09-05", 合計 ¥7,000, 予約日時 "2025-06-05 14:30")
        expect(page).to have_content reservation2_by_user.room.name
        expect(page).to have_content reservation2_by_user.check_in.strftime('%Y-%m-%d')
        expect(page).to have_content "¥7,000" # 事前に計算したフォーマット済み文字列
        expect(page).to have_content reservation2_by_user.created_at.strftime('%Y-%m-%d %H:%M')
        expect(page).not_to have_content reservation_by_other_user.check_in.strftime('%Y-%m-%d')
        expect(page).not_to have_content reservation_by_other_user.created_at.strftime('%Y-%m-%d %H:%M')
        expect(page.all("table.reservations-table tbody tr.reservation-row").count).to eq 2
      end

      it "ヘッダーのドロップダウンメニューから「予約済み一覧」に遷移できること" do
        visit root_path # ヘッダー操作のために一度トップページへ
        within "header .navbar-right" do
          find('button.dropdown-toggle').click
          within ".dropdown-menu" do
            click_link(href: my_reservations_path) # href属性で「予約済み一覧」リンクをクリック
          end
        end
        expect(page).to have_current_path my_reservations_path
        expect(page).to have_content "あなたの予約済み施設の一覧"
      end
    end
  end
end
