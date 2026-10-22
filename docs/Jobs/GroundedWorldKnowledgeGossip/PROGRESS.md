# Progress — Project Hoomans Grounded World Knowledge Adoption

Updated: 2026-10-22
Status: IN PROGRESS; W0 complete and W2 producer/conversation adapter implemented, with W3-W6 remaining.

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

Completed the bounded source/authority audit without adding production state. Exact local/remote state, the zombie census/cache relationship, faction/death publication points, PZ API limitation, conversation worker before-state, and DT boundary are recorded in `AUDIT.md` and Core `Docs/world_knowledge_gossip/PROGRESS.md`. The current dirty PNC files remain untouched. Next phase is Core W1, then Hoomans W2-W6.
