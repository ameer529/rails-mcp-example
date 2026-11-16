class SearchBooksTool < MCP::Tool
  DEFAULT_LIMIT = 10
  MAX_LIMIT = 50

  tool_name "search_books"
  description "Search books by title or author. Returns id, title, author and year for up to `limit` matches, ordered by title. Use get_book for the summary."
  input_schema(
    properties: {
      query: { type: "string", description: "Text to look for in the title or author" },
      limit: { type: "integer", description: "Max results, 1 to #{MAX_LIMIT}, default #{DEFAULT_LIMIT}" }
    },
    required: [ "query" ]
  )
  annotations(read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: false)

  def self.call(query:, limit: DEFAULT_LIMIT, server_context: nil)
    books = Book.search(query).limit(limit.clamp(1, MAX_LIMIT)).map(&:to_listing)

    MCP::Tool::Response.new([ { type: "text", text: { books: }.to_json } ])
  end
end
