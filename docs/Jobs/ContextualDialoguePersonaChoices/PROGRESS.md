# Contextual Dialogue Persona & Choices — Current Progress

**Updated:** 2026-10-23

**Parent status:** REOPENED — P10 infrastructure is retained, but P11 runtime parity, relationships, and Semantic Lab UX are mandatory.

**Current mandatory phase:** P11F — Unified semantic Flow / Hub / ConversationBlock runtime graph.

**Native Project Zomboid SP/MP:** UNTESTED / user-owned.

## Accepted foundation to preserve

The accepted P10 foundation remains in place:

- contextual What's Up semantic hub and removal of the legacy authored What's Up category;
- registered hub choice providers and typed Simulation Control Catalog;
- structured inventory plus Advanced JSON;
- Apply and Apply + Replay infrastructure;
- ActorConversationContext, SpeechStyleContext, relationship-state resolver, and EN/TL realization;
- graph renderer/history infrastructure and the Dynamic Trading provider boundary;
- production player/NPC trait and social-profile registries.

## P11A completed — actor-centric workbench and truthful catalogs

P11A is complete on the local ProjectHoomans `main` checkout.

- Simulation now presents `NPC Target`, `Player`, `Relationship`, and `World` in the main lower workbench.
- NPC Target and Player expose Overview, Needs, and Personality & Traits tabs.
- Normal relationship catalogs use only current production kinds: friend, lover, mother, father, sister, and brother. Future extensible kinds remain diagnostic-only.
- Preview is beside Send; Snapshot and Restart worker are in Diagnostics / Worker; World Knowledge refresh is in its inspector; Compare replaces the primary Persona Matrix / Sweep / Capture workflow.
- Apply, Apply + Replay, structured inventory, and Advanced JSON remain available.

## P11B completed — first-class actor needs and generated personality

P11B is complete.

- Player and NPC own Hunger, Thirst, Fatigue, Stress, Boredom, and Panic in the scenario model. Legacy world fields remain compatibility fallbacks.
- Player trait options come from `PNC.SocialTraits.GetDefinitions()` and feed the production social-trait resolver. Derived orientation and social profile values are read-only.
- NPC identity seed, archetype, registered traits, and generated personality use the production generator. Manual personality values require the explicit Override generated personality control.

## P11C completed — durable friend bond

P11C is complete.

- The durable bond lives on the existing directed relationship record with schema normalization and migration support. No second bond database exists.
- Server relationship commits evaluate approval 80, respect 50, familiarity 60. Promotion writes a bounded `friendship_established` event/memory and normal relationship revisions.
- Later standing deterioration can reach enemy while the durable friend bond remains. Starting Companion friend, lover, and current family kinds seed the same record.
- ActorConversationContext and the Semantic Lab project the durable bond.

## P11D completed — romance proposal and deterministic lover progression

P11D is complete on the local ProjectHoomans `main` checkout in commit `685d88a0`.

- One canonical `RELATIONSHIP_PROPOSAL` action uses production player traits, NPC social profile, actor genders, and the registered orientation compatibility APIs.
- Eligibility requires a friend bond, approval 85, respect 60, familiarity 80, non-rival/non-enemy standing, living and available actors, family exclusion, compatibility, and a clear cooldown.
- Acceptance is server-authoritative and deterministic, with personality-aware weighting. Acceptance promotes friend to lover and records bounded event/memory/revision state. Rejection preserves friend and adds a bounded cooldown.

Validation:

- `test_contextual_runtime_parity_p11d.py`: 7/7 passed under Xvfb.
- P11A-C combined regression and Lua/Python syntax checks passed before the P11D commit.

## P11E completed — live relationship preview and Compare

P11E is complete on the local ProjectHoomans `main` checkout.

- Added non-persisted `RELATIONSHIP_PREVIEW` through the real Lua worker. It uses the production standing resolver and proposal policy and reports standing, reason, scores, bond, thresholds, compatibility, cooldown, and availability while staged sliders move.
- Relationship workbench now shows live standing reason text, friend bond progress, romance compatibility, proposal threshold/cooldown/availability, Apply, Apply + Replay, and an optional debounced Auto replay checkbox.
- Compare is one understandable utterance plus A/B/C surface. It runs through the real Lua worker and displays NPC response, semantic choices, SpeechStyleContext, standing, durable bond, and runtime graph path while retaining the full production evidence payload.

Validation:

- `test_contextual_runtime_parity_p11e.py`: 4/4 passed under Xvfb.
- P11A-P11E focused regression: 21/21 passed under Xvfb.
- `luac5.3 -p`, `py_compile`, and `git diff --check` passed for the P11E changes.

## Current Exact Next Chunk — P11F

1. Unify greeting Flow, contextual Hub, and authored ConversationBlock graph projections through one renderer family.
2. Preserve current, visited, available, locked, future, and completed history plus real semantic frame/action paths.
3. Add focused graph tests for `hello`, contextual `What's up?`, and authored branches.
4. Run focused checks, update this ledger with exact evidence, commit P11F on existing `main`, and continue automatically to P11G.

## Ordered remaining milestones

- **P11F:** unified semantic Flow / Hub / ConversationBlock runtime graph.
- **P11G:** modular speech-realization content packs.
- **P11H:** final runtime-parity usability and regression gate.

## Handoff condition

Do not report **READY FOR USER LIVE TEST** until P11A-P11H all pass.

Native Project Zomboid SP/MP remains user-owned and must remain UNTESTED unless the user performs it.
