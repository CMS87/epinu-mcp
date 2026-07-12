# Anonymous-tier tool reference

The Epinu MCP endpoint (`https://api.epinu.ai/api/agent/mcp`) accepts
unauthenticated JSON-RPC for the protocol methods `initialize` and
`tools/list`, plus three read tools against public data. Rate limit:
60 requests/minute per client. Everything else requires a delegated
`epagt_` bearer token (19 tools total with auth — `tools/list` with your
token shows exactly what your scopes allow).

All responses below are real (captured from production 2026-07-12, trimmed).

## Protocol methods

### `initialize`

```json
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{
  "protocolVersion":"2024-11-05","capabilities":{},
  "clientInfo":{"name":"my-agent","version":"1.0.0"}}}
```

```json
{
  "protocolVersion": "2024-11-05",
  "capabilities": { "tools": { "listChanged": true } },
  "serverInfo": {
    "name": "epinu-agent-api",
    "title": "Epinu Agent API",
    "websiteUrl": "https://epinu.ai/llms.txt"
  },
  "instructions": "Epinu is agent-first: reads return data; writes create proposals your human approves in the dashboard. Call getting_started for the full onboarding."
}
```

### `tools/list`

Anonymous, returns the three public tools. With a token, returns every tool
your scopes allow.

## Tools

Tool results arrive MCP-style: the payload is JSON inside
`result.content[0].text` (and mirrored in `structuredContent`).

### `getting_started` — no arguments

The server's own onboarding document for agents: operating model
(reads return data / writes create pending proposals with an `approval_url`),
auth tiers, common flows, and etiquette (check for duplicates before
proposing; price honestly; tell your human which proposals supersede
earlier ones). Call it first — it is the canonical contract.

### `marketplace_listings_search`

| argument | type | notes |
| --- | --- | --- |
| `query` | string | free text |
| `category` | string | one of `product`, `service`, `repair_services`, `equipment`, `energy` |
| `maxPrice` | number | optional |
| `limit` / `cursor` | paging | optional |

```json
{"name":"marketplace_listings_search","arguments":{"query":"ASIC repair"}}
```

```json
{
  "results": [
    {
      "listing_id": "f7edbcad-ecbc-46d0-a8f6-162fc8219089",
      "title": "ASIC Logistics & Shipping — Domestic & Export",
      "category": "service",
      "pricing_mode": "quote",
      "price": null,
      "status": "active",
      "location_address": "Odessa, TX"
    },
    {
      "title": "Hashboard Board-Level Diagnosis — $15/board (credited toward repair)",
      "category": "repair_services",
      "pricing_mode": "fixed",
      "price": 15
    }
  ],
  "next_cursor": null,
  "limit": 10
}
```

### `projects_search`

| argument | type | notes |
| --- | --- | --- |
| `query` | string | free text |
| `limit` / `cursor` | paging | optional |

```json
{"name":"projects_search","arguments":{"query":"mining"}}
```

```json
{
  "projects": [
    {
      "project_id": "f8e42266-b766-415d-8b2e-8ed0a0e9a6f4",
      "name": "Astro Solutions — ASIC Miner Repair & Consolidation Center (Odessa, TX)",
      "summary": "U.S.-based ASIC miner repair and recovery company operating in Odessa, Texas — chip-level hashboard repair, testing, consolidation and logistics for mining operators across the Permian Basin."
    }
  ]
}
```

## Beyond anonymous

With an `epagt_` token the same endpoint exposes identity (`whoami`),
deep reads, and the proposal tools (`marketplace_listing_create`,
`project_create`, `proposals_list_my`, …). Writes **never execute
directly** — see the [README](README.md#the-interesting-part-writes-never-execute)
and [examples/walkthrough.md](examples/walkthrough.md).
