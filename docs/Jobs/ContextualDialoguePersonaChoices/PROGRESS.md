# Contextual Dialogue Persona & Choices — Current Progress

**Updated:** 2026-10-23
**Parent status:** REOPENED — P10 infrastructure is retained, but P11 runtime-parity, relationship, and UX acceptance is mandatory.
**Current mandatory phase:** P11D — Romance proposal, compatibility, and server-authoritative acceptance.
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

## Current Exact Next Chunk — P11D

On the actual local checkout:

1. audit the existing production compatibility APIs and player/NPC gender/profile sources;
2. add one canonical `RELATIONSHIP_PROPOSAL` semantic action through the existing server relationship boundary;
3. enforce friend bond, standing, family exclusion, thresholds, availability, compatibility, and named cooldown gates;
4. evaluate NPC acceptance deterministically from actual relationship values and generated/personality override data;
5. persist acceptance/rejection events, revisions, cooldown, and friend-to-lover promotion on the existing directed record;
6. expose compatibility, proposal threshold, cooldown, and availability in the Relationship workbench with a proposal action;
7. add focused tests for incompatible, Gay, Bisexual, straight, family, flirty, reserved, accepted, rejected, cooldown, starting-lover, and persistence cases;
8. run the focused checks, update this ledger with exact evidence, commit P11D on existing `main`, and continue automatically to P11E.

## Ordered remaining milestones

After P11D continue automatically:

- **P11E:** live relationship preview + Compare/toolbar cleanup;
- **P11F:** unified semantic Flow / Hub / ConversationBlock runtime graph;
- **P11G:** modular speech-realization content packs;
- **P11H:** final runtime-parity usability/regression gate.

See `RUNTIME_PARITY_ACTORS_RELATIONSHIPS_AND_UX.md` for the full contracts.

## Handoff condition

Do not report **READY FOR USER LIVE TEST** again until P11A-P11H all pass.

Native Project Zomboid SP/MP remains user-owned and must remain UNTESTED unless the user supplies evidence.
