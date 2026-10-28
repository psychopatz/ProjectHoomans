# Roadmap — Unified Semantic Evidence Architecture

**Parent status:** PLANNED / OPEN.
**Accepted foundation:** existing parser, DialogueContextState, Conversation Memory, relationship/conduct systems, InteractionProviders, Pragmatic Resolver, Interaction Director, generated affordances and UtterancePlan.
**Active phase:** E0.

All E0-E7 phases are mandatory. Completing one adopter or fixing im sorry does not complete the parent goal.

## E0 — Baseline, contracts and storage measurements

Reproduce and machine-capture:

- reset/no-grievance im sorry;
- same-session insult -> apology;
- cross-conversation same-day event recall;
- durable relationship/conduct event recall;
- relationship-memory saturation with immediate social effect;
- current record.memory.s/t/l shape and limits;
- current salience behavior;
- current InteractionProviders/PragmaticResolver projections.

Measure representative serialized ModData deltas without mutating source saves. Record explicit meaning of confidence, salience, strength/decay, recency, relevance and priority.

**Gate:** grounded baseline tests and measurements exist before architecture changes.

## E1 — Canonical evidence schema and provider seam

Define a bounded normalized evidence descriptor and query contract. Extend existing InteractionProviders/InteractionContext with evidence and add adapter registration consistent with existing provider patterns.

Requirements: runtime read model only; bounded fields/lists; provenance/source tier; targeted query by relation/class/target; no raw transcript/context copying; no gameplay mutation from provider/query code.

**Gate:** session, today and durable fixture providers normalize into one schema; existing consumers remain compatible.

## E2 — Canonical event metadata and salience unification

Remove first-party dual authoring between social-event definitions and Conversation Memory EventTypes.

Add canonical semantic evidence metadata for first-party social events, including explicit retention policy and salience where relevant. Derive/register compact Conversation Memory metadata from the authoritative source. Keep safe dynamic fallback for unknown addons but make first-party omission visible to validation.

Standardize names/contracts for retention salience versus confidence/relevance/strength/priority.

**Gate:** every first-party social event is explicitly semantically described or explicitly opts out; no silent salience-0 drift for intended adopters; stable codes/migrations remain safe.

## E3 — Tiered evidence query and salience-aware bounded retention

Implement one bounded query path over SESSION -> TODAY -> DURABLE.

- SESSION uses existing dialogue/director state;
- TODAY reads existing compact short/topic storage;
- DURABLE queries owning domain APIs and optional compact long projection;
- no interactionJournal scan;
- no full-store dump into semantic context.

Make the eight-slot TODAY event lane salience-aware when full, with deterministic recency tie-breaks and no persisted salience field.

Decouple TODAY projection from detailed relationship-memory retention: successful authoritative events may remain remembered today even when full relationship memory is pruned/dropped.

**Gate:** bounded deterministic query results, no new ModData root, and saturation regressions pass.

## E4 — Generic semantic relation/obligation resolution

Introduce data-driven relations between semantic acts and evidence: opens, addresses, resolves and other small canonical relation types.

Use the existing Pragmatic Resolver as interpretation owner. It receives evidence/relation matches and produces grounded, unresolved, unrelated or ambiguous pragmatic outcomes. It does not tokenize text or mutate gameplay.

Current relation state is derived at read time from ordered session/day evidence and authoritative durable evidence; do not create a parallel obligation database.

**Gate:** no-grievance apology clarifies rather than fabricating forgiveness; same-session and same-day grievance cases ground correctly; repeated repair does not reopen a resolved event without newer evidence.

## E5 — First-party adopters

Migrate representative existing mechanics onto the generic path:

- hostility/grievance -> apology/repair;
- assistance/help -> gratitude;
- pending offer/request/question -> accept/refuse/acknowledge/reply;
- reconciliation/challenge where already supported.

Generated player affordances and NPC behavior consume the same pragmatic evidence. Relationship/personality/world policy remains downstream authority.

**Gate:** at least three distinct relation families use the same generic architecture with no feature-specific memory manager.

## E6 — Extensibility proof and content integration

Add one synthetic/test future mechanic such as promise -> fulfillment/breach -> repair/explanation using registration/metadata only.

A new evidence type/relation must not require editing generic evidence query, Pragmatic Resolver algorithm or creating a store.

Integrate required Dialogue Content/affordance/UtterancePlan data through canonical CodeBuilder sources, deterministic generation and locale-owned translations.

**Gate:** synthetic adopter passes through real Lua worker and existing Response Channel/Director pipeline with resolver implementation unchanged.

## E7 — Scale, storage and full acceptance

Stress repeated conversations/events across multiple world days and saturated stores.

Prove:

- no new semantic ModData root;
- no transcript persistence;
- TODAY short limit stays 8;
- compact durable limit stays 6;
- relationship memory stays 20;
- conduct evidence stays 64;
- repeated event/target entries coalesce;
- salience protects meaningful events under pressure;
- day rollover drops short episodic state;
- durable context survives only through existing policy;
- semantic query cost remains bounded;
- traces remain bounded;
- full semantic/social/conduct/CodeBuilder regressions pass;
- two generations are byte-identical where generated sources change;
- source saves remain immutable.

Only after E7 developer acceptance hand native SP/MP verification to the user.

## Stop rules

Do not launch native Project Zomboid, publish Workshop content, mutate source saves, create a new branch, replace PsychopatzCore NLU, create a second dialogue/behavior engine, or invent new persistence merely to satisfy a test.

A phase completion is not a stop condition. Continue through E0-E7 under the parent /goal unless a genuine ownership/safety/tooling blocker occurs.
