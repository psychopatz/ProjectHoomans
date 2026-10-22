# Progress — Project Hoomans Grounded World Knowledge Adoption

Updated: 2026-10-22
Status: W0-W9 developer implementation/evidence complete; native PZ SP/MP remains reserved for user validation.

Canonical parent progress: PsychopatzCore Docs/world_knowledge_gossip/PROGRESS.md.

## Current Hoomans responsibility in W0

Audit exact current source paths and evidence for:
- lightweight zombie-density/debug display requested by the user and its underlying cached count/band source;
- faction member death and destruction/status transition publication points;
- NPC death/cause attribution;
- Build 42.20 helicopter, power, water and season authoritative APIs/hooks;
- npcGossip construction path for normal game, real Semantic Lab worker and optional PBrainZ;
- ModData/persistence owners that must not be duplicated.

Capture one real worker before-state showing GOSSIP with and without provided authoritative statements.

After W0 contract freeze, continue through Core W1 then Hoomans W2-W6, DT W7, Lab W8 and final W9 without requiring another prompt. Parent completion is controlled by the Core roadmap, not this adopter ledger alone.

## W0 durable evidence

W2 adapter implementation is now present; detailed evidence follows below.

## W2 Core adoption and grounded projection (2026-10-22)

Hoomans now loads the shared Core World Knowledge mechanism from the existing shared/server compositions. `PNC.WorldKnowledge` is a thin owner adapter: it publishes compact zombie-pressure, canonical NPC-death, faction-incident, faction-status and treaty facts, and applies Hoomans-owned acquisition policy. The server wrapper observes existing `PNC.SocialEventHooks`, `PNC.Health.Kill`, `PNC.FactionIncidentService`, faction lifecycle and treaty mutation seams only after their authoritative operation reports success; it does not enumerate zombies or move faction/death ownership.

The cognition service prefers a grounded World Knowledge context when the speaking actor has authorized candidates, otherwise preserving the existing memory-gossip path. The existing bounded `npcGossip` transport is reused through the server network payload and the client `GOSSIP_RECEIVED` route. Runtime EN/TL rendering is derived from fact provenance and is not persisted. No statement is emitted when the actor has no authorized fact. Fact references/candidates are carried for later Semantic Lab/PBrainZ explainability, while no client path reads the global ledger.

Evidence:

```text
python3 tests/run_tests.py pnc_world_knowledge_smoke --verbose       PASS
python3 -m unittest tools.semantic_harness.tests.test_automatic_flow_generation.AutomaticFlowGenerationTests.test_authoritative_gossip_memory_reaches_response_selection_in_en_and_tl -v  PASS
```

`pz_verify.py --kahlua` reports zero errors for the new shared adapter, server wrapper and client cognition changes. The focused worker regression still passes in EN/TL with zero LLM calls. This slice proves the adopter seam and preserves the normal gossip path; it does not yet claim authoritative helicopter/power/water/season adapters, opportunistic NPC propagation, Semantic Lab inspection, DynamicTrading reuse, PBrainZ parity, or native PZ behavior.

## W3/W4 bounded world-state and propagation slice (2026-10-22)

`PNC_WorldKnowledge_PZ.lua` now exposes guarded authority readers for the audited helicopter, hydro-power and climate-season candidates. It accepts injected owner readers for exact 42.20 validation and returns explicit `unknown` for absent/failing readers; water remains unknown because no verified global shutoff owner was found. `ObserveAuthoritativeWorldState` publishes only initial-known or changed domain states, dedupes unchanged observations, uses `derived_current` for initial runtime state and historical retention for transitions, and never scans zombies.

The same adapter now exposes `AcquirePublicFact` and `PropagateConversation`. Propagation requires an authorized conversation/radio/faction opportunity, transfers at most the Core bound, records told/radio provenance and cooldowns, and keeps a bounded acceptance/rejection trace. The smoke test proves Alice-known/Bob-unknown/no statement, Alice-to-Bob transfer, same fact ID, told provenance, world-state initial/transition facts, unchanged-state dedupe and truthful water unknown.

Completed the bounded source/authority audit without adding production state. Exact local/remote state, the zombie census/cache relationship, faction/death publication points, PZ API limitation, conversation worker before-state, and DT boundary are recorded in `AUDIT.md` and Core `Docs/world_knowledge_gossip/PROGRESS.md`. The current dirty PNC files remain untouched. Next phase is Core W1, then Hoomans W2-W6.

## W5/W6 Semantic Lab, PBrainZ and worker evidence (2026-10-22)

The existing Semantic Lab production worker now loads the production Core World Knowledge and Hoomans adapters. Its existing command router exposes bounded `WORLD_KNOWLEDGE_INSPECT` and `WORLD_KNOWLEDGE_PROPAGATE` commands; the Python worker facade exposes the same operations. The scenario fixture is explicitly marked `scenarioOwned` and uses the production Core ledger, actor references, ranking, rendering, cognition projection and client transport. No JSON-only simulator or second parser was added.

The existing PBrainZ dialogue-facts projection now carries the same bounded `factRefs`, provenance, confidence and source from `npcGossip`; it never reads the global ledger. The existing dialogue input lifecycle carries the authorized fact references/source into the response projection where that path is available.

Real worker evidence:

```text
python3 -m unittest tools.semantic_harness.tests.test_grounded_world_knowledge_gossip -v
  2 tests PASS; EN observed/told/no-news, TL observed realization, zero LLM path
python3 -m unittest tools.semantic_harness.tests.test_world_knowledge_inspector -v
  PASS; ledger, actor explanation, ranking, provenance, final source/localization
python3 tests/run_tests.py pbrainz_world_knowledge_smoke --verbose
  PASS; PBrainZ receives the same fact ID/provenance/source
```

The mandatory Alice/Bob scenario is real production Lua worker evidence: Alice can report a witnessed fact, Bob initially receives no statement and selects the existing truthful unknown route, explicit authorized conversation propagation gives Bob the same fact ID with `told` provenance, and Bob then says he heard it.

## W8 Semantic Lab GUI evidence (2026-10-22)

The existing Semantic Lab Simulation trace notebook now includes a first-class `World Knowledge` tab and toolbar action. It renders a bounded projection containing Fact Ledger, Actor Knowledge, Propagation Trace, candidate ranking/why data, authorization/rejection reason, and final realization source/localization. It uses the existing `LuaSemanticWorker` session and does not create a second app.

```text
xvfb-run -a python3 -m unittest tools.semantic_harness.tests.test_world_knowledge_gui -v
  PASS; existing Tk Semantic Lab pane rendered live worker inspection
```

The worker router was also Kahlua-checked after the inspection addition; its pre-existing `next()` calls were replaced with a local `pairs()` helper so the touched file has zero Kahlua errors.

## W9 adopter persistence evidence (2026-10-22)

`pnc_world_knowledge_smoke.lua` now stubs the existing `PNC.WorldKnowledge` ModData owner, saves a historical fact and an ephemeral runtime observation, reloads through the production adapter, and verifies only the historical fact/reference survives. This is an owner-boundary fixture, not native PZ save evidence.

```text
python3 tests/run_tests.py pnc_world_knowledge_smoke --verbose
  PASS 1/1
python3 skills/pz-verify/scripts/pz_verify.py --file Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/WorldKnowledge/PNC_WorldKnowledge.lua --kahlua --no-snippets
  0 errors; 0 warnings
```

W0-W9 Hoomans developer evidence is complete; native PZ SP/MP remains explicitly untested and reserved for the user.

Semantic Lab worker performance evidence (non-native, 2026-10-22):

```text
python3 -m tools.semantic_harness.testing.performance --samples 2 --warmup 1 --serial-turns 8
  PASS; recognized-follow median 361.68ms/165.86ms (provider disabled/enabled)
  PASS; wellbeing median 278.28ms/160.55ms
  PASS; unknown fallback median 340.41ms/164.84ms
  PASS; serialized worker bounded at maxRecentDialogueTurns=6 and maxRecentSemanticEvents=8
```

These measurements cover the real production Lua worker protocol only; native Project Zomboid engine tick cost, SP/MP scheduling and server authority remain user-owned and untested.

The authoritative-domain smoke now also covers `zombie`, `hostile_npc`, `player`, and unknown death attribution; war, peace, truce, alliance and alliance-break incident publication; faction destruction; and authorized public acquisition. Commit: `ba9f32b8`.
