# rails-mcp-example

A small Rails app that exposes part of its data to AI agents through the [Model Context Protocol](https://modelcontextprotocol.io). It uses the official [`mcp`](https://github.com/modelcontextprotocol/ruby-sdk) Ruby gem, serves MCP over plain HTTP from one controller, and protects the endpoint with a bearer token.

The domain is a `books` table with ten public domain titles. Two read-only tools are exposed:

| Tool | Input | What it returns |
| --- | --- | --- |
| `search_books` | `query` (string), `limit` (integer, 1 to 50, default 10) | matching books by title or author, ordered by title |
| `get_book` | `id` (integer) | one book, or a tool error when the id does not exist |

## Run it

Ruby 3.4 or newer. The repo pins 4.0.6 in `.ruby-version`.

```sh
bin/setup --skip-server
bin/rails db:seed
MCP_TOKEN=change-me bin/rails server
```

The MCP endpoint is now at `http://localhost:3000/mcp`. Every request needs `Authorization: Bearer <MCP_TOKEN>`. If `MCP_TOKEN` is not set, every request is refused.

## Try it with curl

MCP over HTTP expects an `Accept` header that allows both JSON and event streams.

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
{"jsonrpc":"2.0","id":3,"result":{"content":[{"type":"text","text":"{\"books\":[{\"id\":1,\"title\":\"Pride and Prejudice\",\"author\":\"Jane Austen\",\"year\":1813,\"summary\":\"Elizabeth Bennet, Mr Darcy, and the cost of first impressions.\"}]}"}],"isError":false}}
```

## Connect an agent

Claude Code:

```sh
claude mcp add --transport http books http://localhost:3000/mcp --header "Authorization: Bearer change-me"
```

Then ask it something like "which books in the library are from before 1850?" and it will call `search_books` and `get_book` on its own. Any MCP client that speaks Streamable HTTP works the same way, for example the [MCP Inspector](https://modelcontextprotocol.io/docs/tools/inspector).

## How it works

- `app/controllers/mcp_controller.rb` builds an `MCP::Server` per request with the two tool classes and hands the Rack request to the gem's `StreamableHTTPTransport`. The transport runs in stateless JSON mode: no sessions, no server sent events, one JSON reply per POST. That keeps the controller stateless, so it works behind a load balancer and with several Puma workers.
- `app/tools/` holds one class per tool. Each declares its name, description, JSON schema and annotations (`readOnlyHint: true`), and implements `self.call`. The gem validates arguments against the schema before `call` runs.
- `app/models/book.rb` has the `search` scope. The query goes through `sanitize_sql_like` and an explicit `ESCAPE` clause, so `%` and `_` in user input are matched literally.
- Auth is a `before_action` that compares the bearer token with `ActiveSupport::SecurityUtils.secure_compare`. Unauthorized requests get a 401 before the body is parsed.

## Tests

```sh
bin/ci
```

That runs rubocop, the test suite and a seed check. `bin/rails test` runs just the tests: model, tool and endpoint tests, including the auth failures and the wildcard escaping.

## Before deploying

- Set `config.hosts` in `config/environments/production.rb`. The app relies on Rails host authorization and turns off the transport's own host check, which only allows loopback addresses.
- Serve it over HTTPS. The token travels in a header.
- Rotate `MCP_TOKEN` by restarting with a new value. There is nothing else to invalidate.

## License

MIT, see `LICENSE`.
