# Contextual Dialogue Persona & Choices — Current Progress

**Updated:** 2026-10-23

**Parent status:** P11 runtime parity and requested Semantic Lab usability polish completed locally.

**Current exact next chunk:** User-owned native Project Zomboid SP/MP live test.

**Native Project Zomboid SP/MP:** UNTESTED / user-owned.

## Accepted foundation

P10 infrastructure remains preserved: contextual What's Up semantic hub, removal of the legacy authored What's Up category, provider-driven contextual choices, typed Simulation Control Catalog, structured inventory with Advanced JSON, Apply + Replay, ActorConversationContext, SpeechStyleContext, relationship-state resolution, EN/TL realization, graph renderer/history infrastructure, and the Dynamic Trading provider boundary.

## P11A — actor-centric workbench and truthful catalogs

Completed on ProjectHoomans `main`.

- Main Simulation workbench exposes NPC Target, Player, Relationship, and World ownership with Overview, Needs, and Personality & Traits access.
- Normal relationship catalogs expose only current production kinds: `friend`, `lover`, `mother`, `father`, `sister`, and `brother`.
- Preview, Snapshot, Restart worker, World Knowledge, Compare, Apply, Apply + Replay, structured inventory, and Advanced JSON remain available under their intended surfaces.
- Real Tk/Xvfb workbench coverage passed the minimum and normal desktop sizes.

## P11B — first-class actor needs and production personality

Completed on ProjectHoomans `main`.

- Player and NPC own Hunger, Thirst, Fatigue, Stress, Boredom, and Panic. Legacy world fields remain compatibility fallbacks.
- Player traits come from `PNC.SocialTraits` and feed the production social-profile resolver.
- NPC traits come from registered `PNC.NPCTraits`; generated personality is the default read-only source.
- Manual personality controls require an explicit generated-personality override.
- Legacy/manual profile normalization preserves explicit numeric values, and explicit empty needs/condition maps clear legacy defaults.

## P11C — durable friend bond

Completed on ProjectHoomans `main`.

- Durable bond is stored on the existing directed relationship record with schema normalization and migration support.
- Friend promotion uses approval `80`, respect `50`, familiarity `60`, standing gates, family exclusion, bounded event/memory, revisions, and normal persistence.
- The bond remains durable after standing deterioration; starting friend, lover, and authored family relationships seed the same record.
- ActorConversationContext and semantic realization consume the durable bond.

## P11D — romance proposal to lover

Completed in commit `685d88a0`.

- One canonical `RELATIONSHIP_PROPOSAL` action uses production gender, player trait/social profile, NPC profile, and mutual orientation compatibility.
- Eligibility uses friend bond, approval `85`, respect `60`, familiarity `80`, standing/availability/family gates, and cooldown.
- Acceptance is server-authoritative, deterministic, bounded, and personality-aware.
- Acceptance promotes friend to lover and records event, memory, revision, and persistence state. Rejection preserves friend and applies cooldown.

## P11E — live relationship preview and Compare

Completed in commit `2296eaf9`.

- Non-persisted `RELATIONSHIP_PREVIEW` uses the production standing resolver and proposal policy while sliders move.
- The workbench shows standing reason, friend progress, compatibility, proposal thresholds, cooldown, availability, Apply, Apply + Replay, and optional debounced Auto replay.
- Compare runs the real Lua worker and reports NPC response, semantic choices, SpeechStyleContext, relationship state, durable bond, and runtime graph path.

## P11F — unified runtime dialogue graph

Completed in commit `ada3b647`.

- `hello` projects the actual greeting semantic Flow with current, visited, completed, and future transitions.
- What's Up projects the real provider/candidate semantic Hub graph and preserves visited/completed history after route closure.
- Authored ConversationBlock projections continue through the same graph interaction path.
- Tk graph adapters share the `semantic_flow`, `semantic_hub`, and `conversation_block` renderer family.

## P11G — modular speech realization packs

Completed in commit `3499ffc8`.

- One SpeechRealization registry, resolver, fallback, and translation path remain in place.
- Built-in phrase content is split into cohesive Status, Social, Knowledge, and Actions packs with shared builders.
- Catalog validation reports 39 registered families across 15 coverage domains; EN/TL family-address behavior remains covered.

## P11H — final runtime-parity usability gate

Completed locally on ProjectHoomans `main`.

- Full Python/Tk discovery under Xvfb: **412/412 passed**.
- Focused P11A-G and P10 regression suite under Xvfb: **70/70 passed**.
- Embedded semantic Lua suite: **73/73 passed**.
- Relationship, translation, starting-companion, authority, and inventory Lua suites: **54/54 passed**.
- Doctor: all required checks passed; only the optional active-venv check was unavailable under the system interpreter.
- Full-mod Kahlua verification: **3,086 Lua files, zero findings**.
- Dedicated Kahlua lint: zero findings.
- Changed-file `luac5.3 -p`, Python compilation, and `git diff --check`: passed.
- EN/TL catalog validation: **35/35 matching files, zero key mismatches**.
- Speech catalog validation: **39 families, 15 coverage domains**.
- Normal relationship catalog validation: `mother`, `father`, `sister`, `brother`, `friend`, `lover`; no hypothetical future kinds.
- Privacy, stale/replay, gameplay authority, structured inventory, Advanced JSON, persistence/migration, friend promotion, romance compatibility/acceptance/cooldown, family exclusion, starting relationships, graph history, and P10 contextual hub regressions are covered by the completed suites.
- Duplicate-state scan found no bond, personality, or conversation-graph ModData persistence. Existing unrelated knowledge/runtime ModData boundaries remain unchanged.

## Post-P11 Semantic Lab usability polish

Completed locally on ProjectHoomans `main`.

- NPC trait selection now displays production registry effects and requests a non-persisted production personality preview; generated sliders update automatically while remaining read-only until override is enabled.
- Relationship controls use a readable single-column layout with wrapped preview text instead of clipped two-column rows.
- Player display name and player/NPC harness IDs derive from the actor name fields; derived controls are visibly marked and not manually editable.
- Apply and Apply + replay show the number of pending edits and a clear staged/applied status.
- Trait effects are bounded in a scrollable read-only pane so minimum-size Simulation keeps conversation and runtime controls visible.
- Focused Tk/Xvfb regression suite after the polish: **18/18 passed**.

## Cross-process harness activity observability

Completed locally on ProjectHoomans `main`.

- GUI, CLI, and direct `LuaSemanticWorker` clients now append to one bounded per-repository JSONL activity stream in the user state directory.
- The Log tab reads events from other live sessions and identifies the client, session, worker PID, request ID, command, and bounded action details.
- CLI agents can use `--activity-client agent`, and `--activity-log PATH` is available when a shared stream must be explicit.
- Clear view removes rendered entries without deleting another session's shared history.
- Real Tk/Xvfb cross-process smoke passed: a separate `agent` event appeared in the open GUI Log tab.
- CLI shared-stream smoke passed with `--trace`, real Lua worker startup, request/response events, and `hello`.
- Shared activity writes are lock-protected and rotate after the bounded file size limit; activity failures do not interrupt harness work.

**Current exact next chunk:** user review of the open GUI Log tab while a separate CLI/agent harness session runs, followed by user-owned native Project Zomboid SP/MP validation.

## Handoff condition

P11A-P11H and the requested Semantic Lab usability polish pass locally. **READY FOR USER LIVE TEST** remains valid for user-owned native Project Zomboid SP/MP validation. The agent did not operate native Project Zomboid and does not claim SP/MP evidence.
