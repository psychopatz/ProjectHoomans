# Progress — Unified Starting Companion Authoring

**Status:** P4 implementation complete; P5 developer verification next

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

Implementation is complete in the current worktree; the exact phase-owned
paths are ready for the local P4 commit.

The implementation now provides:

- one versioned sparse-envelope handoff for SP, listen-server, and MP;
- explicit registry/protocol compatibility and envelope fingerprints;
- atomic compact decode with strict field/authority-key rejection;
- authoritative sanitization against the same starter policy used for final
  resolution;
- final server resolution from the actual character UUID, player descriptor,
  social orientation, relationship policy, and existing
  `StartingCompanionService`;
- bounded pending, received, validated, defaulted, and grants-complete state;
- timeout fallback, payload-order tolerance, reconnect idempotence, and
  replacement-survivor UUID semantics;
- direct production command routing rather than debug-command customization;
- shared resolver name projection so inherited surnames are visible in the
  preview/trace as well as the final runtime record;
- a server-clock fix preventing world-age hours from being mixed with
  millisecond customization deadlines.

## Verification evidence

`TEST_VERIFIED`:

- focused authoring/starter suite: **18/18 passed**;
- full Project Hoomans harness: **1028/1032 passed**; the remaining four are
  the pre-existing animation-scene debug route, context debug scene-lab,
  population-director initialization, and dirty-work translation expectation
  failures;
- direct authority-resolution smoke covers canonical nickname preservation,
  current-player surname/appearance rebinding, and relationship sex
  authority;
- customization smoke covers compact round-trip, explicit clear/value,
  registry mismatch, spoofed authority, lifecycle ordering, timeout fallback,
  and reconnect idempotence;
- registry/serializer smoke covers immutable wire codes, fingerprints,
  deterministic generation, resolution trace, and mandatory binding clears;
- full focused test run includes existing Unique NPC, starter, social-trait,
  composer, preset, and debug-inspector tests.

`STATIC_ONLY`:

- all changed/new Lua files pass `luac -p`;
- all changed production Lua files pass targeted `pz_verify --kahlua`;
- `git diff --check` passes;
- native Project Zomboid SP/MP acceptance has not been run, per repository
  policy; it remains the user-owned P6 handoff.

## Next Chunk — P5 harness regression expansion

Run the existing full harness after the P4 exact-path commit, close the
remaining developer-side regression evidence, update the final handoff, and
then hand the native SP/MP matrix to the user. Do not launch native PZ or
publish Workshop content as part of this developer phase.

## Repository safety

ProjectHoomans and PsychopatzCore remain on existing `main` branches. No new
branch, push, Workshop publication, reset, stash, broad staging, or native PZ
validation was used. Unrelated dirty work remains preserved and will not be
staged by the phase commit.
