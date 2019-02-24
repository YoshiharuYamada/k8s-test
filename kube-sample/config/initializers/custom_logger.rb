class CustomLogger < Rails::Rack::Logger
  def call(env)
    if ['/health_checks'].include?(env['PATH_INFO'])
      Rails.logger.silence do
        super
      end
    else
      super
    end
  end
end

Rails.configuration.middleware.swap Rails::Rack::Logger, CustomLogger, Rails.configuration.log_tags
