# Contextual Dialogue Persona & Choices — Current Progress

**Updated:** 2026-10-23
**Parent status:** REOPENED — P10 infrastructure is retained, but P11 runtime-parity, relationship, and UX acceptance is mandatory.
**Current mandatory phase:** P11E — Live relationship preview and proper Compare surface.
**Implementation baseline audited:** ProjectHoomans remote `main` at `c412d50c27a423965911e115c0947b65c1eb2b6c`.
**Native Project Zomboid SP/MP:** UNTESTED / user-owned.

## Accepted foundation to preserve

The accepted P10 foundation remains in place:

- contextual What's Up semantic hub and removal of the legacy authored What's Up category;
- registered hub and choice providers;
- typed Simulation Control Catalog;
- structured inventory and Advanced JSON;
- inline Simulation workbench Apply + Replay;
- hub diagnostics and ConversationBlock graph projection/history;
- ActorConversationContext and SpeechStyleContext;
- EN/TL realization infrastructure;
- relationship-state resolver and hysteresis;
- production trait registries, social-profile generator/resolvers, and gender/orientation compatibility math;
- server-authoritative directed relationship service and persistence;
- Dynamic Trading provider boundary and P10 regression coverage.

## Current audit findings

The P10 audit identified the remaining P11 work:

- the Simulation primary workflow was developer-centric and mixed diagnostics with conversation controls;
- the normal relationship-kind catalog exposed extensible future definitions;
- relationship sliders lacked a clear live standing and bond explanation;
- NPC personality was presented as ordinary manual numeric state even though production generates it from identity, archetype, and traits;
- durable friend and lover progression was not yet automatic and server-authoritative;
- greeting, contextual hub, and authored ConversationBlock graph paths still need one runtime-parity renderer family.

## P11A completed — truthful actor/context model and UI cleanup skeleton

P11A is complete on the local ProjectHoomans `main` checkout.

Evidence:

- `RelationshipKindRegistry` now distinguishes production-supported kinds from extensible diagnostic definitions. The normal catalog contains exactly `friend`, `lover`, `mother`, `father`, `sister`, and `brother`.
- The Simulation workbench now presents `NPC Target`, `Player`, `Relationship`, and `World` panels, with `Overview`, `Needs`, and `Personality & Traits` actor tabs.
- Preview is beside Send; Snapshot and Restart worker are in `Diagnostics / Worker`; World Knowledge refresh is in the World Knowledge inspector; Persona Matrix/Sweep/Capture baseline now have an explicit Compare surface.
- Apply, Apply + Replay, structured inventory, and Advanced JSON paths remain present.
- Added `test_contextual_runtime_parity_p11a.py` with worker catalog assertions and real Tk/Xvfb navigation checks at 1080x700.

Validation:

- 23 focused Python/Tk tests passed across P11A, P10C, P10E, P8A, P8D, and S4.
- `py_compile` passed for the changed Python modules and tests.
- `luac5.3 -p` passed for the changed Lua files.
- `git diff --check` passed.

Native Project Zomboid SP/MP remains UNTESTED / user-owned.

## P11B completed — first-class actor needs and production personality

P11B is complete on the local ProjectHoomans `main` checkout.

Evidence:

- Player and NPC Target now own Hunger, Thirst, Fatigue, Stress, Boredom, and Panic in the scenario model. Legacy `world.*` values remain readable as compatibility fallbacks.
- Player trait options come from `PNC.SocialTraits.GetDefinitions()` and feed the production `ResolveTraits` path. Derived orientation, romance style, jealousy style, social style, and food preference are read-only projections.
- NPC traits, identity seed, archetype, and generated personality use the production trait effects and social-profile generator. Generated mode is the default; manual personality values remain locked until `Override generated personality` is enabled.
- The actor projection, Simulation Control Catalog, and Tk workbench expose the same derived state without creating a second authority.

Validation:

- `test_contextual_runtime_parity_p11b.py`: 3/3 passed, including production trait resolution, generated NPC defaults, and real Tk override gating.
- The combined P10/P11 focused checks passed 26 tests before P11C changes; the P11C regression run is recorded below.
- `py_compile` and `luac5.3 -p` passed for the changed P11B modules.

Native Project Zomboid SP/MP remains UNTESTED / user-owned.

## P11C completed — durable automatic friend bond

P11C is complete on the local ProjectHoomans `main` checkout.

Evidence:

- Durable bond schema version 1 is normalized on the existing directed relationship record. The social schema migrated from version 3 to 4; no second bond database was added.
- Server relationship commits evaluate the named approval 80, respect 50, and familiarity 60 gate. Promotion writes `bond.class = friend`, a bounded `friendship_established` memory/event, and normal relationship/social revisions.
- Bond promotion is one-way durable history: later standing deterioration can reach `enemy` while the friend bond remains. Starting Companion friend, lover, mother, father, sister, and brother seeds use the same existing record and current production kinds.
- ActorConversationContext and the Semantic Lab projection expose the durable bond. Direct arbitrary bond editing remains an Advanced/diagnostic path.

Validation:

- `test_contextual_runtime_parity_p11c.py`: 4/4 passed, covering below-gate, promotion, deterioration retention, all starting-bond kinds, persistence round-trip, and real Tk Apply projection.
- Production relationship Lua files, worker files, and scenario session passed `luac5.3 -p`.
- The P10 regression set and P11A/P11B suites remain part of the next combined regression run.

Native Project Zomboid SP/MP remains UNTESTED / user-owned.

## P11D completed — romance proposal and deterministic lover progression

P11D is complete on the local ProjectHoomans `main` checkout.

Evidence:

- The existing directed relationship record now has one canonical `RELATIONSHIP_PROPOSAL` action. Production compatibility calls `PNC.SocialProfileMath.AreMutuallyOrientationCompatible` with the real player profile/traits, NPC generated or explicit profile, and actor genders.
- Proposal eligibility requires durable friend bond, approval 85, respect 60, familiarity 80, non-rival/non-enemy standing, living/available actors, family exclusion, compatibility, and a clear `relationship_proposal` cooldown.
- Acceptance is server-authoritative and deterministic through the shared proposal policy. Actual romance style affects bounded acceptance probability; no permanent romance chance field was added.
- Acceptance promotes `friend` to `lover` and records a permanent bounded event/memory with normal revision/persistence updates. Rejection preserves `friend`, records a bounded rejection memory, and sets a personality-aware cooldown.
- Semantic Lab exposes compatibility, thresholds, cooldown, availability, and a `Propose relationship` action in the Relationship workbench. Starting lover remains preserved and cannot be reproposed.

Validation:

- `test_contextual_runtime_parity_p11d.py` under Xvfb: 7/7 passed, covering incompatible, Gay, Bisexual, straight, family, below-threshold, flirty, reserved, deterministic acceptance, rejection cooldown, starting-lover, persistence round-trip, and Tk workbench controls.
- P11A-C combined regression: 27/27 passed before the P11D test was added.
- `luac5.3 -p`, `py_compile`, and `git diff --check` passed for the P11D changes.

Native Project Zomboid SP/MP remains UNTESTED / user-owned.

## Current Exact Next Chunk — P11E

On the actual local checkout:

1. add production-backed live standing preview and reason text while relationship sliders move;
2. show friend bond progress and romance eligibility/proposal state in the Relationship workbench;
3. preserve Apply, Apply + Replay, and optional debounced Auto replay;
4. make Compare the single understandable surface for utterance A/B/C comparison using the real Lua worker;
5. add focused tests for live resolver preview, thresholds, cooldown, Compare output, stale/replay behavior, and normal/large Tk layouts;
6. run the focused checks, update this ledger with exact evidence, commit P11E on existing `main`, and continue automatically to P11F.

## Ordered remaining milestones

After P11E continue automatically:

- **P11F:** unified semantic Flow / Hub / ConversationBlock runtime graph;
- **P11G:** modular speech-realization content packs;
- **P11H:** final runtime-parity usability/regression gate.

See `RUNTIME_PARITY_ACTORS_RELATIONSHIPS_AND_UX.md` for the full contracts.

## Handoff condition

Do not report **READY FOR USER LIVE TEST** again until P11A-P11H all pass.

Native Project Zomboid SP/MP remains user-owned and must remain UNTESTED unless the user supplies evidence.
