#!/usr/bin/env bash
set -euo pipefail

echo "Installing Trello MCP skill server..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# Build from a full clone of this repository — the single source of truth. The skill does
# not bundle a second copy of the server (it inevitably drifted from the real runtime), and
# there is deliberately NO registry fallback: the published @delorenj/mcp-server-trello
# package is the upstream server without this fork's tool profiles and access blocklists,
# and pulling unpinned registry code into a process that holds TRELLO_API_KEY/TRELLO_TOKEN
# would bypass both review pinning and the documented access-control behavior.
#
# Source resolution order:
#   1. TRELLO_MCP_SOURCE_REPO — explicit path to a clone. Required when the skill
#      directory was copied standalone into an agent skills directory.
#   2. The skill's parent directory — covers running from inside the repo itself.
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
INSTALL_DIR="$DATA_HOME/mcp-server-trello-skill/server"
BUILD_FILE="$INSTALL_DIR/build/index.js"

is_server_repo() {
  [ -d "$1/src" ] && [ -f "$1/package.json" ] && [ -f "$1/bun.lock" ] \
    && grep -q '"@delorenj/mcp-server-trello"' "$1/package.json"
}

SOURCE_DIR="${TRELLO_MCP_SOURCE_REPO:-$(cd "$SKILL_ROOT/.." && pwd)}"
if ! is_server_repo "$SOURCE_DIR"; then
  echo "Unable to install: no server source at '$SOURCE_DIR'." >&2
  echo "This skill builds from a full clone of mot-group/mcp-server-trello. Either run it" >&2
  echo "from inside the repository, or clone it and point the installer at the clone:" >&2
  echo "  git clone https://github.com/mot-group/mcp-server-trello.git" >&2
  echo "  TRELLO_MCP_SOURCE_REPO=/path/to/mcp-server-trello bash $SCRIPT_DIR/install.sh" >&2
  exit 1
fi

if ! command -v bun >/dev/null 2>&1; then
  echo "Unable to install: Bun is required to build the server (https://bun.sh)." >&2
  exit 1
fi

echo "Building server from repository source with Bun..."
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cp -R "$SOURCE_DIR/src" "$INSTALL_DIR/src"
cp "$SOURCE_DIR/package.json" "$SOURCE_DIR/bun.lock" "$SOURCE_DIR/tsconfig.json" "$INSTALL_DIR/"
[ -f "$SOURCE_DIR/LICENSE" ] && cp "$SOURCE_DIR/LICENSE" "$INSTALL_DIR/"

cd "$INSTALL_DIR"
bun install --frozen-lockfile --ignore-scripts
bun run build

echo "Built server at $BUILD_FILE"
echo "Configure your MCP client to run: node $BUILD_FILE"

cat <<'MSG'

Required MCP environment variables:
  TRELLO_API_KEY
  TRELLO_TOKEN

Optional:
  TRELLO_BOARD_ID
  TRELLO_WORKSPACE_ID
  TRELLO_BLOCKED_WORKSPACES   (comma-separated IDs to deny; access is open by default)
  TRELLO_BLOCKED_BOARDS       (comma-separated IDs to deny; access is open by default)
  https_proxy or HTTPS_PROXY

Note: the legacy TRELLO_ALLOWED_WORKSPACES / TRELLO_ALLOWED_BOARDS variables are no
longer supported; the server fails fast at startup if they are set.

MSG
