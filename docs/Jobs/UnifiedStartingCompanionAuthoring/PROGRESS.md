# Progress — Unified Starting Companion Authoring

**Status:** P1 implementation complete; accepted phase commit pending

**Primary repository:** ProjectHoomans (`main`)

**Participant repository:** PsychopatzCore (`main`), unchanged for P1

## P1 implementation

The shared NPC authoring pipeline now exists under the Project Hoomans shared
runtime:

```text
canonical field registry
    -> sparse blueprint
    -> context/policy resolver
    -> concrete definition
    -> existing Unique NPC/runtime actions
```

Implemented pieces:

- `PNC_NPCAuthoringRegistry` defines canonical logical field IDs, runtime and
  draft accessors, normalizers and bounds, authoring/persistence/network and
  binding flags, lifecycle metadata, immutable explicit wire codes, registry
  validation, protocol fingerprinting, and compact encode/decode.
- `PNC_NPCAuthoringBlueprint` stores only sparse canonical authored values,
  bounded explicit clears, and a deterministic generation seed. `nil` is not
  used as an explicit-clear marker.
- `PNC_NPCAuthoringResolver` applies authoritative, mandatory-binding,
  explicit, then generated precedence and returns bounded field-source traces.
  Starting-companion policies call the existing social-trait resolver for
  relationship sex and preserve the current family surname/appearance rules.
- Registry and blueprint fingerprints are deterministic and are not runtime
  NPC IDs or authority tokens. Compact decode rejects protocol, registry, and
  schema mismatches before decoding fields.
- The Unique NPC draft, definition serializer, local storage, registration,
  resolution, and debug inspector consume the shared registry/blueprint/
  resolver. The generated Unique catalog compiles through the same canonical
  blueprint before registration.
- `identity.nickname` now survives draft construction, canonical save/load,
  Unique resolution, and runtime identity creation. `alias`, `name` input,
  `firstName`, `lastName`, `skillBaseLevels`, `physiologicalTraits`, and
  `startingInventoryTemplate` are no longer active Unique authoring or
  persistence aliases. `name` remains only as a derived runtime record
  projection required by existing PNC consumers.
- Explicit nickname clears and canonical generation seeds survive editor
  round-trips. Randomize is the only operation that changes the seed.
- Existing Unique faction authoring remains registry-backed for debug/editor
  parity; owner, debug, grant, and runtime authority fields are not blueprint
  fields.

## P1 verification evidence

`TEST_VERIFIED`:

- `python3 tests/run_tests.py unique_npc identity_nickname identity_deterministic npc_authoring_schema starting_companion --jobs 4 --timeout 30` — **PASS 14/14**.
- Focused direct Lua tests passed for canonical schema, Unique registration and
  resolution, editor/storage, debug inspector, nickname, identity generation,
  social traits, and starter service/relationship/state behavior.
- `python3 tests/run_tests.py --jobs 4 --timeout 30` reached 1029 tests; four
  unrelated pre-existing dirty-work failures remain in animation scene routes,
  context debug, population director, and custom translation manager. Their
  failures concern existing scene/settlement/translation expectations and no
  P1-owned paths.
- `luac -p` passed for all new and modified P1 Lua files.
- `pz_verify` Kahlua checks passed for the registry, blueprint, resolver,
  Unique draft, Unique diagnostics, and identity/runtime files; targeted i18n
  verification reported no hardcoded UI strings.
- `git diff --check` passed.

## P1 gate

The anti-split gate is satisfied after the exact local phase commit:

- Unique debug/editor and storage use the shared model.
- Owned Unique definitions and persistence output use canonical fields and
  schema metadata; superseded aliases are not loaded or emitted.
- Nickname round-trip and deterministic resolution are covered.
- Resolution Inspector rows consume `resolutionTrace` produced by the shared
  resolver.
- No companion-only draft, field vocabulary, serializer, or diagnostic
  resolver was introduced.

## Not yet implemented

The following remain parent-goal work and are deliberately not claimed by P1:

- generic normal/co-op character-creation extension seam;
- selected-trait keyed session reconciliation and companion composer UI;
- whole-setup/per-companion presets and shared import sanitizer;
- SP/MP customization envelope, server authority, lifecycle pending/default
  fallback, and starter-service integration;
- final regression expansion and native Build 42.20 acceptance.

## Next Chunk

P2: introduce one provider-neutral character-creation extension seam covering
normal `CharacterCreationProfession` and `CoopCharacterCreationProfession`.
The Core seam must remain unaware of Project Hoomans trait IDs, policies,
presets, blueprints, and starter services.

## Repository safety

ProjectHoomans and PsychopatzCore both remain on their existing `main` branches.
Unrelated dirty/staged work is preserved. No Core changes, branch creation,
push, Workshop publication, reset, stash, or broad staging was used.
