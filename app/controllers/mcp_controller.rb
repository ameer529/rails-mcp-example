class McpController < ApplicationController
  TOOLS = [ SearchBooksTool, GetBookTool ].freeze

  wrap_parameters false
  before_action :authenticate

  def handle
    server = MCP::Server.new(name: "rails-mcp-example", version: "1.0.0", tools: TOOLS, capabilities: { tools: {} })
    transport = MCP::Server::Transports::StreamableHTTPTransport.new(
      server,
      stateless: true,
      enable_json_response: true,
      serve_subscriptions_listen: false,
      dns_rebinding_protection: false
    )
    status, headers, body = transport.handle_request(request)

    self.status = status
    response.headers.merge!(headers)
    self.response_body = body
  end

  private

  def authenticate
    expected = ENV.fetch("MCP_TOKEN", "")
    given = request.authorization.to_s[/\ABearer (.+)\z/i, 1].to_s
    return if expected.present? && ActiveSupport::SecurityUtils.secure_compare(given, expected)

    render json: { error: "unauthorized" }, status: :unauthorized
  end
end
