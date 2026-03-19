class Chat::RespondJob < ApplicationJob
  queue_as :default

  def perform(conversation)
    Chat::CompletionService.new(conversation).call
  end
end
