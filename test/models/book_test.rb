require "test_helper"

class BookTest < ActiveSupport::TestCase
  test "search matches title and author case insensitively" do
    assert_equal [ books(:ruby) ], Book.search("RUBY").to_a
    assert_equal [ books(:dune) ], Book.search("herbert").to_a
  end

  test "search escapes like wildcards" do
    assert_equal [ books(:rails) ], Book.search("100%").to_a
    assert_equal [ books(:rails) ], Book.search("%").to_a
    assert_empty Book.search("_").to_a
  end

  test "search orders by title" do
    assert_equal [ "100% Rails", "Dune", "Programming Ruby" ], Book.search("r").map(&:title)
  end

  test "as_tool_hash has the five keys" do
    hash = books(:dune).as_tool_hash
    assert_equal %i[id title author year summary], hash.keys
    assert_equal "Dune", hash[:title]
  end

  test "title and author are required" do
    assert_not Book.new(title: "", author: "x").valid?
    assert_not Book.new(title: "x", author: "").valid?
  end
end
