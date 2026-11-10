# Progress — Unified NPC Population and Expansion Architecture

**Status:** P2 IN PROGRESS — PROFILE/MAP/MONITOR PRESENCE SLICE VERIFIED

**Primary repository:** ProjectHoomans (`main`)

**Participant repositories:** PsychopatzCore (`main`), DynamicTrading (`main`)

## Verified current truth

### `CODE_VERIFIED` — existing foundation

- PsychopatzCore owns the existing SurvivorWorld group-plan and canonical
  commit seams, including stable group/faction/member identity and provenance.
- Project Hoomans owns physical PNC/NPC materialization through the existing
  Core adapter and `MaterializeCoreGroup` boundary.
- Dynamic Trading has abstract and Hoomans-backed provider paths and already
  supplies trader presets/member specifications.

### `STATIC_ONLY` — remaining architectural split

- Dynamic Trading still owns trader-specific generation façade/cadence code;
  it has not yet become a generic Core source registration.
- Hoomans' fixed mobile allow-list has been replaced by registered profiles;
  canonical actor adoption/hydration remains the next boundary.
- Map/hover and monitor projections now normalize valid live/abstract state;
  an unhydrated canonical actor must still be repaired or hidden, and
  `UNKNOWN` remains an invalid projection rather than a supported mode.
- The exact writer/provenance chain for recurring new-save names such as Nina
  Cole and Vara Moss remains a runtime trace to perform before deleting any
  compatibility or bootstrap path.
- Canonical actor adoption/hydration remains the next Hoomans boundary;
  Dynamic Trading has not been migrated to Core source registration yet.

### `TEST_VERIFIED` — supporting evidence already available

The preceding authority work recorded focused Core, Hoomans, and Dynamic
Trading tests, including Core group commits, Hoomans adoption/materialization,
and DTAbstract/DTHoomans handoff checks. Those results support the starting
seams; they do not satisfy this new source-registration or native fresh-save
acceptance goal.

### `USER_ACCEPTANCE` — not yet demonstrated

- Fresh-save and restart behavior in native Project Zomboid.
- Nearby physical materialization and NPC monitor/map parity.
- Dynamic Trading activation/hotswap without duplicate actors.
- Absence of stale `UNKNOWN` map hover output after the source chain is
  unified.

## Accepted P1 — Core generation-source contract

`CODE_VERIFIED`: PsychopatzCore now exposes `SurvivorWorld.Generation.Sources`
plus `GenerateGroup` and `GenerateCommunity`. Sources have bounded
registration, activation, generation kind, serializable defaults/profile data,
caps, cooldowns, idempotency keys, request fingerprints, and persisted
provenance. Canonical commits still flow through the existing Core bootstrap.

`TEST_VERIFIED`: the new source-contract smoke and the existing generation,
dynamic-group, registry, schema, bounds, bootstrap, and PNC-import smokes pass.
Changed runtime Lua compiles with `luac5.3` and passes `pz-verify`.

Commit: PsychopatzCore `6c16192f2929f0a054dbca2dce26c4d6588c32c4`.

Dynamic Trading and Project Hoomans generation code were intentionally not
rewritten in P1.

## P2 — registered materializer profile and presence projection slice

`CODE_VERIFIED`: Hoomans faction archetypes now expose a bounded registration
API for mobile profiles. Existing and custom profiles use the same
`GenerateForFaction` and `MaterializeCoreGroup` path; no second expansion
generator or body writer was introduced. A test-only expansion-shaped fixture
is used only to prove the registration contract. No Gang mod or production
Gang feature is being created.

`CODE_VERIFIED`: Core actor-map/hover projection now consumes canonical
`presenceState` when provider lease state is absent. Hoomans' supplemental
map directory normalizes missing/legacy state to `abstract` for alive records
and treats dead records as `corpse` before visibility projection. The NPC
monitor uses the same normalization for filters, badges, and details.

`TEST_VERIFIED`: Hoomans mobile-profile, canonical-member-preset, travel
directory, and map-presentation smokes pass (`4/4`). Core actor-map and hover
card smokes pass (`2/2`). Changed Lua compiles with `luac5.3`; changed
Hoomans runtime files pass `pz-verify` with zero errors. The unrelated
`pnc_faction_service_presence_boundary_smoke` still reports its pre-existing
declaration-count expectation `87` versus actual `88`; no new public
`Factions.*` function was added by this slice.

Core participant commit: `cff123f` (`phase(P2): normalize Core actor presence projections`).

## Current phase

**P2 — Hoomans materializer and extensible NPC policy.** The profile,
map-presence, and monitor-presence slice is verified; the next boundary is
canonical actor adoption/hydration.

## Next Chunk

**Complete P2 canonical actor adoption/hydration.** Preserve Hoomans
ownership of PNC records, body creation, abstract/live projection, monitor,
map, and debug integration. Do not migrate Dynamic Trading until that
Hoomans boundary is tested.

## Completion rule

This parent goal remains active until P1–P5 gates pass. A documentation update,
a focused unit test, or a successful static audit does not by itself prove
fresh-save native behavior.
