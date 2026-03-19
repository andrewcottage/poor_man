class ChatController < ApplicationController
  def show
    if Current.user&.pro?
      @conversation = Current.user.chat_conversations.first_or_create!
      @messages = @conversation.messages.visible.chronological
    end
  end

  def create_message
    unless Current.user
      session[:return_to] = chat_path
      redirect_to new_session_path, alert: "Sign in to start chatting about recipes.", status: :see_other
      return
    end

    unless Current.user.pro?
      redirect_to pricing_path, alert: "Upgrade to #{Billing::PlanCatalog::PRO_DISPLAY_NAME} to use Recipe Chat.", status: :see_other
      return
    end

    @conversation = Current.user.chat_conversations.first_or_create!
    @message = @conversation.messages.create!(role: "user", content: params[:content])

    Chat::RespondJob.perform_later(@conversation)

    respond_to do |format|
      format.turbo_stream
    end
  end
end
