# Walkthrough: an agent proposes, a human approves

This document combines a **real recorded transcript** of the anonymous leg of
[`walkthrough.mjs`](walkthrough.mjs) against the live production endpoint with
an **illustrative, redacted proposal flow**. The proposal section will be
replaced with a complete production transcript once the demonstrative run is
recorded with a delegated `epagt_` token.

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

## The propose leg (delegated token)

With `EPINU_AGENT_TOKEN` set, the same script continues:

```console
── 3. whoami ───────────────────────────────────────────────────
(agent identity, scopes and restrictions — never secrets)

── 4. marketplace_listing_create → PROPOSAL (not a listing yet!)
{
  "proposal_id": "…",
  "status": "pending",
  "approval_url": "https://epinu.ai/dashboard/proposals/…",
  …
}

   >>> Nothing was written. A human must now open:
   >>> https://epinu.ai/dashboard/proposals/…
   >>> and approve or reject this proposal in the dashboard.
```

<!-- TRANSCRIPT-PENDING: replace the propose-leg block above with the real
     recorded output once run with a test agent token. -->

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
