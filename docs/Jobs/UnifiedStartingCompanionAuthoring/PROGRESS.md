# Progress — Unified Starting Companion Authoring

**Status:** P2 implementation complete; accepted phase commit pending

**Primary repository:** ProjectHoomans (`main`)

**Participant repository:** PsychopatzCore (`main`), with the reusable
character-creation seam added in P2

## P1 — canonical NPC authoring pipeline

P1 is implemented and accepted in local commit `a6381bf4`.

The shared pipeline is:

```text
canonical field registry
    -> sparse blueprint
    -> context/policy resolver
    -> concrete definition
    -> existing Unique NPC/runtime actions
```

The registry, blueprint, compact codec, deterministic resolver, fingerprints,
resolution trace, Unique NPC draft/storage/registration/resolution, and Debug
Resolution Inspector all use one canonical model. Project Hoomans-owned Unique
authoring and persistence use canonical fields only; superseded aliases are not
loaded or emitted. `identity.nickname` survives draft, save, load, Unique
resolution, and runtime identity creation.

The P1 anti-split gate is satisfied: no companion-only draft, field vocabulary,
serializer, or diagnostic resolver was introduced.

## P2 — provider-neutral character-creation seam

PsychopatzCore now exposes one bounded
`PsychopatzCore.CharacterCreationExtension` registry. Providers register an ID
and one `onEvent(screen, payload)` callback; Core owns no Project Hoomans trait
IDs, relationship rules, presets, blueprints, or starter services.

The seam wraps the existing `CharacterCreationProfession` base methods for:

- screen creation and visibility;
- actual selected-trait repopulation and profession changes;
- build load/reset and randomize operations.

Each event carries a bounded, deduplicated `selectedTraitIDs` snapshot read from
the screen's selected-trait list. `CoopCharacterCreationProfession` derives
from this base class, so it uses the same wrapped path without a second co-op
patch.

Project Hoomans registers
`ProjectHoomans.StartingCompanions` as an adapter. The adapter maps Core's
engine trait IDs to canonical starting-companion trait IDs and forwards bounded
snapshots to the future session service. It does not author or resolve NPC
fields; that remains the shared P1 pipeline's responsibility.

## P2 verification evidence

`TEST_VERIFIED`:

- `python3 tests/run_tests.py unique_npc identity_nickname identity_deterministic npc_authoring_schema starting_companion social_traits --jobs 4 --timeout 30` — **PASS 15/15**.
- `lua tests/pnc_social_traits_smoke.lua` — **PASS**; normal and inherited
  co-op screen paths reach the Hoomans adapter with actual selected traits.
- `lua tests/psychopatz_character_creation_extension_smoke.lua` in
  PsychopatzCore — **PASS**; provider registration, event coverage, selected
  trait snapshots, and normal/co-op inheritance pass.
- `luac -p` passed the changed Core, adapter, and test Lua files.
- `pz_verify` Kahlua checks passed for the changed Core seam and Hoomans
  adapter.
- `git diff --check` passed in both repositories.

The full Hoomans suite remains at the P1 baseline of four unrelated failures in
pre-existing animation-scene, context-debug, population-director, and custom-
translation dirty-work areas. No P2-owned path is implicated.

## Remaining parent-goal work

- selected-trait keyed session reconciliation and companion composer UI;
- whole-setup/per-companion presets and shared import sanitizer;
- SP/MP customization envelope, server authority, lifecycle pending/default
  fallback, and starter-service integration;
- final regression expansion and native Build 42.20 acceptance.

## Next Chunk

P3: build the selected-trait keyed starting-companion session, generic NPC
composer surface, source indicators/resolved preview, deterministic per-slot
actions, presets, and shared Unique NPC import sanitization.

## Repository safety

ProjectHoomans and PsychopatzCore remain on their existing `main` branches.
Unrelated dirty/staged work is preserved. No new branch, push, Workshop
publication, reset, stash, broad staging, or native Project Zomboid validation
was used.
