class ChatController < ApplicationController
  def show
    if chat_enabled_for?(Current.user)
      @conversations = Current.user.chat_conversations.includes(:messages).recent_first
      @conversation = selected_conversation || @conversations.first || Current.user.chat_conversations.create!
      @messages = @conversation.messages.visible.chronological
    end
  end

  def create_message
    unless Current.user
      session[:return_to] = chat_path
      redirect_to new_session_path, alert: "Sign in to start chatting about recipes.", status: :see_other
      return
    end

    unless chat_enabled_for?(Current.user)
      redirect_to pricing_path, alert: "Upgrade to #{Billing::PlanCatalog::PRO_DISPLAY_NAME} to use Recipe Chat.", status: :see_other
      return
    end

    @conversations = Current.user.chat_conversations.includes(:messages).recent_first
    @conversation = selected_conversation || @conversations.first || Current.user.chat_conversations.create!
    @message = @conversation.messages.create!(role: "user", content: params[:content])
    @conversation.assign_title_from!(params[:content]) if @conversation.title.blank?

    Chat::RespondJob.perform_later(@conversation)

    respond_to do |format|
      format.turbo_stream
    end
  end

  def create_conversation
    unless Current.user
      session[:return_to] = chat_path
      redirect_to new_session_path, alert: "Sign in to start chatting about recipes.", status: :see_other
      return
    end

    unless chat_enabled_for?(Current.user)
      redirect_to pricing_path, alert: "Upgrade to #{Billing::PlanCatalog::PRO_DISPLAY_NAME} to use Recipe Chat.", status: :see_other
      return
    end

    conversation = Current.user.chat_conversations.create!
    redirect_to chat_conversation_path(conversation), notice: "Started a new chat.", status: :see_other
  end

  private

  def chat_enabled_for?(user)
    user&.pro? || user&.admin?
  end

  def selected_conversation
    return unless params[:conversation_id].present?

    Current.user.chat_conversations.find_by(id: params[:conversation_id])
  end
end
