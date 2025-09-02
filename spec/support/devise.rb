RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :system
  # Warden::Test::Helpers も含めておくと良い場合があります。
  # config.include Warden::Test::Helpers
  # config.before(:suite) { Warden.test_mode! }
end
