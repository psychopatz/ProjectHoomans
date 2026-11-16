# Progress — Unified Starting Companion Authoring

**Status:** P5 developer gates complete; P6 native acceptance is user-owned

**Primary repository:** ProjectHoomans (`main`)

**Participant repository:** PsychopatzCore (`main`), changed only for the
provider-neutral character-creation seam in P2

## Accepted phases

### P1 — canonical NPC authoring pipeline

Accepted in local commit `a6381bf4`.

The canonical registry, sparse blueprint, explicit-clear semantics, compact
codec, fingerprints, policy resolver, bounded field trace, Unique NPC cutover,
and canonical nickname round-trip are shared by debug authoring and starter
contexts. Superseded authoring aliases are not registered or loaded.

### P2 — provider-neutral character-creation seam

Accepted in local commits `dfcf9f6e` (PsychopatzCore) and `9778522f`
(ProjectHoomans).

PsychopatzCore owns only the generic lifecycle extension. Project Hoomans owns
the starting-companion adapter, trait IDs, policies, presets, and services.
Normal and co-op profession screens use the same extension path.

### P3 — session, composer, presets, and import sanitization

Accepted in local commit `c7904a78`.

The selected-trait keyed session reconciles added/removed/unchanged slots,
retains removed-slot caches, preserves deterministic seeds, reuses the generic
composer and resolution trace, and serializes canonical whole/per-slot presets.
Unique NPC import uses the shared relationship policy and reports preserved,
removed, rebound, and regenerated fields.

### P4 — authority handoff and lifecycle

Accepted in local commit `e15aefea`.

The versioned sparse envelope supports SP, listen-server, and MP with explicit
protocol/registry compatibility, atomic compact decode, strict authority-key
rejection, and a bounded pending/received/validated/defaulted/grants-complete
state machine. Final resolution uses the actual character UUID, descriptor,
social orientation, relationship policy, and existing
`StartingCompanionService`. Timeout/default behavior, payload ordering,
reconnect idempotence, replacement-survivor UUID semantics, and the
millisecond-vs-world-age clock boundary are covered.

## P5 verification evidence

`TEST_VERIFIED`:

- focused authoring/starter suite: **18/18 passed**;
- full Project Hoomans harness: **1028/1032 passed**; the four remaining
  failures are the pre-existing animation-scene debug route, context debug
  scene-lab, population-director initialization, and dirty-work translation
  expectation failures;
- direct authoritative-resolution smoke covers canonical nickname
  preservation, current-player surname/appearance rebinding, relationship sex
  authority, and the shared resolution trace;
- customization smoke covers compact round-trip, explicit clear/value,
  registry/protocol mismatch, spoofed authority, lifecycle ordering, timeout
  fallback, and reconnect idempotence;
- registry/serializer smoke covers immutable wire codes, fingerprints,
  deterministic generation, source tracing, mandatory binding clears, and
  inherited-name projection;
- existing Unique NPC editor/storage, Unique NPC resolver, debug Resolution
  Inspector, starter relationship, social-trait, preset, and character-
  creation extension tests remain green.

`STATIC_ONLY`:

- all changed/new Lua files pass `luac -p`;
- all changed production Lua files pass targeted `pz_verify --kahlua`;
- `git diff --check` passes;
- no native Project Zomboid SP/MP session has been run, per repository policy;
- no Workshop publication or push was performed.

## P6 — native acceptance handoff

The remaining acceptance is user-owned: run the native SP, MP host/remote,
local/co-op, preset/import, orientation, rebinding, no-reroll, and
Resolution-Inspector matrix described in `ROADMAP.md`. Developer-side code,
test, compile, and static gates are complete. Do not launch native PZ or
publish Workshop content without explicit user authorization.

## Repository safety

ProjectHoomans and PsychopatzCore remain on existing `main` branches. No new
branch, push, Workshop publication, reset, stash, broad staging, or native PZ
validation was used. Unrelated dirty work remains preserved and is excluded
from the exact phase commits.
