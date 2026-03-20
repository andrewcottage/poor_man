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

    @conversation = selected_conversation || Current.user.chat_conversations.recent_first.first || Current.user.chat_conversations.create!
    @message = @conversation.messages.create!(role: "user", content: params[:content])
    @conversation.assign_title_from!(params[:content]) if @conversation.title.blank?
    @conversations = Current.user.chat_conversations.includes(:messages).recent_first

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

  def update_conversation
    require_user!
    return if performed?

    conversation = Current.user.chat_conversations.find(params[:conversation_id])
    title = params[:title].to_s.squish

    if title.blank?
      redirect_to chat_conversation_path(conversation), alert: "Chat title can't be blank.", status: :see_other
      return
    end

    conversation.update!(title: title)
    redirect_to chat_conversation_path(conversation), notice: "Chat renamed.", status: :see_other
  end

  def destroy_conversation
    require_user!
    return if performed?

    conversation = Current.user.chat_conversations.find(params[:conversation_id])
    fallback_conversation = Current.user.chat_conversations.where.not(id: conversation.id).recent_first.first
    conversation.destroy!

    destination = fallback_conversation ? chat_conversation_path(fallback_conversation) : chat_path
    redirect_to destination, notice: "Chat deleted.", status: :see_other
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
