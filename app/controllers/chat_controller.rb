class ChatController < ApplicationController
  before_action :require_user!

  def show
    if Current.user.pro?
      @conversation = Current.user.chat_conversations.first_or_create!
      @messages = @conversation.messages.visible.chronological
    end
  end

  def create_message
    unless Current.user.pro?
      redirect_to pricing_path, alert: "Upgrade to #{Billing::PlanCatalog::PRO_DISPLAY_NAME} to use Recipe Chat."
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
