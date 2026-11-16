class McpController < ApplicationController
  TOOLS = [ SearchBooksTool, GetBookTool ].freeze

  before_action :authenticate

  def create
    server = MCP::Server.new(name: "rails-mcp-example", version: "1.0.0", tools: TOOLS)
    transport = MCP::Server::Transports::StreamableHTTPTransport.new(
      server,
      stateless: true,
      enable_json_response: true,
      serve_subscriptions_listen: false,
      dns_rebinding_protection: false
    )
    status, headers, body = transport.handle_request(request)

    render json: body.first, status:, headers:
  end

  private

  def authenticate
    expected = ENV.fetch("MCP_TOKEN", "")
    given = request.authorization.to_s.delete_prefix("Bearer ")
    return if expected.present? && ActiveSupport::SecurityUtils.secure_compare(given, expected)

    render json: { error: "unauthorized" }, status: :unauthorized
  end
end
