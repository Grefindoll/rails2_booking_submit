RSpec.configure do |config|
  config.before(:each, type: :system) do
    # デフォルトのドライバは :rack_test (JS不要、高速)
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    # テストに js: true メタデータを付けた場合、ヘッドレスChromeを使用
    driven_by :selenium_chrome_headless
  end
end
