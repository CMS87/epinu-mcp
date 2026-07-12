#!/usr/bin/env bash
# Epinu MCP quickstart — live marketplace data in under 60 seconds, zero credentials.
#
# The Epinu agent door has an anonymous read tier: initialize, tools/list,
# getting_started, marketplace_listings_search, and projects_search work
# without any token. Everything below hits the LIVE production endpoint.
#
#   bash examples/quickstart.sh
#
# Requires: curl, python3 (for pretty-printing only).
set -euo pipefail

MCP=${EPINU_MCP_URL:-https://api.epinu.ai/api/agent/mcp}

rpc() {
  curl -sS --max-time 30 -X POST "$MCP" \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json, text/event-stream' \
    -d "$1"
}

pretty() { python3 -m json.tool 2>/dev/null || cat; }

# Unwrap an MCP tools/call result: content[0].text is a JSON string.
tool_text() {
  python3 -c 'import json,sys; print(json.dumps(json.loads(json.load(sys.stdin)["result"]["content"][0]["text"]), indent=2))'
}

echo '── 1. initialize ──────────────────────────────────────────────'
rpc '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"epinu-quickstart","version":"1.0.0"}}}' | pretty

echo
echo '── 2. tools/list (anonymous tier) ─────────────────────────────'
rpc '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' \
  | python3 -c 'import json,sys; [print(" -", t["name"], "—", t.get("description","")[:80]) for t in json.load(sys.stdin)["result"]["tools"]]'

echo
echo '── 3. marketplace_listings_search — real industrial inventory ─'
rpc '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"marketplace_listings_search","arguments":{"query":"ASIC repair"}}}' | tool_text

echo
echo '── 4. projects_search ─────────────────────────────────────────'
rpc '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"projects_search","arguments":{"query":"mining"}}}' | tool_text

echo
echo '── 5. getting_started — the full onboarding for agents ────────'
rpc '{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"getting_started","arguments":{}}}' | tool_text

echo
echo 'Done. Writes require a delegated token (epagt_*) and ALWAYS go through'
echo 'human approval — see examples/walkthrough.md for the full propose→approve flow.'
