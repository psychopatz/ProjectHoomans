# Contextual Dialogue Persona & Choices — Current Progress

**Updated:** 2026-10-23

**Parent status:** P11 runtime parity and Semantic Lab UX completed locally.

**Current exact next chunk:** User-owned native Project Zomboid SP/MP live test.

**Native Project Zomboid SP/MP:** UNTESTED / user-owned.

## Accepted foundation

P10 infrastructure remains preserved: contextual What's Up semantic hub, removal of the legacy authored What's Up category, provider-driven contextual choices, typed Simulation Control Catalog, structured inventory with Advanced JSON, Apply + Replay, ActorConversationContext, SpeechStyleContext, relationship-state resolution, EN/TL realization, graph renderer/history infrastructure, and the Dynamic Trading provider boundary.

## P11A — actor-centric workbench and truthful catalogs

Completed on ProjectHoomans `main`.

- Main Simulation workbench exposes NPC Target, Player, Relationship, and World ownership with Overview, Needs, and Personality & Traits access.
- Normal relationship catalogs expose only current production kinds: `friend`, `lover`, `mother`, `father`, `sister`, and `brother`.
- Preview, Snapshot, Restart worker, World Knowledge, Compare, Apply, Apply + Replay, structured inventory, and Advanced JSON remain available under their intended surfaces.
- Real Tk/Xvfb workbench coverage passed at the required minimum and normal desktop sizes through the focused P11 suite.

## P11B — first-class actor needs and production personality

Completed on ProjectHoomans `main`.

- Player and NPC own Hunger, Thirst, Fatigue, Stress, Boredom, and Panic. Legacy world fields remain compatibility fallbacks.
- Player traits come from `PNC.SocialTraits` and feed the production social-profile resolver.
- NPC traits come from registered `PNC.NPCTraits`; generated personality is the default read-only source.
- Manual personality controls require the explicit generated-personality override.
- P11H compatibility fixed explicit legacy/manual profiles so numeric values survive production normalization, and made explicit empty needs/condition maps clear legacy defaults.

## P11C — durable friend bond

Completed on ProjectHoomans `main`.

- Durable bond is stored on the existing directed relationship record with schema normalization and migration support.
- Friend promotion uses approval `80`, respect `50`, familiarity `60`, standing gates, family exclusion, bounded event/memory, revisions, and normal persistence.
- Bond remains durable after standing deterioration; starting friend, lover, and authored family relationships seed the same record.
- ActorConversationContext and semantic realization consume the durable bond.

## P11D — romance proposal to lover

Completed in commit `685d88a0`.

- One canonical `RELATIONSHIP_PROPOSAL` action uses production gender, player trait/social profile, NPC profile, and mutual orientation compatibility.
- Eligibility uses friend bond, approval `85`, respect `60`, familiarity `80`, standing/availability/family gates, and cooldown.
- Acceptance is server-authoritative and deterministic with bounded personality-aware weighting.
- Acceptance promotes friend to lover and records event, memory, revision, and persistence state. Rejection preserves friend and applies cooldown.

## P11E — live relationship preview and Compare

Completed in commit `2296eaf9`.

- Non-persisted `RELATIONSHIP_PREVIEW` uses the production standing resolver and proposal policy while sliders move.
- Workbench shows standing reason, friend progress, compatibility, proposal thresholds, cooldown, availability, Apply, Apply + Replay, and optional debounced Auto replay.
- Compare runs the real Lua worker and reports NPC response, semantic choices, SpeechStyleContext, relationship state, durable bond, and runtime graph path.

## P11F — unified runtime dialogue graph

Completed in commit `ada3b647`.

- `hello` projects the actual greeting semantic Flow with current, visited, completed, and future transitions.
- What's Up projects the real provider/candidate semantic Hub graph and preserves visited/completed history after route closure.
- Authored ConversationBlock projections continue through the same graph interaction path.
- Tk graph adapters share the `semantic_flow`, `semantic_hub`, and `conversation_block` renderer family.

## P11G — modular speech realization packs

Completed in commit `3499ffc8`.

- One SpeechRealization registry, resolver, fallback, and translation path remain in the central module.
- Built-in phrase content is split into cohesive Status, Social, Knowledge, and Actions packs with shared builders.
- Catalog validation reports 39 registered families and 15 coverage domains; EN/TL family-address behavior remains covered.

## P11H — final runtime-parity usability gate

Completed locally on ProjectHoomans `main`.

### Acceptance evidence

- Full Python/Tk discovery under Xvfb: **412/412 passed**.
- Focused P11A-G and P10 regression suite under Xvfb: **70/70 passed**.
- Embedded semantic Lua suite: **73/73 passed**.
- Relationship, translation, starting-companion, authority, and inventory Lua suites: **54/54 passed**.
- Doctor: all required checks passed; optional active-venv check is false only because the system interpreter is active.
- Full-mod Kahlua verification: **3,086 Lua files, zero findings**.
- Dedicated Kahlua lint: zero findings.
- Changed-file `luac5.3 -p`, Python compilation, and `git diff --check`: passed.
- EN/TL catalog validation: **35/35 matching files, zero key mismatches**.
- Speech catalog validation: **39 families, 15 coverage domains**.
- Normal relationship catalog validation: `mother`, `father`, `sister`, `brother`, `friend`, `lover`; no hypothetical future kinds.
- Privacy, stale/replay, gameplay authority, structured inventory, Advanced JSON, persistence/migration, friend promotion, romance compatibility/acceptance/cooldown, family exclusion, starting relationships, graph history, and P10 contextual hub regressions are covered by the full and focused suites.
- Duplicate-state scan found no bond, personality, or conversation-graph ModData persistence. Existing unrelated knowledge/runtime ModData boundaries remain unchanged.
- Codebase-memory coverage check for the relationship, trait, speech, runtime, and scenario paths returned no recorded coverage issue; changed paths were read directly because the index records them as metadata-changed or not-tracked.

## Handoff condition

P11A-P11H pass locally. **READY FOR USER LIVE TEST** is now valid for the user-owned native Project Zomboid SP/MP validation. The agent did not operate native Project Zomboid and does not claim SP/MP evidence.
