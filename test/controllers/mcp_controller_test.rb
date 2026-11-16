require "test_helper"

class McpControllerTest < ActionDispatch::IntegrationTest
  test "missing token is rejected" do
    post "/mcp", params: rpc("tools/list").to_json, headers: headers.except("Authorization")

    assert_response :unauthorized
    assert_equal({ "error" => "unauthorized" }, response.parsed_body)
  end

  test "wrong token is rejected" do
    post "/mcp", params: rpc("tools/list").to_json, headers: headers.merge("Authorization" => "Bearer nope")

    assert_response :unauthorized
  end

  test "initialize returns server info" do
    post "/mcp", params: rpc("initialize", protocolVersion: "2025-11-25", capabilities: {}, clientInfo: { name: "test", version: "1" }).to_json, headers: headers

    assert_response :success
    assert_equal "rails-mcp-example", response.parsed_body.dig("result", "serverInfo", "name")
  end

  test "tools/list lists both tools" do
    post "/mcp", params: rpc("tools/list").to_json, headers: headers

    assert_response :success
    assert_equal %w[get_book search_books], response.parsed_body.dig("result", "tools").map { |t| t["name"] }.sort
  end

  test "tools/call search_books returns matches" do
    post "/mcp", params: rpc("tools/call", name: "search_books", arguments: { query: "dune" }).to_json, headers: headers

    assert_response :success
    result = response.parsed_body["result"]
    assert_not result["isError"]
    assert_equal [ "Dune" ], JSON.parse(result.dig("content", 0, "text"))["books"].map { |b| b["title"] }
  end

  test "tools/call get_book with unknown id has isError true" do
    post "/mcp", params: rpc("tools/call", name: "get_book", arguments: { id: 0 }).to_json, headers: headers

    assert_response :success
    assert response.parsed_body.dig("result", "isError")
  end

  private

  def rpc(method, **params)
    { jsonrpc: "2.0", id: 1, method:, params: }
  end

  def headers
    {
      "Authorization" => "Bearer test-token",
      "Content-Type" => "application/json",
      "Accept" => "application/json, text/event-stream"
    }
  end
end
