Sidekiq.configure_server do |config|
  Sidekiq::Logging.logger.level = :debug if Rails.env.development?
  Rails.logger = Sidekiq::Logging.logger
  ActiveRecord::Base.logger = Sidekiq::Logging.logger

  config.redis = Settings.redis.sidekiq.symbolize_keys
end

Sidekiq.configure_client do |config|
  config.redis = Settings.redis.sidekiq.symbolize_keys
end
