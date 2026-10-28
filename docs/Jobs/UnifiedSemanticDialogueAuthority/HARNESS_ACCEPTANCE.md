# Harness Acceptance — Remaining P11

Use this contract for future P11B–P11I work.

## Authority

Acceptance must preserve:

- one semantic meaning/ResponseCatalog authority;
- one Project Hoomans first-party wording authority;
- one semantic lifecycle/context authority;
- one Conversation UI/navigation authority once P11D lands;
- gameplay/domain systems as factual/effect authority;
- presentation as delivery only.

Generated compatibility shims may bridge old require paths temporarily but must
not become semantic or wording authorities.

## Canonical source / generation

- canonical Conversation authoring is manifest-backed and modular;
- agents/editors write canonical shards, never generated output;
- global IDs/cross-references validate across shards;
- generated runtime modules are bounded;
- generated indexes/manifests/translations are deterministic;
- two consecutive generation runs are byte-identical;
- generated aggregate snapshots are read-only;
- physical shard moves do not change canonical identity.

## Translation

- EN is the required fallback locale;
- other locales are discovered from generic translation data/directories;
- adding a locale does not require a compiler language whitelist;
- placeholders/arguments remain equivalent across available locales;
- generated `Conversation.json` reflects actual locale files;
- automatic-flow/semantic manifests do not duplicate locale path ownership;
- generated JSON is deterministic, readable and newline-terminated.

## P11B wording-domain gate

For each migrated domain:

- characterize real production callers once;
- preserve factual/parameter behavior;
- migrate callers directly to canonical Dialogue Content;
- focused domain tests pass;
- full native Lua remains green;
- relevant Python/worker tests pass;
- old key/path is removed only after production caller search reaches zero;
- no broad runtime alias table masks incomplete migration.

## P11D Conversation UI gate

When implemented:

- static landing/hub/child/order data comes from one registry;
- What's Up child membership can be changed without production Lua edits;
- dynamic provider eligibility remains production-owned and visibly locked;
- UI changes do not mutate gameplay policy.

## P11F/G Studio/editor gate

When implemented:

- one Conversation explorer is the normal inspection surface;
- route/conditions/follow-ups/sources remain inspectable;
- Developer Tools edits the selected item;
- phrase variants can be added/duplicated/deleted/reordered safely;
- all available locales are editable through generic locale controls;
- normal authoring does not require raw JSON;
- preview/review is effect-free until explicit write;
- stale/fingerprint guards reject outdated writes.

## P11H agent-authoring gate

- GUI and agent workflows call the same canonical-ID service;
- bounded inspect/edit/add/remove/reorder APIs exist;
- diagnostics are machine-readable;
- no hidden writes;
- generated artifacts are never direct edit targets.

## Runtime regression

For runtime-affecting slices:

- typed/clicked/event semantic parity remains;
- command/task/gift automatic flows retain behavior;
- follow-up grounding/privacy remains;
- PBrainZ integration remains;
- compatibility adapters remain;
- full native Lua remains green;
- relevant resource-aware Python acceptance remains green;
- installed-PZ Kahlua verification is run when the verifier is available;
- `git diff --check` passes.

Do not relabel a newly failing old test as a baseline failure without verifying
that it was already red at the accepted pre-slice baseline.

## Data/save safety

- developer acceptance does not launch native Project Zomboid;
- source saves are not mutated;
- no Workshop publication occurs;
- no player/NPC persisted state is added merely for rendered dialogue;
- no per-NPC/per-tick semantic scans are introduced.

## P11I completion

Only after all remaining P11 gates pass may the parent return to
`READY FOR USER LIVE TEST`.

Native SP/MP acceptance remains user-owned.
