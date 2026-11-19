# Harness Acceptance — Compact Social Memory & Relationship Authority

Developer acceptance must prove behavior through the real production Lua/social/semantic paths, not JSON shape checks alone.

## A. Baseline and storage evidence

Capture before structural change:

- serialized relationship/memory/conduct/knowledge footprint for a small representative population;
- repeated same-pair events;
- many unrelated actors;
- high-observer event;
- current TODAY/long/relationship memory caps and rollover behavior;
- current server/client relationship snapshot traffic where testable.

Measurements must state fixture shape, actor/event count and serialized byte/count metrics.

## B. Retention

Required cases:

- SCENE evidence disappears with scene/session and is not saved;
- SHORT expires/rolls over according to accepted policy;
- LONG survives expected day boundaries but remains bounded;
- ANCHOR survives long age but obeys a hard cap;
- low-salience events lose under saturation before high-salience events where policy says so;
- no tick loop is needed for decay.

## C. Consolidation

Required cases:

- repeated equivalent incidents coalesce;
- count/first/last/aggregate semantics stay deterministic;
- one especially salient event can remain distinct;
- consolidated state still supports correct relationship and semantic explanation;
- storage growth is sublinear/bounded for repeated same-key events.

## D. Relationships and hostility

Required cases:

- A-to-B differs from B-to-A;
- unrelated A/C pair creates no edge merely because both exist;
- personal positive attitude can coexist with hostile faction policy;
- immediate attack/threat can cause hostile behavior without permanently forcing relationship sentiment;
- grievance can survive expiry of exact low-level event detail according to policy.

## E. Knowledge vs memory

Required cases:

- learned identity/name/fact persists through Knowledge without consuming an ANCHOR slot;
- forgetting an episodic detail does not erase authoritative learned facts unless the Knowledge domain explicitly owns forgetting;
- semantic query reports the correct source tier/provenance.

## F. Provenance / gossip

Required cases:

- direct target;
- direct witness;
- hearsay from a named actor;
- hearsay confidence/shareability attenuation where configured;
- no duplicated verbose payload per recipient;
- semantic realization can distinguish witnessed vs heard-about context without persisting prose.

## G. Personality/configuration

At minimum demonstrate three event families, such as insult/grievance, rescue/assistance and severe betrayal/kill.

For each:

- canonical event policy is data-driven;
- at least two actor profiles produce different bounded retention/effect outcomes;
- server/sandbox multiplier changes behavior within safe limits;
- compiler output is deterministic.

## H. Multiplayer authority

Required protocol/harness cases:

- client cannot directly set trust/grievance/memory;
- replayed social request does not double-apply consequences;
- player-to-NPC event is committed by server;
- NPC-to-NPC server event updates directed social state;
- NPC witnesses player-to-player event and records only appropriate evidence;
- non-witness NPC does not magically know it;
- reconnect/join receives bounded presentation snapshot, not full private NPC memory;
- stale revision/context causes requery/revalidation.

## I. Semantic/Director integration

Using the real Semantic Harness worker:

- relationship provider returns bounded directed relationship context;
- memory evidence retrieval is targeted;
- current-day and durable tiers remain compatible with Unified Semantic Evidence;
- Social Conversation Director can use state without becoming persistence owner;
- DecisionFrame/optional AI projection contains compact relevant facts only;
- no transcript/full-memory dump appears in traces.

## J. Scale acceptance

Stress at least:

- many actors with few meaningful contacts;
- many repeated events for one pair;
- many distinct meaningful pairs;
- high-observer event;
- multiple world days;
- anchor saturation;
- actor deletion/stale refs;
- gossip chain;
- server reload.

Acceptance requires hard evidence that:

- memory rows remain within configured caps;
- relationship edges scale with meaningful contacts, not population squared;
- no per-tick memory aging path exists;
- query work is bounded/targeted;
- serialized footprint remains within the documented budget/measurement expectations;
- no broad MP replication of private state occurs.

## K. Future non-LLM autonomy consumer contract

Add a synthetic read-only consumer representing a future advertisement/autonomy resolver.

It must be able to evaluate bounded social context for candidate opportunities such as TALK, HELP, AVOID or CONFRONT using public projections only.

Acceptance requires:

- two actors with the same external opportunity but different personality/relationship/memory context can receive different social decision features;
- one remembered event can make several response motives plausible without the social-state layer selecting the final action;
- candidate evaluation does not scan unrelated actors or full global memory;
- raw private stores are not exposed to clients;
- no world-pacing, advertisement scoring, task reservation or action execution logic is added to this job;
- no LLM is needed to produce the decision features;
- revision changes make stale cached projections detectable.

## L. Regression

Before final developer acceptance:

- relevant Lua tests pass;
- relevant Python/harness tests pass;
- real Semantic Harness suites pass;
- CodeBuilder check/generation is deterministic where touched;
- installed Kahlua/static compile checks pass where currently used by repository practice;
- git diff --check passes;
- source saves remain untouched;
- accepted Unified Semantic Evidence and Social Conversation Director regressions remain green.

Only then mark READY FOR USER LIVE TEST.


## Parent portability acceptance

Hoomans acceptance is necessary but not sufficient.

The canonical Core parent additionally requires:

- Core-only portable social fixture;
- DynamicTrading/DTAbstract fixture with Project Hoomans disabled;
- combined Hoomans + DynamicTrading fixture;
- one shared actor identity and one generic directed relationship state across representation changes.

Do not satisfy Hoomans tests by introducing a PNC-only contract that DTAbstract cannot consume.
