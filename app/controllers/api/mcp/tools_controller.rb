class Api::Mcp::ToolsController < Api::BaseController
  def index
    tools = StovaroServer.tools_for(user: Current.user)

    render json: {
      instructions: StovaroServer::INSTRUCTIONS,
      tools: tools.map(&:to_h)
    }
  end

  def create
    tool = StovaroServer.find_tool(name: params[:tool_name], user: Current.user)

    unless tool
      return render json: { error: "Tool not found" }, status: :not_found
    end

    body = request.raw_post.presence || "{}"
    kwargs = JSON.parse(body).symbolize_keys
    kwargs[:server_context] = { user: Current.user }
    result = tool.call(**kwargs)

    render json: result.to_h
  end
end
