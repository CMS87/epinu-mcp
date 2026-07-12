// Epinu MCP walkthrough — the full agent flow: search → propose → HUMAN approves.
//
// Zero dependencies. Node >= 18 (built-in fetch).
//
//   node examples/walkthrough.mjs                    # anonymous leg only (safe, read-only)
//   EPINU_AGENT_TOKEN=epagt_... node examples/walkthrough.mjs   # + the propose leg
//
// The point of this example is what does NOT happen: the write call below never
// touches the database. It creates a *proposal* (status: pending) and returns an
// approval_url. A human reviews and approves it in the Epinu dashboard — only then
// does the listing exist. Every proposal is audited with the agent's identity.
// See examples/walkthrough.md for a recorded transcript of the full loop,
// including the human-approval moment.

const MCP = process.env.EPINU_MCP_URL || 'https://api.epinu.ai/api/agent/mcp';
const TOKEN = process.env.EPINU_AGENT_TOKEN;

let nextId = 1;
async function rpc(method, params) {
  const res = await fetch(MCP, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json, text/event-stream',
      ...(TOKEN ? { Authorization: `Bearer ${TOKEN}` } : {}),
    },
    body: JSON.stringify({ jsonrpc: '2.0', id: nextId++, method, params }),
  });
  const body = await res.json();
  if (body.error) throw new Error(`${method}: ${body.error.message}`);
  return body.result;
}

// tools/call results wrap their payload as JSON text in content[0].
async function callTool(name, args = {}) {
  const result = await rpc('tools/call', { name, arguments: args });
  if (result.isError) throw new Error(`${name}: ${result.content?.[0]?.text}`);
  return JSON.parse(result.content[0].text);
}

const show = (label, value) =>
  console.log(`\n── ${label} ${'─'.repeat(Math.max(0, 60 - label.length))}\n` +
    JSON.stringify(value, null, 2));

// ── 1. Handshake (anonymous works) ─────────────────────────────────────────
const init = await rpc('initialize', {
  protocolVersion: '2024-11-05',
  capabilities: {},
  clientInfo: { name: 'epinu-walkthrough', version: '1.0.0' },
});
show('1. initialize', init.serverInfo);
console.log(`   server says: ${init.instructions}`);

// ── 2. Etiquette: check for duplicates BEFORE proposing ────────────────────
const dupes = await callTool('marketplace_listings_search', {
  query: 'livestock verification visit',
});
show('2. duplicate check (marketplace_listings_search)', {
  results: dupes.results.length,
  titles: dupes.results.map(r => r.title).slice(0, 5),
});

if (!TOKEN) {
  console.log(`
── 3. propose leg skipped ──────────────────────────────────────
No EPINU_AGENT_TOKEN set, and that is the point: WRITES ARE NEVER
ANONYMOUS on Epinu. To run the propose→approve loop yourself:
  1. Create an account:            https://epinu.ai/signup
  2. Dashboard → Settings → Authorize Agent → copy the epagt_ token
  3. EPINU_AGENT_TOKEN=epagt_... node examples/walkthrough.mjs
See walkthrough.md for a recorded transcript of steps 3-5.`);
  process.exit(0);
}

// ── 3. Who am I? (identity, scopes — never secrets) ────────────────────────
const me = await callTool('whoami');
show('3. whoami', me);

// ── 4. Propose a listing — returns PENDING + an approval URL ───────────────
// A quote-priced service listing (no fixed price → pricing_mode: 'quote').
const proposal = await callTool('marketplace_listing_create', {
  title: 'Veterinary weigh-in & herd verification visit — medianería record-keeping',
  description:
    'On-site visit by a credentialed veterinarian: animal count, weigh-in, health check, ' +
    'and signed verification record for an active cattle medianería agreement. ' +
    'Price quoted per visit depending on herd size and location.',
  category: 'service',
  subcategory: 'Livestock / Ganadería',
  pricing_mode: 'quote',
  price_unit: 'per visit',
  location_address: 'Venezuela',
});
show('4. marketplace_listing_create → PROPOSAL (not a listing yet!)', proposal);
console.log(`
   >>> Nothing was written. A human must now open:
   >>> ${proposal.approval_url || '(approval_url)'}
   >>> and approve or reject this proposal in the dashboard.`);

// ── 5. Track it ─────────────────────────────────────────────────────────────
const mine = await callTool('proposals_list_my', { status: 'all', limit: 5 });
show('5. proposals_list_my', mine);
console.log('\nDone. The proposal stays pending until a human decides (expires in 7 days).');
