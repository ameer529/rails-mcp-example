class GetBookTool < MCP::Tool
  tool_name "get_book"
  description "Fetch one book by id."
  input_schema(
    properties: { id: { type: "integer", description: "Book id from search_books" } },
    required: [ "id" ]
  )
  annotations(read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: false)

  def self.call(id:, server_context: nil)
    book = Book.find_by(id:)
    return MCP::Tool::Response.new([ { type: "text", text: "Book #{id} not found" } ], error: true) if book.nil?

    MCP::Tool::Response.new([ { type: "text", text: book.as_tool_hash.to_json } ])
  end
end
