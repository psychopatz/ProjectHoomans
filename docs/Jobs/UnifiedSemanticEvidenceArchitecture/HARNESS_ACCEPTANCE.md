# Harness Acceptance — Unified Semantic Evidence Architecture

Use the production Lua worker / Semantic Lab as the primary developer acceptance surface.

## Required trace chain

For a semantic turn expose bounded evidence for:

1. recognized semantic act/candidates;
2. session-context evidence queried;
3. today-memory evidence queried;
4. durable providers queried;
5. normalized evidence rows with provider/source tier;
6. relation compatibility;
7. retention salience, confidence, effective strength and recency as distinct fields when applicable;
8. derived contextual relevance/admission result;
9. pragmatic frame;
10. Director behavior/beat;
11. generated player affordances;
12. NPC/player UtterancePlan;
13. actual authoritative effect/memory outcomes.

Diagnostics must not require dumping entire stores.

## Core scenario matrix

### Repair

- reset + im sorry -> APOLOGIZE recognized, no fabricated grievance/forgiveness;
- insult -> apology in same conversation;
- insult -> close/reopen -> apology same world day;
- day rollover after non-durable insult;
- durable severe grievance -> later apology;
- repeated apology after already-addressed grievance;
- newer grievance after prior repair;
- different target / third-party event;
- relationship-memory saturated but today projection retained.

### Other relation families

At minimum:

- assistance/rescue -> THANK;
- open offer/request/question -> ACCEPT/REFUSE/ACKNOWLEDGE or appropriate reply;
- negative controls with no matching antecedent.

### Extensibility fixture

Register a synthetic future mechanic, recommended promise/commitment, through public evidence/relation registration.

The test must fail if it requires a new generic-resolver code branch. The fixture must be removable without leaving production-specific conditionals.

## Salience and storage

Verify exact limits and behavior:

- TODAY short <= 8 event triples;
- TODAY topics remain bounded bitmasks;
- compact durable <= 6 event quadruples;
- relationship memories <= 20;
- conduct evidence <= 64;
- no new semantic ModData root;
- repeated event/target pairs coalesce;
- salience-aware short retention is deterministic;
- high-salience evidence survives lower-salience churn;
- equal-salience ties use deterministic recency;
- day rollover removes current-day short/topic state;
- derived relevance/relations are absent from persistence unless represented by an existing compact event marker.

Capture representative serialized byte deltas before/after stress.

## Safety

Context may strengthen non-mutating conversational interpretation but must never lower existing authorization thresholds for inventory, movement, recruitment, relationship mutation or other gameplay effects.

Provider/query failures fail closed for mutation and degrade gracefully for dialogue.

## Regression

Run focused and broad suites appropriate to touched owners:

- Project Hoomans semantic Lua;
- social events;
- relationship memory;
- conduct;
- Conversation Memory normalization/storage;
- CodeBuilder/context-health when generated data changes;
- PsychopatzCore semantic suites only if Core is genuinely touched;
- Kahlua/static verification;
- git diff --check.

Source SAVE hashes must remain unchanged. Native SP/MP remains user-owned after developer acceptance.
