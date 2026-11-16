# Progress — Unified Starting Companion Authoring

**Status:** P3 implementation complete; accepted phase commit pending

**Primary repository:** ProjectHoomans (`main`)

**Participant repository:** PsychopatzCore (`main`), changed only for the
provider-neutral character-creation seam in P2

## P1 — canonical NPC authoring pipeline

Accepted in local commit `a6381bf4`.

The shared pipeline is:

```text
canonical field registry
    -> sparse blueprint
    -> context / binding policy
    -> resolver and bounded trace
    -> concrete definition
    -> existing Unique NPC/runtime actions
```

Registry descriptors drive readable serialization, explicit-clear validation,
compact encoding, fingerprints, resolver tracing, and the Unique NPC editor.
`identity.nickname` is canonical and round-trips through the Unique NPC draft,
save/load, resolution, and runtime identity. Superseded authoring aliases are
not registered or loaded.

## P2 — provider-neutral character-creation seam

Accepted in local commits `dfcf9f6e` (PsychopatzCore) and `9778522f`
(ProjectHoomans).

PsychopatzCore owns a bounded `CharacterCreationExtension` registry. It wraps
the vanilla `CharacterCreationProfession` lifecycle and emits actual selected
trait snapshots for creation, repopulation, visibility, build load/reset, and
randomization. `CoopCharacterCreationProfession` inherits the same base path.
Project Hoomans owns the starting-companion adapter and all companion policy.

## P3 — session, composer, presets, and import sanitization

The implementation now provides:

- a bounded per-character-creation session keyed by canonical starting-
  companion trait ID;
- actual selected-set reconciliation with added/removed/unchanged results,
  inactive-slot caching, re-add restoration, and final active-only blueprints;
- context rebuilding from the current descriptor plus the existing social-trait
  resolver, so Lover orientation and family surname/appearance remain dynamic;
- distinct per-slot `Randomize`, `Reset`, and `RevertToPreset` operations;
- a reusable registry/policy/trace-backed NPC composer facade and character-
  creation window with source indicators, blueprint-vs-preview presentation,
  editable policy-permitted fields, and a final active-slot summary;
- canonical whole-setup and individual-template preset serialization,
  JSON encoding, dedicated local starter-preset storage, and no trait purchase
  or automatic trait addition during load;
- a shared Unique NPC import sanitizer that returns preserved, removed,
  rebound, and regenerated field reports and strips runtime/authority data;
- removal of the old flat Unique NPC persistence fallback and a dedicated
  `starter` definition-store kind.

No companion-only field registry, blueprint, resolver, or persistence schema
was introduced. The composer consumes the same canonical registry and resolver
trace as Unique NPC authoring and debug inspection.

## P3 verification evidence

`TEST_VERIFIED`:

- `python3 tests/run_tests.py unique_npc unique_npc_editor_model unique_npc_smoke identity_nickname identity_deterministic npc_authoring_schema starting_companion social_traits pnc_starting_companion_authoring puppet_opera_storage --jobs 4 --timeout 30` — **PASS 17/17**.
- `lua tests/pnc_starting_companion_authoring_smoke.lua` — **PASS**; session reconciliation, cached re-add, policy locks, deterministic previews, all three slot actions, dynamic Lover orientation, preset JSON round-trip, current-player rebinding, and import sanitization.
- `lua tests/pnc_social_traits_smoke.lua` — **PASS**; normal and inherited co-op extension paths still reach the adapter.
- `lua tests/psychopatz_character_creation_extension_smoke.lua` in PsychopatzCore — **PASS**.

`STATIC_ONLY`:

- changed Lua passed `luac -p` and targeted `pz_verify --kahlua --severity ERROR`.
- JSON translation catalogs parse successfully.
- `git diff --check` passes.

The full existing Hoomans suite remains at the previously observed four
unrelated failures: animation-scene debug routes, context debug scene-lab
route, population-director initialization, and the dirty-work translation
expectation. No new P3-focused regression was introduced.

## Next Chunk — P4 authority handoff and lifecycle

Implement one semantic starter-customization service for SP and MP. Add the
versioned compact blueprint envelope, registry-fingerprint rejection, final
server-side resolution against the actual survivor/context, bounded pending /
received / defaulted / grants-complete lifecycle, timeout/default fallback,
spoofed-authority rejection, and reconnect/replacement-survivor idempotence.
Keep `StartingCompanionService` the only spawn, recruitment, relationship,
knowledge, faction, and community owner.

## Repository safety

ProjectHoomans and PsychopatzCore remain on existing `main` branches. Unrelated
dirty work is preserved. No new branch, push, Workshop publication, reset,
stash, broad staging, or native Project Zomboid validation was used.
