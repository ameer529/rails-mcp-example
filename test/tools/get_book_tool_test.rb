require "test_helper"

class GetBookToolTest < ActiveSupport::TestCase
  test "describes itself" do
    assert_equal "get_book", GetBookTool.name_value
    assert GetBookTool.annotations.read_only_hint
  end

  test "returns a book" do
    response = GetBookTool.call(id: books(:dune).id, server_context: nil)

    assert_not response.error?
    assert_equal "Dune", JSON.parse(response.content.first[:text])["title"]
  end

  test "unknown id is an error response" do
    response = GetBookTool.call(id: 0, server_context: nil)

    assert response.error?
    assert_equal "Book 0 not found", response.content.first[:text]
  end
end
