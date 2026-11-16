require "test_helper"

class SearchBooksToolTest < ActiveSupport::TestCase
  test "describes itself" do
    assert_equal "search_books", SearchBooksTool.name_value
    assert SearchBooksTool.annotations.read_only_hint
  end

  test "returns matching books as json" do
    response = SearchBooksTool.call(query: "ruby", server_context: nil)

    assert_not response.error?
    books = JSON.parse(response.content.first[:text])["books"]
    assert_equal [ "Programming Ruby" ], books.map { |b| b["title"] }
    assert_equal %w[id title author year summary], books.first.keys
  end

  test "returns an empty list when nothing matches" do
    response = SearchBooksTool.call(query: "zzz", server_context: nil)

    assert_equal [], JSON.parse(response.content.first[:text])["books"]
  end

  test "clamps limit" do
    60.times { |i| Book.create!(title: "Clamp #{i.to_s.rjust(2, "0")}", author: "Someone") }

    assert_equal 50, books_for(limit: 500).size
    assert_equal 1, books_for(limit: 0).size
    assert_equal 10, books_for.size
  end

  private

  def books_for(**args)
    JSON.parse(SearchBooksTool.call(query: "clamp", server_context: nil, **args).content.first[:text])["books"]
  end
end
