# Connect to Epinu from Claude Code

## One command

```bash
claude mcp add --transport http epinu https://api.epinu.ai/api/agent/mcp
```

That's it for read-only: `initialize`, `tools/list`, `getting_started`,
`marketplace_listings_search`, `projects_search`, `search`, and `fetch` work
with no credentials.

Then just ask:

> search epinu for ASIC repair services in Texas

## With a delegated token (lets your agent draft deals)

1. Create an account at <https://epinu.ai/signup>
2. Dashboard → **Settings → Authorize Agent** → pick scopes → copy the `epagt_` token
3. Add the server with the header:

```bash
claude mcp add --transport http epinu https://api.epinu.ai/api/agent/mcp \
  --header "Authorization: Bearer epagt_YOUR_TOKEN"
```

## `.mcp.json` (project-scoped, checked in — WITHOUT the token)

```json
{
  "mcpServers": {
    "epinu": {
      "type": "http",
      "url": "https://api.epinu.ai/api/agent/mcp",
      "headers": {
        "Authorization": "Bearer ${EPINU_AGENT_TOKEN}"
      }
    }
  }
}
```

`${EPINU_AGENT_TOKEN}` expands from your environment, so the token never
lands in the file. Omit the `headers` block entirely for anonymous reads.

## What your agent can and cannot do

Reads return data directly. **Writes never execute** — they create proposals
you approve or reject in the Epinu dashboard (each proposal response includes
its `approval_url`). Deletes and other sensitive actions additionally require
a fresh sign-in at approval time. See the [README](../README.md) for the full
broker model.
