class EchoJob < ApplicationJob
  queue_as :default

  def perform(message)
    sleep(10)
    Rails.logger.info(message.to_json)
  end
end
