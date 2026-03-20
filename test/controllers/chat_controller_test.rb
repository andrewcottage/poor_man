require "test_helper"

class ChatControllerTest < ActionDispatch::IntegrationTest
  test "anonymous user can view chat page" do
    get chat_url
    assert_response :success
    assert_select "[data-controller='chat']"
  end

  test "anonymous user submitting message is redirected to login" do
    post create_message_chat_url, params: { content: "What should I cook?" }
    assert_redirected_to new_session_path
  end

  test "anonymous user gets return_to set to chat path" do
    post create_message_chat_url, params: { content: "What should I cook?" }
    assert_equal chat_path, session[:return_to]
  end

  test "pro user can access chat" do
    login(users(:pro_user))
    get chat_url
    assert_response :success
    assert_select "[data-controller='chat']"
    assert_select "h2", "Recent conversations"
    assert_select "form#chat_input_form[enctype='multipart/form-data']"
  end

  test "admin user can access chat without pro plan" do
    login(users(:admin))
    get chat_url
    assert_response :success
    assert_select "h1", "Seed Copilot"
  end

  test "free user sees upgrade CTA" do
    login(users(:user))
    get chat_url
    assert_response :success
    assert_select "a[href='#{pricing_path}']", text: /Upgrade/
  end

  test "pro user can send a message" do
    login(users(:pro_user))

    assert_enqueued_with(job: Chat::RespondJob) do
      post create_message_chat_url, params: { content: "What should I cook tonight?" }, as: :turbo_stream
    end

    assert_response :success
    conversation = users(:pro_user).chat_conversations.last
    assert_equal "What should I cook tonight?", conversation.messages.where(role: "user").last.content
  end

  test "pro user can send a message with an image attachment" do
    login(users(:pro_user))
    image = Rack::Test::UploadedFile.new(
      Rails.root.join("test/fixtures/files/vaporwave.jpeg"),
      "image/jpeg"
    )

    assert_enqueued_with(job: Chat::RespondJob) do
      post create_message_chat_url,
        params: { content: "What did I make?", images: [ image ] },
        as: :turbo_stream
    end

    assert_response :success
    message = users(:pro_user).chat_conversations.last.messages.where(role: "user").last
    assert_equal "What did I make?", message.content
    assert_equal 1, message.images.count
  end

  test "pro user can send an image-only message" do
    login(users(:pro_user))
    conversation = users(:pro_user).chat_conversations.create!
    image = Rack::Test::UploadedFile.new(
      Rails.root.join("test/fixtures/files/vaporwave.jpeg"),
      "image/jpeg"
    )

    assert_enqueued_with(job: Chat::RespondJob) do
      post create_message_chat_url,
        params: { images: [ image ], conversation_id: conversation.id },
        as: :turbo_stream
    end

    assert_response :success
    message = conversation.reload.messages.where(role: "user").last
    assert_nil message.content
    assert_equal 1, message.images.count
    assert_equal "Photo recipe chat", conversation.reload.title
  end

  test "pro user can start a new conversation" do
    login(users(:pro_user))

    assert_difference(-> { users(:pro_user).chat_conversations.count }, 1) do
      post create_conversation_chat_url
    end

    conversation = users(:pro_user).chat_conversations.order(:created_at).last
    assert_redirected_to chat_conversation_path(conversation)
  end

  test "show renders the requested conversation context" do
    login(users(:pro_user))
    other_conversation = users(:pro_user).chat_conversations.create!(title: "Meal planning")
    other_conversation.messages.create!(role: "user", content: "Help me plan lunches")

    get chat_conversation_url(other_conversation)

    assert_response :success
    assert_select "p", text: "Meal planning"
    assert_select "#chat_messages", text: /Help me plan lunches/
    assert_select "input[type=hidden][name=conversation_id][value='#{other_conversation.id}']", visible: false
  end

  test "message posts to the selected conversation" do
    login(users(:pro_user))
    other_conversation = users(:pro_user).chat_conversations.create!

    assert_enqueued_with(job: Chat::RespondJob) do
      post create_message_chat_url,
        params: { content: "Use this context", conversation_id: other_conversation.id },
        as: :turbo_stream
    end

    assert_equal "Use this context", other_conversation.messages.where(role: "user").last.content
    assert_equal "Use this context", other_conversation.reload.title
  end

  test "user can rename a conversation" do
    login(users(:pro_user))
    conversation = chat_conversations(:pro_conversation)

    patch update_chat_conversation_url(conversation), params: { title: "Dinner ideas" }

    assert_redirected_to chat_conversation_path(conversation)
    assert_equal "Dinner ideas", conversation.reload.title
  end

  test "user can delete a conversation" do
    login(users(:pro_user))
    conversation = chat_conversations(:pro_conversation)
    other_conversation = users(:pro_user).chat_conversations.create!(title: "Backup")

    assert_difference("Chat::Conversation.count", -1) do
      delete destroy_chat_conversation_url(conversation)
    end

    assert_redirected_to chat_conversation_path(other_conversation)
  end

  test "admin user can send a message without pro plan" do
    login(users(:admin))

    assert_enqueued_with(job: Chat::RespondJob) do
      post create_message_chat_url, params: { content: "Preview a new vegan dinner recipe" }, as: :turbo_stream
    end

    assert_response :success
    conversation = users(:admin).chat_conversations.last
    assert_equal "Preview a new vegan dinner recipe", conversation.messages.where(role: "user").last.content
  end

  test "free user cannot send messages" do
    login(users(:user))
    post create_message_chat_url, params: { content: "test" }
    assert_redirected_to pricing_path
  end
end
