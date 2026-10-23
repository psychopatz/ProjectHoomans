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

## P11 continuation — reusable Simulation workbench correction

Completed locally on ProjectHoomans `main`.

- Added a reusable `WorkbenchPage` component with shared section, two-column, stacked, summary, and scrollable viewport layout behavior.
- Needs pages now use full-width actor-owned sliders, preventing label/value collisions at 1080x700 and 1280x800.
- Personality & Traits pages group registered traits, production effects, personality source, derived social profile, and generated personality controls; NPC trait selection refreshes production preview sliders automatically.
- Player trait selection now uses the same `PERSONA_PREVIEW` worker route to expose the production social profile, conflicts, and fingerprint in the workbench.
- Derived player ID/display name and NPC ID controls remain in the worker catalog for Advanced JSON/diagnostics but are hidden from normal workbench/settings editing; first/surname remain editable and continue to derive identity values.
- Real Tk/Xvfb smoke passed at 1080x700 and 1280x800, including hidden derived controls, full-width needs, scrollable personality controls, player trait profile feedback, and NPC Berserker preview (`aggression` 0.4505 → 0.6005).
- Focused regression suite under Xvfb: **15/15 passed**; `luac5.3 -p`, Python compile, worker catalog/preview smoke, and `git diff --check` passed.

**Current exact next chunk:** user review of the updated Simulation workbench at normal and minimum desktop sizes, followed by any remaining visual adjustments before native Project Zomboid SP/MP validation.

## Handoff condition

P11A-P11H runtime parity and the current Semantic Lab workbench continuation are locally validated. Native Project Zomboid SP/MP remains **UNTESTED / user-owned**; no new READY claim is made by this workbench correction.

## P11I — deterministic identity choices and shared Core content seed boundary

First implementation slice completed across `psychopatzCore` and Project Hoomans `main`.

- `PsychopatzCore/Content/PsychopatzDeterministicContent.lua` now owns versioned save-seed resolution, canonical seed composition, bounded hashing/index/range/choose primitives, native `SurvivorFactory` name-pool reading, and deterministic name generation.
- Native name-pool selection reads `SurvivorFactory.FemaleForenames`, `MaleForenames`, and `Surnames` without calling `CreateSurvivor`; the current save seed comes from `WorldGenParams.INSTANCE:getSeedString()` when no explicit scenario seed is supplied.
- Project Hoomans identity aliases use `saveSeed + player identity seed + namespaced attempt` and are recomputed by the server. Alias text is not stored in ModData.
- Pending identity now presents exactly three provider-backed semantic frames: real name, rude refusal, and deterministic generated alias. The existing semantic identity request and server authority route remains the only mutation path.
- NPC generated names use the same Core-backed deterministic name boundary while native SurvivorFactory remains available for appearance and voice data.
- Harness context and observation projections carry the authoritative pending identity state, so direct Lua, CLI worker, and GUI worker suggestions use the same three-choice provider path.
- Focused evidence: Core deterministic content smoke **PASS**; Hoomans identity-choice smoke **PASS**; Python identity/wellbeing suite **10/10 passed**; worker suggestion-click smoke covered all three frames and server identity request dispatch; changed Lua `luac5.3 -p` **PASS**; targeted `pz_verify` Kahlua scans **PASS**; translation JSON and `git diff --check` **PASS**.
- The repository-wide `tests/run_tests.py` command remains unavailable in this checkout because it imports the missing pre-existing `tools.semantic_harness.suite` module; direct focused tests were used and this runner issue was not changed.

## P11I follow-up — deterministic first-name and surname overrides

Completed locally on ProjectHoomans `main` and psychopatzCore `main`.

- Core `DeterministicContent.GenerateName` now accepts canonical `firstName` and `surname` overrides, plus `forename` and `lastName` aliases for SurvivorDesc-style integrations. An omitted component remains derived from save seed, identity seed, namespace, version, gender, and archetype.
- Project Hoomans `PNC.Identity.GenerateResolvedIdentity` and `PNC.IdentityNames.Generate` pass partial overrides through the Core boundary instead of falling back to the native factory's unseeded name.
- Starting Companion family construction passes the authored player's surname into the identity factory for `mother`, `father`, `sister`, and `brother`; the existing persisted-record repair path remains in place.
- Focused evidence: Core deterministic content smoke **PASS**; Hoomans deterministic identity smoke **PASS** including surname-only and first-name-only overrides; Starting Companion and family appearance smoke **PASS**; changed Lua `luac5.3 -p` **PASS**; targeted Kahlua verification **PASS**.

## P11I follow-up — identity lie choice harness parity

Completed locally on ProjectHoomans `main`.

- The identity lie choice continues through the generated alias in its canonical `SemanticIdentityRequest`; it no longer relies on a generic acknowledgement path.
- The false-name response is restored to the former concise disbelief behavior: `I don't believe you.` with the matching TL catalog entry.
- Focused worker regression: **11/11 passed**, including generated-alias request payload, server rejection, trust consequence, and cleared pending exchange.
- Real Tk/Xvfb regression: **7/7 passed**, including clicking the visible `identity.choice.lie_name` row and verifying the rendered NPC response.
- EN/TL response JSON parsing and `git diff --check`: **PASS**.

**Current exact next chunk:** add the Core-facing deterministic content adapters for NPC backstory/flavour projections, then validate the remaining identity and native Project Zomboid integration paths.

## P11I follow-up — activity-log startup regression correction

Completed locally on ProjectHoomans `main`.

- Root cause confirmed: the shared GUI/CLI activity poll reparsed the complete JSONL history every 150 ms on the Tk thread. The local stream reached about 1.77 MB and 7,122 records, with each poll measured around 74 ms before the correction.
- `ActivityLog.new_shared_events` now reads the bounded historical window once and advances a file cursor for appended records; file identity, size, and first-record signatures detect truncation or rotation.
- Focused activity-log tests: **2/2 passed**, including append-only polling and cursor reset after truncation.
- After the first read, repeated polling measured about **0.04 ms** instead of 74 ms; identity regression **11/11**, formatter regression **2/2**, and Tk/Xvfb interaction **7/7** passed.

**Current exact next chunk:** add the Core-facing deterministic content adapters for NPC backstory/flavour projections, then validate the remaining identity and native Project Zomboid integration paths.

## P11I follow-up — readable tool/action transcript entries

Completed locally on ProjectHoomans `main`.

- Added one reusable bounded formatter for transcript tool/action calls across typed input, semantic suggestion clicks, and graph clicks.
- Tool entries now show the contract, status, authority/source route, compact input, response text, relationship changes, and resulting relationship state as readable lines.
- Large nested snapshots and transport/session tokens remain available in the structured inspector and are omitted from the visible conversation transcript.
- Focused formatter tests: **2/2 passed**; real Tk/Xvfb contextual interaction suite: **7/7 passed**; live worker sample confirmed the identity request and relationship adjustment render with their response and delta.

**Current exact next chunk:** add the Core-facing deterministic content adapters for NPC backstory/flavour projections, then validate the remaining identity and native Project Zomboid integration paths.
