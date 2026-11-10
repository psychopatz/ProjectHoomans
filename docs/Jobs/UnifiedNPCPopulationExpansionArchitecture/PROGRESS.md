# Progress — Unified NPC Population and Expansion Architecture

**Status:** DOCUMENTATION BASELINE

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
- Hoomans mobile/faction policy still contains fixed trader/looter/refugee
  assumptions and a high-fan-out generation function.
- Map/hover projection can observe a marker or record before the canonical
  actor/provider lease is fully resolved. `UNKNOWN` must be treated as an
  invalid projection, not a supported mode.
- The exact writer/provenance chain for recurring new-save names such as Nina
  Cole and Vara Moss remains a runtime trace to perform before deleting any
  compatibility or bootstrap path.

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

## Current phase

**P0 — Documentation and evidence baseline.** The roadmap and durable
architecture contract are being recorded before production edits.

## Next Chunk

**Implement P1: the PsychopatzCore generic generation-source contract after
the documented ownership/roadmap is accepted.** Do not begin the Dynamic
Trading or Hoomans generation rewrite before Core's source registration,
activation, provenance, idempotency, and canonical-result contract is defined
and tested.

## Completion rule

This parent goal remains active until P1–P5 gates pass. A documentation update,
a focused unit test, or a successful static audit does not by itself prove
fresh-save native behavior.
