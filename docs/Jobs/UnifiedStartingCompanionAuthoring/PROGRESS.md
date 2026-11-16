# Progress — Unified Starting Companion Authoring

**Status:** P5R developer gates complete — P6 native acceptance is user-owned

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

## USER_VERIFIED regression — native entry-point failure

The user tested a new-save character creation in Build 42.20 and reached the
final **Customise Character** screen, but no usable starting-companion editor
entry point was visible. The supplied native screenshot shows vanilla final
character customization with Random and Play controls and no companion action.

`CODE_VERIFIED` audit explains the failure:

- `PNC_StartingCompanionCharacterCreationAdapter.HandleEvent()` calls
  `OpenComposer()` only on profession `screen_shown`;
- `OpenComposer()` returns `no_active_companions` when no starter trait is active
  at that instant;
- later trait-set events reconcile session state but do not reopen the composer;
- therefore the feature can remain invisible even though the session/resolver
  tests pass;
- `PNC_SocialTraitCharacterCreationPatch` currently wraps
  `CharacterCreationMain.onOptionMouseDown` by invoking vanilla Play/NEXT first
  and `Adapter.Submit()` afterward;
- vanilla NEXT hides the final screen, initializes the player/world, and enters
  `LoadingQueueState`, so this is the wrong pre-commit ordering;
- the adapter's current session lookup is screen-object oriented, so a naïve
  final-screen `GetSession(CharacterCreationMain)` would risk creating a second
  logical companion session;
- existing focused tests did not assert the real profession -> final character
  screen -> visible Companions action -> composer -> return -> Play journey.

The prior P1/P2/P4 foundations remain useful and accepted. P3 functionality is
implemented but its entry-point UX acceptance was incomplete. P5 verification
is now insufficient for parent-goal completion because it missed this native
journey regression.

## P5R target

Repair the character-creation lifecycle so the final screen becomes the explicit
entry point:

```text
profession selects companion traits
        -> one logical creation session
        -> final Customise Character screen
        -> optional COMPANIONS button beside Play
              -> shared composer using CURRENT final player context
              -> return to final screen
        -> Play
              -> skipped/unmodified: original default/randomized path
              -> authored: validate/stage before vanilla transition
```

Native P6 acceptance resumes only after P5R automated/UI-harness gates pass.
Do not launch native PZ or publish Workshop content without explicit user
authorization.

## P5R — developer acceptance complete

P5R repaired the real final-screen journey without changing the accepted
authoring, resolver, or P4 authority foundations:

- profession visibility now reconciles only; it never navigates into the
  composer;
- normal and co-op final character screens expose an explicit **COMPANIONS**
  action beside **PLAY**, disabled when no starting-companion trait is active;
- session identity is keyed by creation player index, so profession, final
  screen, composer, and back-navigation share one logical session and removed
  slot caches;
- every open and Play pre-commit re-reads selected traits and the current final
  player descriptor, then rebuilds social/orientation and inherited appearance
  context without mutating blueprint intent;
- blueprint-vs-default fingerprints make customization opt-in. Skipped and
  open/close-without-change flows clear/omit customization intent, while edits
  and explicit Randomize stage canonical authored envelopes;
- authored Play validates and stages before vanilla NEXT/world transition.
  Invalid authored state remains on the final screen with a reason; default
  state never blocks Play. Remote MP keeps the validated envelope pending until
  the player exists and submits it idempotently;
- the focused final-screen journey harness covers normal/co-op entry, session
  continuity, dynamic player rebinding, Lover orientation, back-navigation,
  Randomize determinism, invalid-state blocking, default paths, and MP pending
  submission. Existing authoring, preset/import, customization, starter, and
  authority tests remain green.

## P6 — native acceptance handoff

The remaining gate is user-owned native Build 42.20 validation: SP, MP
host/remote, local/co-op, preset/import, orientation, final-player rebinding,
deterministic preview, Reset/Randomize/Revert, final summary, Resolution
Inspector, reconnect, replacement-survivor, and no-customization fallback.
Do not launch native PZ or publish Workshop content without explicit user
authorization.

## Repository safety

ProjectHoomans and PsychopatzCore remain on existing `main` branches. Current
ProjectHoomans HEAD at this audit is `fb4c43ce23ee0106f52dab931f12f817ddb9f991`.
The worktree contains unrelated active semantic/UI edits; preserve them. No new
branch, push, Workshop publication, reset, stash, broad staging, or agent-run
native PZ validation is authorized. The native regression above was supplied by
the user and is acceptance evidence, not an agent-run native test.
