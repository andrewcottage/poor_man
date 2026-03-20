class Chat::CompletionService
  MAX_TOOL_LOOPS = 5

  SYSTEM_PROMPT = <<~PROMPT.freeze
    You are Stovaro's recipe assistant. You help users discover recipes, plan meals, and answer cooking questions.

    Rules:
    - Use the available tools to look up real recipes and user data — never make up recipe names or ingredients.
    - When mentioning a recipe, always link to it as [Recipe Title](/recipes/slug).
    - Be friendly, concise, and helpful.
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
    messages = build_messages
    tool_loops = 0

    loop do
      response = request_completion(messages)
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
    Rails.logger.error("[Chat::CompletionService] Error: #{e.message}")
    error_message = @conversation.messages.create!(
      role: "assistant",
      content: "Sorry, I ran into a problem. Please try again in a moment."
    )
    broadcast_message(error_message)
    broadcast_done
  end

  private

  def build_messages
    [ { role: "system", content: system_prompt } ] + @conversation.messages_for_api
  end

  def request_completion(messages)
    client = OpenAI::Client.new
    client.chat(
      parameters: {
        model: "gpt-4.1",
        messages: messages,
        tools: Chat::ToolDefinitions.new(user: @user).all
      }
    )
  end

  def system_prompt
    return SYSTEM_PROMPT unless @user.admin?

    <<~PROMPT
      #{SYSTEM_PROMPT}

      You are also Stovaro's admin seed copilot.

      Admin rules:
      - When the admin wants new site content, use the seed tools instead of describing what you would do.
      - Prefer creating a preview first unless the admin explicitly asks you to publish immediately.
      - Use the recipe seed tools for recipe requests and the category seed tools for standalone category requests.
      - A recipe preview should summarize the recipe title, category, tags, and available preview links/images.
      - A category preview should summarize the category title, slug, description, and preview links/images.
      - If a preview already exists and the admin approves it, use the matching publish tool.
      - Never claim a recipe or category was created unless a tool confirms it.
    PROMPT
  end

  def broadcast_message(message)
    Turbo::StreamsChannel.broadcast_append_to(
      @conversation,
      target: "chat_messages",
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
