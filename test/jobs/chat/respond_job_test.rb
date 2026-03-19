require "test_helper"

class Chat::RespondJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  test "enqueues job" do
    conversation = chat_conversations(:pro_conversation)
    assert_enqueued_with(job: Chat::RespondJob) do
      Chat::RespondJob.perform_later(conversation)
    end
  end

  test "calls completion service" do
    conversation = chat_conversations(:pro_conversation)
    Chat::CompletionService.any_instance.expects(:call).once
    Chat::RespondJob.perform_now(conversation)
  end
end
