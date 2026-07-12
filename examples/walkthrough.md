# Walkthrough: an agent proposes, a human approves

This is a **recorded transcript of a real run** of
[`walkthrough.mjs`](walkthrough.mjs) against the live production endpoint —
anonymous leg first, then the propose leg with a delegated `epagt_` token
(2026-07-12; token, account identifiers, and emails redacted). Nothing here
is mocked.

## The read leg (anonymous — run it yourself right now)

```console
$ node examples/walkthrough.mjs

── 1. initialize ───────────────────────────────────────────────
{
  "name": "epinu-agent-api",
  "title": "Epinu Agent API",
  "version": "0.1.0",
  "websiteUrl": "https://epinu.ai/llms.txt"
}
   server says: Epinu is agent-first: reads return data; writes create
   proposals your human approves in the dashboard. Call getting_started
   for the full onboarding.

── 2. duplicate check (marketplace_listings_search) ────────────
{
  "results": 10,
  "titles": [
    "Guante Dieléctrico Ansell Clase 2, 16\" (RIG216Y) | Ansell Class 2 Dielectric Glove, 16\" (RIG216Y)",
    "ASIC Logistics & Shipping — Domestic & Export",
    "Guante de Goma Dieléctrico Clase 4 Ipro, Talla 11 | Ipro Class 4 Dielectric Rubber Glove, Size 11",
    "Hashboard Board-Level Diagnosis — $15/board (credited toward repair)",
    "Sell or Consign Your Miner Fleet"
  ]
}
```

Live public catalog results from the production endpoint, no credentials. Etiquette from `getting_started`: always
check for duplicates *before* proposing a create.

## The propose leg (delegated token) — recorded

With `EPINU_AGENT_TOKEN` set, the same script continues (real output, redacted):

```console
── 3. whoami ───────────────────────────────────────────────────
{
  "owner_user_id": "[REDACTED]",
  "owner_email": "[REDACTED]",
  "agent_client_id": "Ms",
  "scopes": [
    "projects:read",
    "marketplace:read",
    "marketplace:listing:create",
    "..."
  ],
  "constraints": {
    "agent_surface": "personal_agent",
    "approval_required": true,
    "allow_direct_execution": false
  }
}

── 4. marketplace_listing_create → PROPOSAL (not a listing yet!)
{
  "proposalId": "1aeb2574-[REDACTED]",
  "status": "pending",
  "expiresAt": "2026-07-19T22:21:32.260Z",
  "approval_url": "/dashboard/proposals/1aeb2574-[REDACTED]",
  "message": "Marketplace listing proposal created. Awaiting human approval."
}

   >>> Nothing was written. A human must now open:
   >>> /dashboard/proposals/1aeb2574-[REDACTED]
   >>> and approve or reject this proposal in the dashboard.

── 5. proposals_list_my ────────────────────────────────────────
{
  "proposals": [
    {
      "proposalId": "1aeb2574-[REDACTED]",
      "type": "marketplace_listing.create",
      "status": "pending",
      "summary": {
        "diff": {
          "type": "create",
          "fields": [
            { "field": "category",    "before": null, "after": "service" },
            { "field": "title",       "before": null, "after": "Veterinary weigh-in & herd verification visit — medianería record-keeping" },
            { "field": "pricing_mode","before": null, "after": "quote" }
          ]
        }
      }
    }
  ]
}

Done. The proposal stays pending until a human decides (expires in 7 days).
```

Note what the response makes visible: the write became a **pending proposal
with a field-level diff** for the human to review — `allow_direct_execution`
is `false` on the token itself, and the constraint is enforced server-side.

## The approval moment

The proposal shows up in the owner's dashboard with everything the human
needs to decide: what the agent wants to create, every field, which agent
proposed it, and when it expires. One click approves (the listing goes live)
or rejects (nothing ever existed). If the underlying data changed since the
proposal was made, approval is drift-blocked until the human explicitly
acknowledges the change.

```console
── 5. proposals_list_my ────────────────────────────────────────
{
  "proposals": [
    { "status": "pending", "summary": "Create listing: Veterinary weigh-in & herd verification visit …" }
  ]
}
```

After the human approves, the same call reports `"status": "executed"` and
the listing is live on [epinu.ai](https://epinu.ai). If they never act, the
proposal expires by itself after 7 days.

**That's the whole model.** The agent did the work; the human made the
decision; the audit trail recorded both.
