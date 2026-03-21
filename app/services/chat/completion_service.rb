class Chat::CompletionService
  MAX_TOOL_LOOPS = 5
  MAX_RETRIES = 3
  RETRY_BASE_DELAY = 2 # seconds
  TOOL_MODEL = "gpt-4.1-mini"
  FINAL_MODEL = "gpt-4.1"
  MIN_REQUEST_INTERVAL = 3 # seconds between requests per user

  SYSTEM_PROMPT = <<~PROMPT.freeze
    You are Stovaro's recipe assistant. You help users discover recipes, plan meals, and answer cooking questions.

    Rules:
    - Use the available tools to look up real recipes and user data — never make up recipe names or ingredients.
    - When mentioning a recipe, always link to it as [Recipe Title](/recipes/slug).
    - Be friendly, concise, and helpful.
    - If the user uploads food or ingredient images, analyze them and use that visual context in your answer.
    - If the user shares a dish photo and asks what they made, give your best visual read, clearly note uncertainty, and offer a recipe recreation path.
    - If the user asks about their favorites, collections, or recipes, use the appropriate tool.
    - For recipe suggestions, search the site first rather than inventing recipes.
    - You can combine multiple tool calls to give thorough answers.
  PROMPT

  def initialize(conversation)
    @conversation = conversation
    @user = conversation.user
    @executor = Chat::ToolExecutor.new(user: @user)
  end

  def call
    throttle_request!
    messages = build_messages
    tool_loops = 0

    loop do
      # Use cheaper model for tool-calling rounds, full model for final response
      model = tool_loops > 0 ? TOOL_MODEL : FINAL_MODEL
      response = request_completion(messages, model: model)
      choice = response.dig("choices", 0, "message")

      if choice["tool_calls"].present? && tool_loops < MAX_TOOL_LOOPS
        # Save assistant message with tool calls
        @conversation.messages.create!(
          role: "assistant",
          content: choice["content"],
          tool_calls: choice["tool_calls"].to_json
        )
        messages << { role: "assistant", content: choice["content"], tool_calls: choice["tool_calls"] }

        # Execute each tool call and add results
        choice["tool_calls"].each do |tool_call|
          result = @executor.call(
            tool_name: tool_call.dig("function", "name"),
            arguments: tool_call.dig("function", "arguments")
          )

          @conversation.messages.create!(
            role: "tool",
            content: result,
            tool_call_id: tool_call["id"],
            tool_name: tool_call.dig("function", "name")
          )
          messages << { role: "tool", content: result, tool_call_id: tool_call["id"] }
        end

        tool_loops += 1
      else
        # Final text response — save and broadcast
        assistant_message = @conversation.messages.create!(
          role: "assistant",
          content: choice["content"]
        )

        broadcast_message(assistant_message)
        broadcast_done
        break
      end
    end
  rescue StandardError => e
    Rails.logger.error("[Chat::CompletionService] Error: #{e.class}: #{e.message}")
    Rails.logger.error("[Chat::CompletionService] Conversation: id=#{@conversation.id} user=#{@user.id} (#{@user.username})")
    Rails.logger.error("[Chat::CompletionService] Backtrace:\n#{e.backtrace&.first(20)&.join("\n")}")

    user_message = if e.is_a?(Faraday::TooManyRequestsError)
      "I'm being rate-limited by the AI service right now. Please wait a minute and try again."
    else
      "Sorry, I ran into a problem. Please try again in a moment."
    end

    error_message = @conversation.messages.create!(
      role: "assistant",
      content: user_message
    )
    broadcast_message(error_message)
    broadcast_done
  end

  private

  def build_messages
    [ { role: "system", content: system_prompt } ] + @conversation.messages_for_api
  end

  def throttle_request!
    cache_key = "chat_rate_limit:user:#{@user.id}"
    last_request_at = Rails.cache.read(cache_key)

    if last_request_at
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - last_request_at
      if elapsed < MIN_REQUEST_INTERVAL
        wait_time = MIN_REQUEST_INTERVAL - elapsed
        Rails.logger.info("[Chat::CompletionService] Throttling user=#{@user.id} for #{wait_time.round(1)}s")
        sleep(wait_time)
      end
    end

    Rails.cache.write(cache_key, Process.clock_gettime(Process::CLOCK_MONOTONIC), expires_in: MIN_REQUEST_INTERVAL.seconds)
  end

  def request_completion(messages, model: FINAL_MODEL)
    client = OpenAI::Client.new
    retries = 0

    begin
      Rails.logger.info("[Chat::CompletionService] Requesting completion: conversation=#{@conversation.id} model=#{model} message_count=#{messages.size} attempt=#{retries + 1}")
      response = client.chat(
        parameters: {
          model: model,
          messages: messages,
          tools: Chat::ToolDefinitions.new(user: @user).all
        }
      )
      if response["error"]
        Rails.logger.error("[Chat::CompletionService] API error response: #{response['error'].inspect}")
      end
      Rails.logger.info("[Chat::CompletionService] Response finish_reason=#{response.dig('choices', 0, 'finish_reason')} tool_calls=#{response.dig('choices', 0, 'message', 'tool_calls')&.size || 0}")
      response
    rescue Faraday::TooManyRequestsError, Faraday::ServerError => e
      retries += 1
      if retries <= MAX_RETRIES
        delay = RETRY_BASE_DELAY ** retries
        Rails.logger.warn("[Chat::CompletionService] #{e.class} (attempt #{retries}/#{MAX_RETRIES}), retrying in #{delay}s...")
        sleep(delay)
        retry
      end
      Rails.logger.error("[Chat::CompletionService] #{e.class} persisted after #{MAX_RETRIES} retries, giving up")
      raise
    end
  end

  def system_prompt
    return SYSTEM_PROMPT unless @user.admin?

    <<~PROMPT
      #{SYSTEM_PROMPT}

      You are also Stovaro's admin seed copilot.

      Admin rules:
      - When the admin wants new site content, use the seed tools instead of describing what you would do.
      - Prefer creating a preview first unless the admin explicitly asks you to publish immediately.
      - If the admin uploads images, use them as visual reference when deciding what recipe or category content to create.
      - When tool results include preview_url or image_urls, present them with markdown links and markdown images on their own lines so they render inline in chat.
      - For bulk preview requests spanning many recipes or multiple categories, use the batch queue tool instead of the single-preview tool.
      - If the admin asks for recipes for every category, fetch the category list and queue previews for all of them.
      - If the admin says "each category" or references all categories, use get_categories first if you need the category list.
      - Use the recipe seed tools for recipe requests and the category seed tools for standalone category requests.
      - A recipe preview should summarize the recipe title, category, tags, and available preview links/images.
      - A category preview should summarize the category title, slug, description, and preview links/images.
      - A queued batch response should clearly say the previews were queued and point the admin to the preview links or Seed Studio.
      - If a preview already exists and the admin approves it, use the matching publish tool.
      - Never claim a recipe or category was created unless a tool confirms it.
    PROMPT
  end

  def broadcast_message(message)
    Turbo::StreamsChannel.broadcast_append_to(
      @conversation,
      target: "chat_messages_inner",
      partial: "chat/message",
      locals: { message: message }
    )
  end

  def broadcast_done
    Turbo::StreamsChannel.broadcast_remove_to(
      @conversation,
      target: "chat_thinking"
    )
  end
end
