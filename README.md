# rails-mcp-example

A small Rails app that exposes part of its data to AI agents through the [Model Context Protocol](https://modelcontextprotocol.io). It uses the official [`mcp`](https://github.com/modelcontextprotocol/ruby-sdk) Ruby gem, serves MCP over plain HTTP from one controller, and protects the endpoint with a bearer token.

The domain is a `books` table with ten public domain titles. Two read-only tools are exposed:

| Tool | Input | What it returns |
| --- | --- | --- |
| `search_books` | `query` (string), `limit` (integer, 1 to 50, default 10) | id, title, author and year of matching books, by title or author, ordered by title |
| `get_book` | `id` (integer) | the same fields plus the summary, or a tool error when the id does not exist |

## Run it

Rails 8.1 needs Ruby 3.2 or newer. The repo was built and tested on 4.0.6, pinned in `.ruby-version`.

```sh
bin/setup --skip-server
MCP_TOKEN=change-me bin/rails server
```

`bin/setup` installs gems, creates the SQLite database and loads the ten seed books.

The MCP endpoint is now at `http://localhost:3000/mcp`. Every request needs `Authorization: Bearer <MCP_TOKEN>`. If `MCP_TOKEN` is not set, every request is refused.

## Try it with curl

MCP clients send an `Accept` header listing both JSON and event streams, so the examples do too. This server always answers plain JSON. `--json` needs curl 7.82 or newer.

```sh
MCP=http://localhost:3000/mcp
AUTH="Authorization: Bearer change-me"
ACCEPT="Accept: application/json, text/event-stream"

curl $MCP -H "$AUTH" -H "$ACCEPT" --json '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"curl","version":"1.0"}}}'

curl $MCP -H "$AUTH" -H "$ACCEPT" --json '{"jsonrpc":"2.0","id":2,"method":"tools/list"}'

curl $MCP -H "$AUTH" -H "$ACCEPT" --json '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"search_books","arguments":{"query":"austen"}}}'
```

The last call answers with:

```json
{"jsonrpc":"2.0","id":3,"result":{"content":[{"type":"text","text":"{\"books\":[{\"id\":1,\"title\":\"Pride and Prejudice\",\"author\":\"Jane Austen\",\"year\":1813}]}"}],"isError":false}}
```

## Connect an agent

Claude Code:

```sh
claude mcp add --transport http books http://localhost:3000/mcp --header "Authorization: Bearer change-me"
```

Then ask it "find the Austen book in the library and tell me what it is about". It calls `search_books` for the id and `get_book` for the summary. Any MCP client that speaks Streamable HTTP works the same way, for example the [MCP Inspector](https://modelcontextprotocol.io/docs/tools/inspector).

## How it works

- `app/controllers/mcp_controller.rb` builds an `MCP::Server` per request with the two tool classes and hands the Rack request to the gem's `StreamableHTTPTransport`. The transport runs in stateless JSON mode: no sessions, no server sent events, one JSON reply per POST. The Rack response it returns is passed through as-is, so a notification gets the empty 202 the spec asks for and a GET gets a 405. Stateless means it works behind a load balancer and with several Puma workers.
- `app/tools/` holds one class per tool. Each declares its name, description, JSON schema and annotations (`readOnlyHint: true`), and implements `self.call`. The gem validates arguments against the schema before `call` runs.
- `app/models/book.rb` has the `search` scope. The query goes through `sanitize_sql_like` and an explicit `ESCAPE` clause, so `%` and `_` in user input are matched literally.
- Auth is a `before_action` that compares the bearer token with `ActiveSupport::SecurityUtils.secure_compare`. Unauthorized requests get a 401 before the request reaches the transport. Rails still parses the JSON body for its own params, as it does for every request.

## Tests

```sh
bin/ci
```

That runs rubocop, the test suite and a seed check. `bin/rails test` runs just the tests: model, tool and endpoint tests, including the auth failures and the wildcard escaping.

## Before deploying

- Set `config.hosts` in `config/environments/production.rb`. The app relies on Rails host authorization and turns off the transport's own host check, which only allows loopback addresses.
- Point `DATABASE_PATH` at a persistent disk. SQLite writes to the local filesystem.
- Serve it over HTTPS. The token travels in a header.
- Rotate `MCP_TOKEN` by restarting with a new value. There is nothing else to invalidate.

## License

MIT, see `LICENSE`.
