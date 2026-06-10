# Configuration

The skill installs the Trello MCP server locally on first use, building it from
the repository's root source. The server communicates over MCP stdio and
requires Trello API credentials.

## Install

Run the installer from the skill root.

```bash
bash {skill-root}/scripts/install.sh
```

The installer copies the repository's `src/` plus build manifests to
`{XDG_DATA_HOME:-$HOME/.local/share}/mcp-server-trello-skill/server`, installs
dependencies with `bun install --frozen-lockfile --ignore-scripts`, and builds
`build/index.js`. It requires Bun and a full repository clone, and fails fast
otherwise — there is deliberately no registry fallback, because the published
package is the upstream server without this fork's tool profiles and access
blocklists, and unpinned registry code must not run with Trello credentials in
the environment.

## MCP command

For clients that need a direct command, use the built server path.

```json
{
  "mcpServers": {
    "trello": {
      "command": "node",
      "args": [
        "{XDG_DATA_HOME:-$HOME/.local/share}/mcp-server-trello-skill/server/build/index.js"
      ],
      "env": {
        "TRELLO_API_KEY": "your-api-key",
        "TRELLO_TOKEN": "your-token"
      }
    }
  }
}
```

Expand `{XDG_DATA_HOME:-$HOME/.local/share}` before adding the command to a
client configuration.

## Environment variables

- `TRELLO_API_KEY`: Required Trello API key.
- `TRELLO_TOKEN`: Required Trello token for the Trello account.
- `TRELLO_BOARD_ID`: Optional initial board ID.
- `TRELLO_WORKSPACE_ID`: Optional initial workspace ID.
- `TRELLO_BLOCKED_WORKSPACES`: Optional comma-separated workspace IDs to deny.
  Access is open by default.
- `TRELLO_BLOCKED_BOARDS`: Optional comma-separated board IDs to deny. Access
  is open by default.
- `https_proxy` or `HTTPS_PROXY`: Optional HTTPS proxy for restricted networks.

The legacy `TRELLO_ALLOWED_WORKSPACES` / `TRELLO_ALLOWED_BOARDS` allowlist
variables are no longer supported; the server fails fast at startup if they are
set.

Get the API key from `https://trello.com/app-key`, then generate a token from
that key page.

## Build artifacts

The install script writes generated runtime files under the user data directory,
not inside the skill. The source of truth is the repository's root `src/` — the
skill intentionally does not bundle a second copy of the server source.
