#!/usr/bin/env bash
# Epinu MCP quickstart — live marketplace data in under 60 seconds, zero credentials.
#
# The Epinu agent door has an anonymous read tier: initialize, tools/list,
# getting_started, marketplace_listings_search, projects_search, search, and
# fetch work without any token. Everything below hits the LIVE production endpoint.
#
#   bash examples/quickstart.sh
#
# Requires: curl, python3 (for response handling).
set -euo pipefail

MCP=${EPINU_MCP_URL:-https://api.epinu.ai/api/agent/mcp}

rpc() {
  curl -sS --max-time 30 -X POST "$MCP" \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json, text/event-stream' \
    -d "$1"
}

pretty() { python3 -m json.tool 2>/dev/null || cat; }

# Unwrap an MCP tools/call result. Successful calls contain JSON text; tool
# errors may contain a plain-language message instead.
tool_text() {
  python3 -c '
import json
import sys

response = json.load(sys.stdin)
result = response.get("result")
if result is None:
    print(json.dumps(response, indent=2))
    raise SystemExit(1)

raw = result["content"][0]["text"]
try:
    value = json.loads(raw)
except json.JSONDecodeError:
    value = raw

print(json.dumps(value, indent=2) if not isinstance(value, str) else value)
raise SystemExit(1 if result.get("isError") else 0)
'
}

echo '── 1. initialize ──────────────────────────────────────────────'
rpc '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"epinu-quickstart","version":"1.0.0"}}}' | pretty

echo
echo '── 2. tools/list (anonymous tier) ─────────────────────────────'
rpc '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' \
  | python3 -c 'import json,sys; [print(" -", t["name"], "—", t.get("description","")[:80]) for t in json.load(sys.stdin)["result"]["tools"]]'

echo
echo '── 3. marketplace_listings_search — live public catalog ───────'
rpc '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"marketplace_listings_search","arguments":{"query":"ASIC repair"}}}' | tool_text

echo
echo '── 4. projects_search ─────────────────────────────────────────'
rpc '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"projects_search","arguments":{"query":"mining"}}}' | tool_text

echo
echo '── 5. getting_started — the full onboarding for agents ────────'
rpc '{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"getting_started","arguments":{}}}' | tool_text

echo
echo '── 6. search — unified project + marketplace results ──────────'
SEARCH_RESPONSE=$(rpc '{"jsonrpc":"2.0","id":6,"method":"tools/call","params":{"name":"search","arguments":{"query":"ASIC"}}}')
printf '%s\n' "$SEARCH_RESPONSE" | tool_text
FETCH_ID=$(printf '%s\n' "$SEARCH_RESPONSE" \
  | python3 -c 'import json,sys; payload=json.loads(json.load(sys.stdin)["result"]["content"][0]["text"]); results=payload.get("results", []); print(results[0].get("id", "") if results else "")')

echo
if [[ -n "$FETCH_ID" ]]; then
  echo "── 7. fetch — full document for $FETCH_ID ────────────────────"
  FETCH_CALL=$(python3 -c \
    'import json,sys; print(json.dumps({"jsonrpc":"2.0","id":7,"method":"tools/call","params":{"name":"fetch","arguments":{"id":sys.argv[1]}}}))' \
    "$FETCH_ID")
  rpc "$FETCH_CALL" | tool_text
else
  echo '── 7. fetch — skipped (search returned no current results) ────'
fi

echo
echo 'Done. Writes require a delegated token (epagt_*) and ALWAYS go through'
echo 'human approval — see examples/walkthrough.md for the full propose→approve flow.'
