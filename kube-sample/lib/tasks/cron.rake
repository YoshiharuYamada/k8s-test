namespace :cron do
  desc 'Cron sample'
  task echo: [:environment] do
    Rails.logger.info('Cron exexute.')
  end
end
