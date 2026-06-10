#!/usr/bin/env bash
set -euo pipefail

echo "Installing Trello MCP skill server..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# Build from the repository root source — the single source of truth. The skill no longer
# bundles a second copy of the server (it inevitably drifted from the real runtime). When
# the skill directory is used standalone (outside the repo), the registry fallback applies.
REPO_ROOT="$(cd "$SKILL_ROOT/.." && pwd)"
SOURCE_DIR="$REPO_ROOT"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
INSTALL_DIR="$DATA_HOME/mcp-server-trello-skill/server"
BUILD_FILE="$INSTALL_DIR/build/index.js"

if [ -d "$SOURCE_DIR/src" ] && [ -f "$SOURCE_DIR/package.json" ] && command -v bun >/dev/null 2>&1; then
  echo "Building server from repository source with Bun..."
  rm -rf "$INSTALL_DIR"
  mkdir -p "$INSTALL_DIR"
  cp -R "$SOURCE_DIR/src" "$INSTALL_DIR/src"
  cp "$SOURCE_DIR/package.json" "$SOURCE_DIR/bun.lock" "$SOURCE_DIR/tsconfig.json" "$INSTALL_DIR/"
  [ -f "$SOURCE_DIR/LICENSE" ] && cp "$SOURCE_DIR/LICENSE" "$INSTALL_DIR/"

  cd "$INSTALL_DIR"
  bun install
  bun run build

  echo "Built server at $BUILD_FILE"
  echo "Configure your MCP client to run: node $BUILD_FILE"
elif command -v npx >/dev/null 2>&1; then
  echo "Bun is not available or repository source is missing."
  echo "Falling back to Smithery install for @delorenj/mcp-server-trello..."
  npx -y @smithery/cli install @delorenj/mcp-server-trello --client claude
  rm -rf "$INSTALL_DIR"
  mkdir -p "$INSTALL_DIR/build"
  cat >"$BUILD_FILE" <<'EOF'
#!/usr/bin/env node
const { spawn } = require('node:child_process');

const child = spawn('npx', ['-y', '@delorenj/mcp-server-trello', ...process.argv.slice(2)], {
  stdio: 'inherit',
  env: process.env,
});

child.on('exit', (code, signal) => {
  if (signal) {
    process.kill(process.pid, signal);
    return;
  }

  process.exit(code ?? 1);
});

child.on('error', (error) => {
  console.error(`Failed to start @delorenj/mcp-server-trello via npx: ${error.message}`);
  process.exit(1);
});
EOF
  chmod +x "$BUILD_FILE"
  echo "Created registry fallback wrapper at $BUILD_FILE"
  echo "Configure your MCP client to run: node $BUILD_FILE"
else
  echo "Unable to install: Bun is required for bundled builds, or npx is required for the registry fallback." >&2
  exit 1
fi

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
