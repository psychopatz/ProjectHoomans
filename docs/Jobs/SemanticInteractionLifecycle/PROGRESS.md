# Semantic Interaction Lifecycle — Current Progress

## Current regression status — READY FOR USER LIVE TEST (2026-10-25)

The newer native screenshots supersede the earlier READY conclusion. The
developer-side repair now covers request-time native lease renewal, semantic
root reprojection after rejected/stale requests, a bounded grounded `What's
up?` response/realization path, and preservation of typed landing shortcut
frames through native/group submission. Native companion authority projection
also now falls back to the replicated conversation snapshot when a target
entry has no local `record`; this keeps the semantic Orders hub eligible for
the same native companion shape that can still expose authored departure and
farewell rows.

Current evidence:

- `python3 -m unittest discover -s tools/semantic_harness/tests -p '*p12*.py' -v`: **29/29** passed, including a direct `conversation.landing:whats_up` click and the Companion Orders hub.
- Focused production Lua semantic/lifecycle/address/speech/emote/location suite: **12/12** passed.
- `pz_verify --kahlua --severity ERROR`: **3,103** Lua files scanned, **0** errors.
- `git diff --check`: passed.
- No source save was mutated and no native Project Zomboid session was launched by this agent.

The isolated `pnc_conversation_smoke` run still reaches its known separately
supplied-Core failure at the legacy Ask About assertion because
`PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationLLMInput` is not
present in that test environment; the new snapshot-only companion authority
assertions execute before that dependency-bound failure.

Exact Next Chunk: **native SP/MP user-owned acceptance** of the repaired root
projection and end effects: `What's up?` semantic response variants,
Companion Orders, Farewell close, Leave Group warning/confirm/departure, emote
speech delivery, unknown-address variation, mutually exclusive Follow/Wait,
Go Home, and dynamic Camp destinations. No further developer-implementable
mandatory P12B–P12H change is identified by the current production-Lua and
harness evidence.

**Current developer status (2026-10-25): READY FOR USER LIVE TEST.** Newer native evidence showed that the companion Orders/Camp click could enter the semantic router but then be rejected as stale by the native projection (`requestRevision=0`, `currentRevision=1`), leaving only `Let's talk something else` visible. The production navigation bridge now rebuilds the bounded semantic projection at the post-navigation revision before applying the requested group, so the native Core surface does not compare a new semantic turn against the pre-turn menu.

**P12 location observation correction (2026-10-25):** Dynamic Camp and future location/navigation dialogue now share `PNC.Semantics.LocationObservation`. The client adapter reuses existing `CampSiteHints`/`CampSiteGeometry`, returns only bounded primitive location/CampSite observations, caches the loaded-cell read briefly, and re-observes generated snapshots rather than treating them as durable state. If the loaded room index omits the player's current room, dynamic Camp reuses the existing nearest-room resolver before campfire fallback. The harness fixtures this same compact observation contract; Python still does not discover maps, select capabilities, or execute Camp authority.

**P12F/P12G/P12H developer evidence (2026-10-25):** Production worker P12 acceptance is 39/39, including Orders/Camp navigation, location-observation Camp fixtures, authoritative Follow/Wait/Go Home/Camp refresh, and native-effect mutation routes. Focused production Lua tests are green, including the location-observation and Camp fallback regressions. `pz_verify` scans 2,992 Lua files with 0 Kahlua errors and `git diff --check` passes. No developer-implementable mandatory P12 work remains. **Exact Next Chunk:** Native SP/MP user-owned acceptance. No source save was mutated, no native game session was launched by this agent, and no Workshop operation was performed.

**Native dynamic Camp discovery correction (2026-10-25):** Native evidence showed the authoritative `camp here` path could resolve the nearby hallway and commit Camp, while the Orders menu produced no destination rows. The client enumeration adapter was passing the literal fallback query `"room"` into room description; that became a room-name filter and rejected valid room types such as `HALLWAY`. Dynamic enumeration now leaves the query unset unless the player supplied one, so it projects all valid bounded loaded rooms while preserving stable primitive targets and server revalidation.

**Developer status:** READY FOR USER LIVE TEST. P12F native-menu discovery correction is complete developer-side; native SP/MP execution remains user-owned.

**Native emote delivery correction (2026-10-25):** New native evidence showed the semantic NPC reply was selected but dropped before visible delivery. The player emote occupied Core's critical `emote_interaction` queue path while the already-resolved NPC reply used the default ambient priority/family arbitration, so the reply could be discarded by family/cadence suppression. The shared semantic speech seam now protects selected semantic speech at interaction priority, gives player-emote replies a distinct `emote_interaction_reply` family, pumps that reply immediately, and marks the player-emote result as the single diary owner. Focused emote/speech tests, the broader P12 acceptance suites, and full Lua Kahlua validation pass after this correction.

**Developer status:** READY FOR USER LIVE TEST. P0–P11 remain retained foundation; P12B–P12H developer-side acceptance is complete after the native emote delivery correction. Native SP/MP execution remains user-owned.

**Current Next Chunk:** Native SP/MP user-owned acceptance. No developer-implementable mandatory P12 chunk remains.

**Post-handoff correction (2026-10-25):** Player-emote target formatting routes unrevealed NPCs through the shared semantic address resolver, so the internal `Unknown survivor` transport placeholder cannot appear in rendered emote speech. The player-emote speech path now also selects `semantic.emote.player` response-plan/realization provenance before the existing authored Flavor content alias renders localized wording. Known names remain unchanged, bounded per-NPC address history is preserved, and the native gesture/gameplay dispatch remains unchanged. Focused presentation/address/realization tests, production semantic-Lua tests, and the 31-test P12 harness pass after the correction.

**Native companion-root correction (2026-10-25):** The P12E Orders hub was present in the shared semantic projection and Semantic Lab, but native Conversation definitions were leaving `actorAuthority` and the bounded companion state nested under the authored composer context. Native semantic eligibility therefore hid `companion.orders:open` even for an owned companion. The production Conversation context now promotes the authoritative authority/follow/health snapshot to the semantic projection, with a compatibility promotion for older nested contexts. The native-shaped Conversation regression and the full 31-test P12 harness pass after this correction.

**Semantic navigation exchange correction (2026-10-25):** Companion Orders, dynamic Camp, and Back navigation were still being treated as presentation-only group clicks. They now enter the same semantic input/policy/realization path as other selected meanings: the player navigation utterance is recorded once, one contextual NPC acknowledgement is delivered, and the target group is reprojected from current authoritative state. `Let's camp...` consequently opens the bounded valid-site branch, an empty site set produces a spoken fallback, and `Let's talk something else` returns to the landing group with an appropriate reply.

**Updated:** 2026-10-25

**Developer status:** READY FOR USER LIVE TEST. P0–P11 remain retained foundation; P12B–P12H developer-side acceptance is complete, including the native companion-root and semantic-navigation exchange corrections above. Native SP/MP execution remains user-owned.

**Current Next Chunk:** Native SP/MP user-owned acceptance. No developer-implementable mandatory P12 chunk remains.

**Accepted predecessor foundation:** Contextual Dialogue Persona & Choices P14. Its save-backed production rehydration architecture remains intact.

**Current parity-audit baseline:** `bc13d3775cb03816d34dafce6e676d278de5997e`

**Checkout:** existing `main` only. No branch, source-save mutation, Workshop upload, or native game launch was performed.

## P12 — native action & semantic capability standardization

**Status:** COMPLETE developer-side. P12B–P12H have no remaining developer-implementable mandatory work; native SP/MP acceptance remains the next user-owned step.

Initial native user evidence and source audit identified:

- **That's all. Stay safe.** is presented but does not close the native Conversation UI.
- **Tell them to leave the group** does not complete the expected authored departure behavior.
- semantic emote `resolvedText` can be selected without being visibly enqueued/spoken.
- internal `Unknown survivor` identity can leak into conversational address outside the normal Conversation identity adapter.
- root semantic capability projection exposes Follow / Stay / Wait independently instead of a contextual companion-order hierarchy.
- existing authoritative Camp and Return Home commands already exist but are not represented in the desired semantic command hub.
- existing CampSite room vocabulary, room enumeration/projection, client hints and server resolver already support dynamic validated room/campfire targets and should be reused.
- the semantic authored-choice bridge can execute an original authored choice through nested/re-entrant `Session:selectChoice`, which risks overwriting `response`, `next`, `close`, `closeReason`, highlight and pending lifecycle state.

Detailed P12 design is in `NATIVE_ACTION_CAPABILITY_STANDARDIZATION.md`.

### P12B — authored action/capability execution bridge

**Status:** COMPLETE developer-side. The native semantic root row now maps to the current normalized authored Core choice, executes its authored action inline exactly once, and leaves the same Core selection responsible for response, next, close, closeReason, logging, enabled state, and highlight hooks. The bridge does not call `Session:selectChoice(originalChoice)` from inside the semantic row execution. Authored normalized choices are retained only as runtime presentation state; semantic persistence remains bounded and frame-based.

Existing gameplay/domain executors remain authoritative. The worker now loads the production ColonistDeparture service for this acceptance surface, and optional raw faction/community fixture registries hydrate through the production owners without a harness-side gameplay implementation.

Developer evidence:

- `lua tests/pnc_semantic_dialogue_input_smoke.lua`: focused native-shaped bridge regression passes; Goodbye action/response/close/highlight execute once and `Session:selectChoice` is entered once.
- `lua tests/pnc_conversation_authority_smoke.lua`: departure warning/confirm path passes; warning does not mutate, confirmation delegates once, forwards relationship penalty, and returns `colonist_departed` close reason.
- `lua tests/pnc_colonist_departure_conversion_smoke.lua`: existing authoritative departure service performs the real ownership/faction conversion.
- `python3 -m unittest tools.semantic_harness.tests.test_contextual_talk_parity_p11j`: production worker parity and Goodbye session closure pass.
- focused P14 rehydration tests and the P12B Lua set pass after worker production-service hydration; `pz_verify` reports zero Kahlua errors for changed production Lua; `git diff --check` passes.

No source save was mutated, no native Project Zomboid session was launched, and no Workshop operation was performed.

### Exact Next Chunk — P12C

### P12C — semantic speech delivery

**Native evidence correction:** The first delivery implementation proved only that a result/diary record existed; native Core arbitration could still suppress the visible NPC line after the player emote. The shared delivery seam now carries explicit interaction priority and zero interaction cooldowns for already-selected semantic speech. Player-emote NPC replies use a distinct queue family, immediate pumping, and explicit delivery ownership so the reply is visible once without a second ambient diary write.

**Status:** COMPLETE developer-side. Already-selected semantic NPC speech now has one bounded delivery seam. Active Conversation sessions receive one NPC message directly; otherwise the existing social presentation receiver routes the same selected text to world nameplate/bubble and shared TTS. The seam carries response-plan, realization, beat/topic, fact-reference, and interaction provenance without selecting legacy Flavor content.

Developer evidence:

- `lua tests/pnc_semantic_speech_delivery_smoke.lua`: active-session and world-presentation routes accept the same resolved text, preserve semantic realization provenance, and deliver once.
- `lua tests/pnc_semantic_emote_result_delivery_smoke.lua`: native-shaped authoritative emote result with `resolvedText` is visibly delivered once, recorded once, and does not call NPC Flavor resolution; duplicate result delivery is suppressed.
- `python3 -m unittest tools.semantic_harness.tests.test_contextual_talk_parity_p11j`: production worker selects the active-beat `semantic.emote.reply.thumbsup.active` realization and projects exactly one newly delivered NPC line with the resolved text.
- focused P12B/P12C Lua suite, P14 rehydration/faction tests, `pz_verify` Kahlua checks, and `git diff --check` pass.

No source save was mutated, no native Project Zomboid session was launched, and no Workshop operation was performed.

### Exact Next Chunk — P12D

### P12D — semantic address resolver

**Status:** COMPLETE developer-side. `PNC.Semantics.AddressResolver` now separates transport/debug identity from player-facing address. Known names are returned only when the existing identity-knowledge projection authorizes them; unknown or placeholder values produce constrained localized terms. Relationship, gender when authoritative, formal/casual/slang tone, and bounded recent-term history control the result. No names, titles, or identity facts are invented, and only compact address IDs are retained for anti-repeat behavior.

The resolver is applied to semantic Conversation identity arguments and farewell context. The internal `Unknown survivor` value is rejected before it can enter normal dialogue; unknown surnames remain empty rather than fabricating identity. Existing player-address behavior remains separate and unchanged.

Developer evidence:

- `lua tests/pnc_semantic_address_resolver_smoke.lua`: unknown, known, gender-neutral, formal, friendly/slang, hostile, placeholder-rejection, and bounded anti-repeat cases pass.
- `lua tests/pnc_conversation_smoke.lua`: known identity remains `Morgan Hale`; unrevealed identity projects `Stranger` without leaking `Unknown survivor` and without inventing a surname.
- `lua tests/pnc_conversation_farewell_smoke.lua` and `lua tests/pnc_semantic_identity_knowledge_mirror_smoke.lua` pass with the resolver integrated.
- production Lua `pz_verify` Kahlua checks and `git diff --check` pass.

No source save was mutated, no native Project Zomboid session was launched, and no Workshop operation was performed.

### P12E — Companion Orders semantic hub

Status: complete. The production semantic projection now exposes one contextual `companion.orders` navigation capability at the native Conversation root, with `Follow me.` and `Wait here.` mutually exclusive from authoritative movement state. Native Conversation definitions now promote the authoritative companion authority/follow/health snapshot into the semantic context so the root is not silently filtered; the shared/headless projection and native Core presentation use the same row. `Let's camp...` opens the bounded `companion.camp` branch, and `Go home.` routes through the existing `return_home` capability/command adapter. Generic `WAIT_AT` remains available for explicit destination requests but is not a permanent menu row. The active orders group is preserved through capability refresh and Back navigation; no gameplay executor was duplicated.

The post-handoff correction makes Orders, Camp, and Back navigation semantic exchanges rather than local toggles. Each accepted navigation frame uses the existing semantic group submission path, produces one contextual NPC acknowledgement, and then reprojects the requested group. This prevents the native Conversation log from showing a silent player-only click.

Evidence:

- `python3 -m unittest tools.semantic_harness.tests.test_companion_orders_hub_p12e`: 3/3 passed, including root flattening, real Follow/Wait command mutations and reprojection, Camp branch navigation, and Go Home transport/state mutation.
- `python3 -m unittest tools.semantic_harness.tests.test_follow_action_binding tools.semantic_harness.tests.test_stay_wait_at_binding`: 7/7 passed.
- `python3 -m unittest tools.semantic_harness.tests.test_contextual_talk_parity_p11j`: 22/22 passed after the native parity assertion was routed through the production Companion Orders hub.
- The corrected navigation assertions cover one player line plus one NPC acknowledgement for Orders, Camp, Back, and empty-Camp fallback; the combined P12 acceptance run is 31/31.
- `python3 tests/run_tests.py --jobs 1 --max-output-lines 200 --verbose pnc_conversation_smoke pnc_semantic_response_catalog_smoke pnc_semantic_realization_authority_smoke pnc_semantic_player_emote_realization_smoke pnc_vanilla_emote_presentation_smoke`: passed; the production Conversation definition regression verifies native `actorAuthority`, `npcState.followState`, and `npcState.healthState` promotion, so the native semantic root can retain the eligible Orders hub row.
- The focused production-Lua Conversation/semantic suite passed; the separate broad `pnc_companion_command_interaction_smoke` invocation remains blocked by the supplied checkout's missing `PsychopatzCore/Events/PC_EventBus` dependency and is not counted as a P12E failure.
- `pz_verify --kahlua --severity ERROR --no-snippets` passed for the changed P12E suggestion, capability-provider, input, lifecycle, and native Conversation lifecycle Lua files; `git diff --check` passed.

### Exact Next Chunk — P12F

Project dynamic Camp destinations into the existing `companion.camp` semantic branch using production CampSite/CampSiteGeometry/client hints/server resolver/authoritative `CompanionCommands.camp`. Present only valid bounded rooms/campfires; send a primitive stable target/hint; server re-resolves and revalidates it; commit the actual Camp order; reject stale or invalid selections safely.

### P12F — Dynamic Camp destinations

**Native menu correction evidence:** `ClientCampSiteHints.Enumerate` now discovers all valid loaded rooms when no specific room query is requested. The previous `room` fallback was incorrectly interpreted as a name filter, hiding valid `HALLWAY`/other room types from the dynamic `Let's camp...` branch. The direct `camp here` path remains unchanged and continues to send a primitive hint for server re-resolution.

Focused evidence after correction: Camp production Lua smokes 7/7; Camp/Orders/native-effect harness subset 9/9; full P12 effect/refresh/Camp/Orders/parity 31/31; lifecycle/mutation/fixture 8/8; full Lua Kahlua validation 2,991 files with 0 errors; `git diff --check` passes.

**Status:** COMPLETE developer-side. The semantic camp branch now projects bounded dynamic room/campfire destinations from the existing production CampSite stack. `CampSiteGeometry.EnumerateRooms`, `Geometry.DescribeRoom`, client CampSite hints, the stable primitive target, server `CampSiteResolver`, and authoritative `CompanionCommands.camp` remain the execution chain; no second Camp executor or Java room object was introduced. Dynamic rows remain inside `companion.camp`, never on the root or Orders landing surface. Duplicate room types are bounded and keyed by stable site/room identity. A selected primitive is carried as `campSiteHint`; the existing server-side resolver remains responsible for independent re-resolution and stale/invalid rejection before order mutation.

Developer evidence:

- `python3 -m unittest tools.semantic_harness.tests.test_dynamic_camp_destinations_p12f`: 3/3 passed. Production Lua projected only the supplied living-room and kitchen destinations, omitted an unfurnished bedroom, transported the selected `siteID`/`roomID` primitive through `PNC.Client.SendCompanionCommand`, applied the simulated real camp-order state patch, delivered one NPC acknowledgement, and preserved stale-result rejection without mutation; an empty valid-site set receives a spoken fallback rather than fabricated rows.
- `PZ_TEST_CORE_REPOSITORY=/home/psychopatz/Zomboid-devSkills python3 tests/run_tests.py --jobs 1 --verbose pnc_companion_camp_site_hint_smoke pnc_semantic_camp_site_hint_client_smoke pnc_semantic_camp_task_smoke`: 3/3 passed. These cover client primitive hint behavior and production server CampSite validation/task handling.
- `PZ_TEST_CORE_REPOSITORY=/home/psychopatz/Zomboid-devSkills python3 tests/run_tests.py --jobs 1 --verbose pnc_semantic_dialogue_input_smoke`: passed.
- Lua syntax checks, focused `pz_verify --kahlua --severity ERROR --no-snippets` checks for the changed CampSite/suggestion/action-target/lifecycle Lua files, and `git diff --check` passed.
- The existing broad `pnc_conversation_smoke` and `pnc_companion_command_interaction_smoke` invocations remain environment-blocked by missing `CustomTranslationManager` / `PsychopatzCore/Events/PC_EventBus` in the separately supplied core checkout; no P12F failure was inferred from those unrelated dependency gaps.

No source save was mutated, no native Project Zomboid session was launched, and no Workshop operation was performed.

### Exact Next Chunk — P12G

Implement stateful capability refresh after every action/command: re-read authoritative movement and CampSite truth, update the Follow/Wait toggle, Camp eligibility, and Go Home eligibility, remove stale or contradictory rows, preserve the active semantic thread/beat, and keep the existing `return_home` command/task-cancellation behavior authoritative.

### P12G — Stateful capability refresh

**Status:** COMPLETE developer-side. Capability refresh now re-enumerates bounded CampSite presentation assistance after actions, applies authoritative companion-state eligibility to dynamic Camp destinations, hides Go Home once the authoritative state is already returning home, and preserves the existing Follow/Wait mutual-exclusion projection. The semantic thread/beat remains owned by the lifecycle/session state; no action-specific gameplay mutation was added to Conversation.

Developer evidence:

- `python3 -m unittest tools.semantic_harness.tests.test_stateful_capability_refresh_p12g`: 2/2 passed. Go Home uses the existing `return_home` path and the resulting `AtHome:returning` state removes the no-longer-meaningful GO capability; an authoritative busy state projects no Camp destination rows.
- `python3 -m unittest tools.semantic_harness.tests.test_companion_orders_hub_p12e tools.semantic_harness.tests.test_dynamic_camp_destinations_p12f`: 5/5 passed after the refresh changes.
- `python3 -m unittest tools.semantic_harness.tests.test_contextual_talk_parity_p11j`: 22/22 passed after the refresh changes.
- Focused production-Lua CampSite, action, speech, address, authored lifecycle, and companion authority smoke tests pass where the supplied core checkout provides their dependencies; changed Lua syntax and Kahlua checks report zero errors, and `git diff --check` passes.

No source save was mutated, no native Project Zomboid session was launched, and no Workshop operation was performed.

### P12H — Native-effect and harness acceptance

**Native emote correction evidence:** The player-emote semantic NPC reply now survives the shared SocialFlavor queue's family/speaker/ambient arbitration, is pumped immediately, and has one explicit delivery owner. Focused production checks pass: 6/6 semantic/native-shaped Lua smokes; P12 effect/refresh/Camp/Orders/parity 31/31; lifecycle/mutation/fixture 8/8; full production-Lua Kahlua validation 2,991 files with 0 errors; `git diff --check` passes.

**Status:** COMPLETE developer-side. The P12 acceptance chain is green across the production Lua authority seams and the real production worker. Farewell closes the native-shaped session, Leave Group delegates warning/confirm/departure to the existing authority path, semantic emote speech is delivered once, unknown identity uses the shared address resolver without exposing `Unknown survivor`, Follow/Wait remains mutually exclusive after real command state changes, Go Home uses the existing `return_home` command and refreshes eligibility, and dynamic Camp carries a selected primitive through the existing server-validation/task path. Typed Follow input and semantic Follow button input converge on the same `pnc:companion.follow` capability and `PNC.Client.SendCompanionCommand` executor.

Developer evidence:

- `python3 -m unittest tools.semantic_harness.tests.test_p12h_native_effect_acceptance tools.semantic_harness.tests.test_stateful_capability_refresh_p12g tools.semantic_harness.tests.test_dynamic_camp_destinations_p12f tools.semantic_harness.tests.test_companion_orders_hub_p12e tools.semantic_harness.tests.test_contextual_talk_parity_p11j`: 31/31 passed.
- `python3 -m unittest tools.semantic_harness.tests.test_semantic_interaction_lifecycle_acceptance tools.semantic_harness.tests.test_production_mutations_p12h tools.semantic_harness.tests.test_fixture_provider_p12f`: 8/8 passed, including compact lifecycle/source-save immutability and production mutation-route coverage.
- `python3 tests/run_tests.py --jobs 1 --max-output-lines 120 --verbose pnc_semantic_dialogue_input_smoke pnc_conversation_authority_smoke pnc_colonist_departure_conversion_smoke pnc_semantic_address_resolver_smoke pnc_semantic_emote_result_delivery_smoke pnc_semantic_speech_delivery_smoke pnc_semantic_group_smoke pnc_semantic_command_adapter_smoke pnc_semantic_camp_client_request_smoke pnc_semantic_camp_task_smoke pnc_companion_camp_site_hint_smoke pnc_semantic_camp_site_hint_client_smoke pnc_semantic_interaction_lifecycle_smoke pnc_semantic_realization_authority_smoke pnc_semantic_navigation_smoke pnc_semantic_response_catalog_smoke`: 16/16 passed.
- `pnc_semantic_nlu_smoke`, `pnc_semantic_wait_at_smoke`, `pnc_conversation_smoke`, and `pnc_companion_command_interaction_smoke` were dependency-blocked by the separately supplied core checkout (`PsychopatzSemantic.lua`, `CustomTranslationManager`, or `PC_EventBus` unavailable); their failures were not treated as P12 regressions. The corresponding P12 typed/action/Camp authority paths are covered by the passing production-worker and focused Lua tests above.
- Full production-Lua Kahlua validation scanned 2,991 files and reported zero errors; final `git diff --check` passes. No source save was mutated, no native Project Zomboid session was launched, and no Workshop operation was performed.

There is no remaining developer-implementable mandatory P12B–P12H work recorded in this progress ledger. Native SP/MP live acceptance remains user-owned.

### Final Handoff — native SP/MP user-owned

No developer-implementable mandatory P12 work remains; native SP/MP live acceptance is the next user-owned step.

## P0A — source-level migration and state-ownership inventory

Complete. `SOURCE_INVENTORY.md` and `MIGRATION_MATRIX.md` enumerate production flavor families, real source owners and IDs, trigger/context/resolver paths, presentation/TTS sinks, cooldown/chance/dedupe behavior, authority, gameplay effects, persistence dependencies, duplicate paths, and characterization coverage. The inventory distinguishes authoritative gameplay/domain state from presentation-only flavor state. No legacy authored line was deleted; migrated lines remain available as bounded realization variants where applicable.

## P1 — common semantic envelope and lifecycle owner

Complete. Production Lua owns `semantic.interaction.envelope.v1` and `semantic.interaction.lifecycle.v1`. Typed/headless input remains NLU-driven; semantic choices, emotes, lifecycle events, grounded events, and NPC speech enter through the same bounded envelope contract. The envelope stores meaning provenance, never rendered prose or gameplay permission.

Server-only `PNC_InteractionLifecyclePersistence` owns the sparse ModData boundary through the existing persistence coordinator. Pair capsules are created only for meaningful state, shared events use canonical references, imports/exports are bounded, and no lifecycle `OnTick` scan was added.

## P2/P3 — greeting, farewell, emote, and companion/social-reply parity

Complete. Greeting, farewell, registered vanilla emote, companion command reply, and social reply adapters retain act/topic/beat/flow/response-plan/pool/fact/event provenance while preserving existing eligibility, cooldown, chance, delay, TTL, and presentation/TTS policy. Accepted no-op emotes remain presentation-only and do not materialize a durable pair.

## P4 — grounded combat, medical, corpse, and world-event routes

Complete. Grounded event transactions bridge validated combat, treatment, incapacitation, abandonment, horde, corpse-awareness, leader-loss, faction-compatibility, and Project A-Life events into canonical world-event references and NPC-speech provenance. Existing domain owners retain gameplay effects. Client-only ambient routes remain presentation-only and do not fabricate durable gameplay state.

## P5 — bounded thread and beat continuity

Complete. Active beats, suspended topic stacks, response windows, open questions, commitments, recent semantic turns, event references, and NPC speech provenance are bounded. Topic interruption/resume works independently of visible transcript rows. Closing the UI suspends meaningful context without destroying it.

## P6 — compaction, expiry, and promotion

Complete. Resolved trivial interactions remove the pair capsule. Long conversations retain only bounded semantic residue; realization history expires lazily; significant facts, commitments, memories, and event references promote as compact durable references. Anti-repetition history is bounded and is not autobiographical transcript memory.

## P7 — sparse multiplayer persistence and isolation

Complete. Lifecycle state does not pre-create Player × NPC records, keeps pair/shared-event budgets bounded, keeps private projections isolated, and leaves dormant actors at zero lifecycle tick work. Shared event payloads are registered once and referenced by ID. Server-authority guards reject non-authoritative lifecycle mutation.

## P8 — production Semantic Lab acceptance worker

Complete. The existing production Lua worker exposes envelope, apply, NPC speech, close/resume, compaction, time, event, projection, response-window, metrics, export, and import operations. Python only transports, isolates, drives, and presents production-Lua state. Save-backed P14 rehydration tests confirm source snapshot immutability.

## P9 — legacy authority retirement boundary

Complete for the audited families. Legacy registries, EN/TL lines, timing gates, and compatibility shims remain only where they are still the correct realization/provider or external-domain boundary. Duplicate lifecycle/state authority and prose-reparse paths are retired; ConversationBlocks, gameplay domains, network authority, and existing presentation/TTS ownership remain authoritative in their existing locations.

## P11 — legacy semantic authority consolidation

**Status:** COMPLETE for developer-side acceptance; P11A–P11H pass for the
current bounded production inventory. Native SP/MP acceptance remains
user-owned.

The completed slices moved greeting, farewell, emote, companion/social
acknowledgement, combat, medical/distress, leader-loss/grief, follower,
corpse, medical-supply, and compatibility event-family realization through the
canonical semantic boundary. Legacy role/tier helpers have no production
callers; authored Flavor/SocialFlavor definitions and renderer fallbacks remain
only where they are content/presentation/compatibility paths.

The remaining work is repository hygiene and combined no-split acceptance, not
re-running the superseded P0–P9 goals.

See `LEGACY_SEMANTIC_AUTHORITY_CONSOLIDATION.md`.

Any P9 statement that legacy semantic authority was fully retired is superseded. P9 remains accepted for lifecycle/provenance/persistence integration only.

P10B–P10H production/session parity and P11A–P11H single-authority acceptance
are complete for the current bounded inventory. No developer-implementable
mandatory chunk remains before the user-owned native handoff.

Attaching a semantic envelope to an already legacy-selected flavor ID does **not** satisfy P11.

## P10 — native Conversation parity correction

**Status:** COMPLETE for developer-side acceptance.

The first user native/harness comparison supersedes the previous final handoff.

Verified mismatches:

- native production showed the staged Pete Patz opening and a three-row Response Channel for the captured state;
- Semantic Lab exposed a much broader candidate surface;
- production \`buildCoreChoices\` selects the current semantic group, while current Tk suggestion rendering can use the global candidate projection when no explicit group override exists;
- harness clickability is gated by worker response type instead of the production presented-choice/session validity contract;
- normal control re-enable paths call splitter restoration and can overwrite a user's current drag with persisted sash state;
- hiding workbench contents can leave the bottom PanedWindow allocation in place, producing large wasted space;
- World Browser relationship/role classification still exists in code but can appear absent because the persisted "Saved affiliations" lens replaces the visible hierarchy.

Detailed corrective architecture and acceptance are in \`NATIVE_CONVERSATION_PARITY_CORRECTION.md\`.

P10A (reopen acceptance + freeze parity evidence) is complete as audit/documentation.

### P10B — headless production Conversation presentation projection

**Status:** COMPLETE — production Lua now exposes
\`semantic.native_conversation_view.v1\` from the live headless Conversation
session. The projection includes Talk/opening state, bounded opening messages,
relation presentation, lifecycle/busy/pending/closed state, current semantic
group/revision, exact rows held by the production-presented session after
\`PresentSemanticChoices\` / \`buildCoreChoices\`, enabled state, semantic
click frames, and typed-input availability. The worker only transports this
projection; it does not reconstruct candidate policy. Broad
\`semanticSuggestions\` remain available as diagnostics for the next seam.

Developer evidence for P10B:

- \`test_contextual_talk_parity_p11j\`: 14/14 passed;
- \`pnc_conversation_smoke\`: passed;
- \`pnc_semantic_dialogue_input_smoke\`: 1/1 passed;
- changed Project Zomboid Lua and worker Lua passed focused \`pz_verify\`
  Kahlua checks with zero errors;
- \`git diff --check\`: passed;
- the live worker returned the same Lua-owned projection through both the
  snapshot and \`CONVERSATION_PROJECTION\` seams.

### P10C — harness consumes production Conversation projection

**Status:** COMPLETE — the primary response surface now adapts only
\`conversationPresentation.responseChannel.rows\` from the production Lua
projection. Broad/global candidates remain in the diagnostic inspector and
are not rendered as player-facing primary choices. The worker now exposes an
explicit \`CONVERSATION_OPEN\` / \`TALK_OPEN\` operation; loading or
rehydrating an NPC leaves the projection in \`loaded\` with no presented rows
until this production open lifecycle is invoked. \`TALK_START\` remains the
production open-plus-typed-greeting path.

Developer evidence P10C:

- \`test_contextual_talk_parity_p11j\`: 15/15 passed;
- worker smoke confirmed loaded projection has zero primary rows and explicit
  open returns the production session rows;
- UI renderer adapter preserves production row order, enabled state, and
  semantic click frames while retaining diagnostics separately.

### P10D — click/session parity

**Status:** COMPLETE — primary clicks now submit the exact semantic frame
from the production-presented row. Production validation checks that a
conversation choice is currently presented and enabled, rejects unpresented
frames, distinguishes replayed receipts from stale revisions, and restores
the current semantic presentation after any rejected frame. The primary UI
derives interactivity from the production lifecycle and typed-input
availability projection rather than the previous worker response type.
Closed sessions no longer repopulate rows during rejection/refresh paths.

Developer evidence P10D:

- `test_contextual_talk_parity_p11j`: 18/18 passed;
- `test_contextual_suggestions_s3`: 9/9 passed;
- exact production-frame click advanced and re-projected the next session
  rows;
- stale, replayed, and unpresented frames were side-effect free;
- goodbye close cleared the production channel and explicit open restored it;
- changed Lua files passed focused `pz_verify` Kahlua checks;
- `pnc_conversation` and `pnc_semantic_dialogue_input` smoke suites passed;
- `git diff --check` passed.

### P10E — Conversation lifecycle parity

**Status:** COMPLETE — explicit open, staged opening projection, current
Response Channel, typed input, exact semantic choice, emote, terminal close,
suspend, and resume now use the production Lua Conversation session. Suspend
preserves the live semantic group and interaction thread/beat without
rebuilding the worker or resetting lifecycle state; resume restores the exact
production choice surface. Terminal close clears the channel and explicit
open starts a new production presentation.

Developer evidence P10E:

- `test_contextual_talk_parity_p11j`: 20/20 passed;
- typed input and exact semantic choice remain on the production projection;
- emote `thumbsup` produced a production lifecycle `ACK` envelope against
  the active `beat:water` thread;
- suspend exposed `suspended` with no clickable rows and preserved group,
  revision, and semantic beat; resume restored rows and beat state;
- terminal goodbye close exposed `closed` and explicit open restored the
  current presentation;
- changed Lua Kahlua checks and Conversation/Input smoke suites passed;
- `git diff --check` passed.

### P10F — conversation-first Simulation desktop UX

**Status: COMPLETE.** The Simulation screen now gives the production
Conversation surface the dominant transcript/Response Channel area and keeps
context/tools in a horizontal right-side dock. The dock is removed from the
PanedWindow when hidden, so the conversation reclaims its space. Sash changes
persist through a debounced save; geometry and splitter restoration happen at
startup or after structural changes, not after ordinary worker operations.
The primary surface has an explicit `Open conversation` action and renders
only the production presentation rows; broad candidates remain diagnostics.

Developer evidence:

- `test_simulation_workbench_p10e`: conversation-first workflow passed through
  Open Conversation, production click, typed input, setting Apply, re-open/
  continue, context switch, and return with the sash stable;
- `test_contextual_runtime_parity_p11a`: compact state/geometry persistence
  passed under Xvfb;
- `test_ui_state_persistence`: hide/show/reset layout persistence passed;
- `test_contextual_talk_parity_p11j`: production Conversation lifecycle suite
  remained green after the UI change.

### P10G — World Browser navigation repair

**Status: COMPLETE.** The saved-world browser now exposes explicit top-level
relationship navigation for Player faction/companions, Settlers/communities,
Hostile/looters, Traders/providers, Neutral/unaffiliated, Other faction
members, and Unknown/unsupported. A separate `Saved affiliations / overlays`
entry keeps persisted factions, communities, provider overlays, and other
save-backed group views reachable. Navigation changes only the read-only
presentation lens; save-backed source data remains authoritative and
immutable.

Developer evidence:

- `test_saved_world_relationship_lens_p15b`: top-level navigation filtered
  relationship categories and restored saved affiliations/overlays;
- `test_operational_world_browser_p13a`: real worker save discovery,
  selection, import, talk start, and source-save immutability passed at both
  supported geometries.

### P10H — native/harness Conversation parity acceptance

**Status: COMPLETE — developer-side production parity recorded.** The bounded
parity test compares the production Conversation projection and the thin harness
adapter for opening/provenance, relation presentation, current semantic group,
exact IDs/text/order/enabled state, revision, semantic click frame, next
choices, typed-input availability, suspend/resume, and terminal close.
`test_contextual_talk_parity_p11j` passes 22/22, including a large
save-backed payload regression proving `CONVERSATION_OPEN` returns only the
bounded production projection rather than duplicated inspector snapshots. This
is not a user-live-test handoff.

### P11A — remaining authority inventory

**Status: COMPLETE.** `P11A_FLAVOR_AUTHORITY_INVENTORY.md` records the bounded
production-Lua inventory and current re-audit. The authority test passes 11/11,
including the guard that no production caller uses the legacy emote/greeting
response helpers.

### P11B — canonical semantic realization boundary

**Status: COMPLETE for the migrated families.** Production Lua routes semantic
selection through `PNC.Semantics.RealizationAuthority`, the existing
`ResponseCatalog`, and validated `ResponsePlan` output. The boundary carries
semantic act/topic, response plan, realization family/ID, compatibility alias,
and grounded fact references before presentation.

### P11C–P11E — migrated interaction and event families

**Status: COMPLETE for the current bounded inventory.** Greeting, farewell,
emote, companion/social acknowledgement, combat, medical/distress,
leader-loss/grief, follower abandonment, corpse reaction, medical-supply,
Project A-Life, and Necroa compatibility event paths resolve semantic reaction
data before queue/network/presentation. Neutral role/tier, threat, audience,
need, and grief classifiers are context providers only. Focused production-Lua
event/interaction regressions pass 17/17.

### P11F — SocialFlavor backend reduction and no-split acceptance

**Status: COMPLETE for the current bounded inventory.** Remaining direct Flavor
calls are classified as authored-content, presentation, transport, or
compatibility fallbacks. Migrated production callers cross the canonical
semantic boundary first and cannot synthesize lifecycle provenance from a
legacy Flavor ID. The production-Lua renderer-replacement smoke test proves
that stubbing the renderer does not change the selected ResponsePlan,
realization family, or realization ID. Representative greeting, farewell,
emote, companion, combat, medical/distress, and leader-loss paths have static
semantic-boundary guards, and the existing EN/TL semantic catalogs remain
parseable and available.

Developer evidence:

- `test_legacy_semantic_authority_p11`: 11/11 passed, including
  representative family guards and EN/TL catalog-presence checks.
- Focused production-Lua event/interaction regressions: 17/17 passed.
- The renderer-replacement smoke kept the semantic plan/family/ID stable while
  the companion regression preserved the selected authored compatibility alias.

### P11G — repository hygiene

**Status: COMPLETE.** The root execution policy has one unmistakable active
Semantic Interaction Lifecycle marker. The three historical checked-in goal
prompts were renamed to `HISTORICAL_GOAL_PROMPT.md` and explicitly marked
`HISTORICAL / DO NOT EXECUTE`; the evidence is preserved and no executable
`GOAL_PROMPT.md` remains. Dependency inspection found no safely removable
duplicate harness entrypoint: canonical Python entry is
`tools/semantic_harness/runtime/worker.py`, canonical Lua bootstrap is
`tools/semantic_harness/lua/worker.lua`, and the split worker/runtime/UI
modules are actively imported or loaded by entrypoints and tests. No speculative
module deletion was made.

Developer evidence:

- `test_legacy_semantic_authority_p11`: 11/11 passed, including the single
  active-goal and historical-prompt guard.
- `rg --files -g 'GOAL_PROMPT.md'` returned no executable prompt artifacts;
  all three preserved prompt files carry the historical warning.

### P11H — no-split acceptance

**Status: COMPLETE for the current developer-side scope.** Combined acceptance
covers representative greeting, farewell, emote, companion acknowledgement and
rejection, combat, medical/distress, and leader-loss/grief families. The
semantic authority smoke proves renderer substitution cannot alter
ResponsePlan/realization selection, while the companion regression preserves
the selected authored compatibility alias. Active-beat typed/button/emote
equivalence, P10 production Conversation parity, and the required
persistence/scaling stress gates are green.

### Final developer completion audit

Current bounded evidence: `test_contextual_talk_parity_p11j` passes 22/22;
the P11 runtime parity modules pass 29/29; `test_legacy_semantic_authority_p11`
plus the focused lifecycle/dialogue set passes 34/34; the production-Lua suite
passes 874/874; 44 changed Lua files
pass `luac5.3 -p`; 27 changed Python files pass `py_compile`; full-mod
`pz_verify --kahlua` scans 3,096 files with zero errors and zero warnings; and
`git diff --check` passes. The refreshed codebase-memory generation is complete
with zero skipped or partial parses, and coverage reports `no_recorded_issue`
for all 78 changed/untracked paths. The comprehensive Xvfb discovery result is
still a historical broad-suite diagnostic rather than a P10/P11 gate; all
P10/P11 scoped production-worker modules are green. A read-only production save
selection for `/home/psychopatz/Zomboid/Saves/Sandbox/2026-10-22_08-59-28`
opened with a 64,285-byte response, six native-presented rows, and no duplicated
snapshot payload. That prior no-work/READY conclusion is superseded by P12 native evidence. Preserve the old test results as historical evidence; do not use them to skip P12.

## Post-acceptance P10 usability correction — saved opening projection

**Status:** COMPLETE. A user-run Semantic Lab screenshot exposed a
presentation defect after the P10 parity seam was otherwise correct: the
production Lua projection contained the resolved NPC opening in the top-level
`text` field, while the Tk transcript adapter only read the older nested
`payload`/`value` shape. The result was a blank `NPC:` row even though the
production session had staged the greeting. The primary response surface also
used the generic “Contextual semantic suggestions” title for a native
Conversation projection, and the adjacent Preview action did not explain its
non-mutating purpose.

The adapter now accepts the bounded production `text` field, the native
projection is labelled `Response Channel`, the action is labelled `Preview
(no send)`, and loading a saved target explains that Load rehydrates state
while Open conversation starts the native Conversation session. Preview still
uses the production Lua router/policy and does not record a turn, dispatch an
action, advance the lifecycle, or promote memory.

Evidence for this correction:

- `test_contextual_talk_parity_p11j`: 22/22 passed, including the production
  opening-to-Tk text assertion;
- `test_simulation_workbench_p10e` under Xvfb: 5/5 passed, including a real
  non-empty `NPC:` transcript, the `Response Channel` label, and the
  `Preview (no send)` control;
- direct read-only save-backed worker check for
  `/home/psychopatz/Zomboid/Saves/Sandbox/2026-10-22_08-59-28/global_mod_data.bin`
  and `npcBernardpatz_U99V`: production greeting `Hey. Need a hand before we
  wrap up?`, adapter greeting identical, six presented rows;
- P11 authority regression: 11/11 passed;
- production-Lua suite: 874/874 passed;
- changed Python files compile cleanly and `git diff --check` passes.

**Next exact chunk:** no developer-implementable P10/P11 chunk remains. The
remaining step is the user-owned native SP/MP acceptance checklist; do not
reopen or auto-start native Project Zomboid from the harness.

## Post-acceptance identity-choice correction — canonical name claim

**Status:** COMPLETE for the reported production-path defect. A live save-backed
Semantic Lab run showed that `identity.choice.real_name` reached the authoritative
identity server request without `claimedName`, so the server correctly rejected the
request as `identity_claim_missing`. The cause was headless-only: the Conversation
context builder passed the engine player proxy to the normalized player-name
adapter, while the proxy exposes names through its descriptor.

The production Lua correction now builds the semantic identity frame from the
normalized `context.playerData` record and includes that canonical name in the
frame. The server continues to re-resolve and validate the authoritative player
name; the client/harness does not grant identity trust locally.

Evidence:

- `test_semantic_identity_wellbeing_collision`: 12/12 passed, including the
  canonical frame name and accepted semantic button submission;
- focused production-Lua identity suite: 23/23 passed;
- read-only reproduction against
  `/home/psychopatz/Zomboid/Saves/Sandbox/2026-10-22_08-59-28/global_mod_data.bin`
  and `npcAbrahamMeehan_DE7J`: request carried `claimedName = "Psycho patz"`,
  server result was accepted/truthful, and the NPC response was
  `Okay Psycho, nice to meet you. I'm Abraham Meehan.`;
- no source save was modified.

**Next exact chunk:** user-owned native SP/MP retest of the corrected identity
choice, followed by the existing final native acceptance checklist. Do not treat
the earlier missing-name rejection as current behavior.

## Post-acceptance layout recovery correction — reset availability

**Status:** COMPLETE for the reported Simulation usability defect. The
`Reset layout` action was present in the Simulation toolbar but was included
in the worker-controlled disabled-button list. A worker startup failure or
busy transition therefore made the recovery action appear unavailable.

The toolbar now places `Reset layout` immediately beside `Load saved NPC`.
The advanced-layout toggle and reset action remain enabled during worker
startup, busy, and failure states because they only change local Tk layout
state. Reset also reapplies default splitter positions before persisting the
new UI state, so it cannot immediately save the broken sash that it was meant
to repair.

Evidence:

- `test_simulation_workbench_p10e` under Xvfb: 5/5 passed, including direct
  reset invocation while controls were forced disabled and adjacency to
  `Load saved NPC`;
- `test_ui_state_persistence` under Xvfb: 1/1 passed;
- `test_contextual_talk_parity_p11j` under Xvfb: 22/22 passed;
- `test_ui_organization` under a 1920x1080 Xvfb desktop: 2/2 passed; the
  default 1080-wide virtual display cannot satisfy its intentional >700px
  transcript-width assertion at a 1080px window;
- direct Xvfb recovery check confirmed a persisted narrow splitter was reset
  to the default projection and persisted at the corrected position;
- no worker state or source save is changed by the layout reset.

**Next exact chunk:** user-owned retest after restarting Semantic Lab: verify
`Reset layout` is clickable during/after a worker failure, verify it is beside
`Load saved NPC`, and verify it restores the conversation-first layout.

## Developer-side evidence

See `DEVELOPER_ACCEPTANCE.md` for the exact command log and scenario mapping.
Earlier P0–P9 results remain historical evidence and are not used to skip the
P10/P11 corrective audit.

## Previous P0–P9 handoff status

The former “no further developer-implementable chunk remains” conclusion is
superseded by P10/P11. Preserve the recorded P0–P9 verification as historical
implementation evidence; do not use it to skip the active native-parity and
single-authority acceptance.
## Current regression status — IN PROGRESS (2026-10-25)

Newer native evidence supersedes the previous READY conclusion. An active native conversation can still lose its lease before a root capability click (`Work / Orders` rejected with `invalid_lease`), authored root rows can reappear after rejection, and `What's up?` still falls through to the generic `Let me think about that.` response. P12H regression repair is reopened.

Exact Next Chunk: P12H regression repair — make active-conversation lease renewal authoritative at request time, route `What's up?` through a grounded semantic response/realization pool, and restore the semantic root projection after rejected or stale requests; then run native-shaped and focused production evidence.
