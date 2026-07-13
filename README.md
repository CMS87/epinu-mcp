# Epinu MCP — agent door for a real-world industrial marketplace

[![MCP endpoint liveness](https://github.com/CMS87/epinu-mcp/actions/workflows/liveness.yml/badge.svg)](https://github.com/CMS87/epinu-mcp/actions/workflows/liveness.yml)

[Epinu](https://epinu.ai) is an **agent-first marketplace for real-world industrial
assets** — ASIC repair services, mining and energy equipment, and livestock
*medianería* collaborations. AI agents are first-class users: they can search,
read, and draft deals directly over MCP, and **every write goes through a
human-approval broker** with a full audit trail.

This is the **public integration repository** for Epinu's hosted MCP endpoint:
registry metadata ([`ai.epinu/epinu`](https://registry.modelcontextprotocol.io/v0/servers?search=epinu)
in the official MCP Registry), runnable examples, and operational checks.
The Epinu platform implementation is maintained separately.

- **Endpoint:** `https://api.epinu.ai/api/agent/mcp` (Streamable HTTP, JSON-RPC 2.0)
- **Live docs for agents:** [epinu.ai/llms.txt](https://epinu.ai/llms.txt)
- **Manifest:** [epinu.ai/.well-known/mcp](https://epinu.ai/.well-known/mcp)

## Try it in 60 seconds — no account, no token

```bash
bash examples/quickstart.sh
```

That queries the **live public production endpoint** anonymously —
listings like dielectric safety gloves in Caracas, an ASIC repair center in
Odessa TX, hashboard diagnosis services. (The catalog is early-stage and may
still include demonstration records.) The anonymous tier allows
`initialize`, `tools/list`, and three read tools (`getting_started`,
`marketplace_listings_search`, `projects_search`) against public data —
see [TOOLS.md](TOOLS.md) for the reference.

Or the same flow in plain Node (zero dependencies, Node ≥ 18):

```bash
node examples/walkthrough.mjs
```

## Connect from Claude Code / any MCP client

```bash
claude mcp add --transport http epinu https://api.epinu.ai/api/agent/mcp
```

or in `.mcp.json`:

```json
{
  "mcpServers": {
    "epinu": {
      "type": "http",
      "url": "https://api.epinu.ai/api/agent/mcp"
    }
  }
}
```

Works immediately in read-only mode. To let your agent draft deals, add
`"headers": {"Authorization": "Bearer epagt_..."}` with a delegated token —
see below for how to get one. Details in [examples/claude-code.md](examples/claude-code.md).

## The interesting part: writes never execute

Epinu's write tools (`marketplace_listing_create`, `project_create`, …) do
**not** write to the database. They create **proposals** (`status: pending`)
and return an `approval_url`. A human reviews the proposal in the Epinu
dashboard and approves or rejects it — only approval executes the change.

[`examples/walkthrough.mjs`](examples/walkthrough.mjs) demonstrates the
agent-controlled portion of the flow: search → create a pending proposal →
check its status. Human approval happens separately in the Epinu dashboard.
[`examples/walkthrough.md`](examples/walkthrough.md) is the recorded,
redacted transcript of a real production run — proposal created, reviewed,
and rejected by the human, with nothing ever written.

### Why is every write human-approved?

- **Agents make mistakes; markets are real.** A hallucinated listing, a wrong
  price, or a duplicate is cheap to reject at proposal time and expensive to
  unwind after it's live. The broker makes the failure mode "a human clicked
  reject", not "a bad write hit production".
- **Identity and audit.** Every proposal records `actor.type=personal_agent`
  and the agent's client id. The human always knows *which* agent proposed
  *what*, and the trail survives.
- **Scoped delegation, not account takeover.** An `epagt_` token is created by
  the account owner with explicit scopes (Dashboard → Settings → Authorize
  Agent). Out-of-scope calls fail with a clean scope error. Sensitive actions
  (deletes, profile changes) additionally require fresh MFA on the human side
  at approval time.
- **Drift checks.** If the underlying data changed materially between proposal
  and approval, approval is blocked or requires explicit acknowledgment — an
  agent can't get a stale change approved.
- Unapproved proposals expire on their own (7 days).

**Production experience:** Epinu reports that its first external marketplace
participant was onboarded through a delegated AI agent: the agent prepared the
catalog proposals, and the account owner reviewed and approved them in the
dashboard. A sanitized case study is forthcoming.

## Getting a token (for writes)

1. Create an account at [epinu.ai/signup](https://epinu.ai/signup)
2. Dashboard → **Settings → Authorize Agent** → choose scopes → copy the
   `epagt_` token, or send your agent's human to
   `https://epinu.ai/authorize-agent?name=<AgentName>&scopes=<scopes>`
3. Use it as `Authorization: Bearer epagt_...` on `POST /api/agent/mcp`
   (the token is valid on the MCP endpoint only)

## What's in this repo

| File | What it is |
| --- | --- |
| [`server.json`](server.json) | The MCP Registry entry for `ai.epinu/epinu` |
| [`examples/quickstart.sh`](examples/quickstart.sh) | Anonymous tier in 60 seconds (curl) |
| [`examples/walkthrough.mjs`](examples/walkthrough.mjs) | Search → create pending proposal → check proposal status (Node, zero deps) |
| [`examples/walkthrough.md`](examples/walkthrough.md) | Recorded, redacted transcript of a real production run |
| [`examples/claude-code.md`](examples/claude-code.md) | Connect from Claude Code / `.mcp.json` |
| [`TOOLS.md`](TOOLS.md) | Anonymous-tier tool reference with captured responses |
| [`SECURITY.md`](SECURITY.md) | How to report a vulnerability |

The canonical, always-current agent documentation lives on the site itself:
[llms.txt](https://epinu.ai/llms.txt) ·
[.well-known/mcp](https://epinu.ai/.well-known/mcp). This repo deliberately
links rather than mirrors, so it can't go stale.

## License

Examples and docs in this repository: [MIT](LICENSE).
The Epinu platform itself is a hosted service — [epinu.ai](https://epinu.ai).
