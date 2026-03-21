require "test_helper"

class Chat::CompletionServiceTest < ActiveSupport::TestCase
  setup do
    @conversation = chat_conversations(:pro_conversation)
    @user = @conversation.user
    @service = Chat::CompletionService.new(@conversation)
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    Rails.cache = @original_cache
  end

  test "uses FINAL_MODEL for first request and TOOL_MODEL for subsequent tool loops" do
    tool_response = {
      "choices" => [{
        "message" => {
          "content" => nil,
          "tool_calls" => [{
            "id" => "call_1",
            "function" => { "name" => "search_recipes", "arguments" => '{"query":"pasta"}' }
          }]
        },
        "finish_reason" => "tool_calls"
      }]
    }

    final_response = {
      "choices" => [{
        "message" => { "content" => "Here are some pasta recipes!", "tool_calls" => nil },
        "finish_reason" => "stop"
      }]
    }

    models_used = []
    mock_client = mock("openai_client")
    mock_client.stubs(:chat).with { |params| models_used << params[:parameters][:model]; true }.returns(tool_response).then.returns(final_response)
    OpenAI::Client.stubs(:new).returns(mock_client)

    Chat::ToolExecutor.any_instance.stubs(:call).returns('[]')
    Turbo::StreamsChannel.stubs(:broadcast_append_to)
    Turbo::StreamsChannel.stubs(:broadcast_remove_to)

    @service.call

    assert_equal Chat::CompletionService::FINAL_MODEL, models_used[0], "First request should use FINAL_MODEL"
    assert_equal Chat::CompletionService::TOOL_MODEL, models_used[1], "Tool loop request should use TOOL_MODEL"
  end

  test "retries on 429 rate limit errors with backoff" do
    call_count = 0
    mock_client = mock("openai_client")
    mock_client.stubs(:chat).with { call_count += 1; true }.raises(Faraday::TooManyRequestsError).then.raises(Faraday::TooManyRequestsError).then.returns({
      "choices" => [{
        "message" => { "content" => "Success!", "tool_calls" => nil },
        "finish_reason" => "stop"
      }]
    })
    OpenAI::Client.stubs(:new).returns(mock_client)
    Turbo::StreamsChannel.stubs(:broadcast_append_to)
    Turbo::StreamsChannel.stubs(:broadcast_remove_to)

    # Stub sleep to avoid actual delays in tests
    @service.stubs(:sleep)

    @service.call

    assert_equal 3, call_count, "Should have retried twice then succeeded on third attempt"
    assert_equal "Success!", @conversation.messages.where(role: "assistant").last.content
  end

  test "gives up after max retries on persistent 429 and shows rate limit message" do
    mock_client = mock("openai_client")
    mock_client.stubs(:chat).raises(Faraday::TooManyRequestsError)
    OpenAI::Client.stubs(:new).returns(mock_client)
    Turbo::StreamsChannel.stubs(:broadcast_append_to)
    Turbo::StreamsChannel.stubs(:broadcast_remove_to)

    @service.stubs(:sleep)

    @service.call

    last_message = @conversation.messages.where(role: "assistant").last
    assert_includes last_message.content, "rate-limited"
  end

  test "retries on server errors" do
    call_count = 0
    mock_client = mock("openai_client")
    mock_client.stubs(:chat).with { call_count += 1; true }.raises(Faraday::ServerError).then.returns({
      "choices" => [{
        "message" => { "content" => "Recovered!", "tool_calls" => nil },
        "finish_reason" => "stop"
      }]
    })
    OpenAI::Client.stubs(:new).returns(mock_client)
    Turbo::StreamsChannel.stubs(:broadcast_append_to)
    Turbo::StreamsChannel.stubs(:broadcast_remove_to)

    @service.stubs(:sleep)

    @service.call

    assert_equal 2, call_count
    assert_equal "Recovered!", @conversation.messages.where(role: "assistant").last.content
  end

  test "throttle_request sleeps when requests are too frequent" do
    cache_key = "chat_rate_limit:user:#{@user.id}"
    Rails.cache.write(cache_key, Process.clock_gettime(Process::CLOCK_MONOTONIC), expires_in: 10.seconds)

    @service.expects(:sleep).with { |t| t > 0 && t <= Chat::CompletionService::MIN_REQUEST_INTERVAL }.once

    @service.send(:throttle_request!)
  end

  test "throttle_request does not sleep on first request" do

    @service.expects(:sleep).never

    @service.send(:throttle_request!)
  end

  test "shows generic error message for non-rate-limit errors" do
    mock_client = mock("openai_client")
    mock_client.stubs(:chat).raises(StandardError, "Something unexpected")
    OpenAI::Client.stubs(:new).returns(mock_client)
    Turbo::StreamsChannel.stubs(:broadcast_append_to)
    Turbo::StreamsChannel.stubs(:broadcast_remove_to)

    @service.call

    last_message = @conversation.messages.where(role: "assistant").last
    assert_includes last_message.content, "ran into a problem"
    assert_not_includes last_message.content, "rate-limited"
  end
end
