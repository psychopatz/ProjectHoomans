# Contextual Dialogue Persona & Choices — Current Progress

**Updated:** 2026-10-22

**Parent status:** IN PROGRESS — corrective P8 sequence

**Completed corrective phase:** P8E — corrective final validation

**Next mandatory phase:** developer-side handoff; native SP/MP remains user-owned

**Native Project Zomboid SP/MP:** UNTESTED / user-owned

## Repository baseline

- ProjectHoomans: `main`, P8A implementation revision `bfdf456c` (`feat: add contextual dialogue bond baseline`); no branch was created.
- psychopatzCore: `main`, clean, `443b3a8`.
- DynamicTrading: `main`, clean, `5db64cb`.
- ProjectHoomans had unrelated concurrent combat/zombie edits before P8A. They were preserved unstaged and were not included in `bfdf456c`.

## P8A implementation evidence

Revision `bfdf456c` adds the smallest bounded foundation required for detailed companion bond vocabulary:

- `PNC_RelationshipKindRegistry` is a declarative, bounded metadata registry. It maps `friend` to `friend`, `lover` to `lover`, and `mother`, `father`, `sister`, and `brother` to `family`. Future registered kinds can supply the same class and localized reference/address term keys without editing the speech resolver.
- Existing Starting Companion persistence remains the owner of detailed `relationshipKind`. The registry owns metadata only; no bond class is stored in ModData or scenario persistence.
- `ActorConversationContext` projects transient `bond.class`, `bond.kind`, source, and term keys. Detailed kind remains intact. Public projection exposes only the known class/kind surface.
- Directed approval/respect/familiarity remains independent from the special bond. Context state is resolved through production `PNC.RelationshipStates.ResolveState`, including current-state hysteresis.
- The Semantic Lab settings surface now obtains bond kinds from the production catalog, displays derived class/reference/address terms, shows numeric slider values, and removes the ordinary editable `npc.relationshipState` field. Legacy normal-mode state overrides are discarded by the settings collector.
- EN/TL relationship reference and address terms use the translation manager's `Conversation/Flavor` namespace and keep semantic kind/term keys language-independent.
- The existing real Lua worker exposes the production relationship-kind catalog and supports a bounded synthetic registration request used by the Lab test.

Focused evidence:

```text
python3 -m unittest -v tools.semantic_harness.tests.test_contextual_bonds_p8a
Ran 6 tests — OK

python3 -m unittest -v \
  tools.semantic_harness.tests.test_contextual_bonds_p8a \
  tools.semantic_harness.tests.test_contextual_actor_context_p2 \
  tools.semantic_harness.tests.test_contextual_speech_style_p3 \
  tools.semantic_harness.tests.test_contextual_semantic_lab_persona_p6 \
  tools.semantic_harness.tests.test_contextual_acceptance_c6b \
  tools.semantic_harness.tests.test_contextual_choice_registry_p1
Ran 21 tests — OK
```

The real worker evidence covers:

- required friend/lover/family mappings with detailed kind preservation;
- `mother + friend` and `mother + enemy` retaining `bond.class = family` and `bond.kind = mother` while directed state changes;
- unknown/friend/rival/enemy thresholds and a hysteresis case through production `ResolveState`;
- no persisted derived bond class or actor context;
- EN `Mom` versus TL `Nanay` with identical semantic kind and term keys;
- synthetic `grandmother -> family` registration and TL `Lola` resolution without resolver changes.

Additional checks passed:

- `luac5.3 -p` on all changed Lua worker/context/registry files;
- `python3 -m py_compile` on changed Semantic Lab/runtime/test Python files;
- `python3 -m json.tool` on both changed EN/TL address catalogs;
- `git diff --cached --check` before commit;
- targeted `pz_verify` Kahlua checks with no reported errors.

## P8A non-goals retained

P8A does not claim behavioral completion. It does not yet expand every semantic response family, complete generic provider discovery, complete arbitrary-utterance Lab comparison, or provide final Dynamic Trading/P8E evidence. Do not report `READY FOR USER LIVE TEST`.

## P8B behavioral speech completion

Revision `2aed55ca` (`feat: complete contextual speech realization coverage`) records the completed production-backed speech-family slice.

Implementation evidence:

- `PNC_SpeechStyleContext` now consumes declarative `speechStyle` metadata from the registered NPC trait definitions, derives previously unused `forgiveness` and `bravery`, applies `socialStyle`, and projects transient friend/family/lover bond detail without using gender or private profile fields.
- `PNC_SpeechRealization` now exposes a bounded machine-readable coverage inventory and deterministic whole-phrase families for non-greeting wellbeing, health/medical, identity, knowledge, acknowledgement, apology, offer/help, dispute/refusal, hostility/threat, gossip, activity, and companion-action responses. Neutral non-bond turns retain their canonical semantic translation identity; missing non-neutral variants fall back to neutral.
- Family-bond realization resolves the localized relationship address term first and passes it as a typed phrase argument. EN/TL production-worker evidence is `Mom`/`Nanay` with the same semantic response and click/action identity.
- The reused refusal `semantic.social.acknowledged` template is explicitly blocked from friendly acknowledgement realization on the authoritative `No.` branch.
- The existing client response presenter remains the only localization/presentation lane; no parser, planner, choice UI, action dispatcher, or persistent speech/bond state was added.

Focused real-worker validation:

```text
python3 -m unittest tools.semantic_harness.tests.test_contextual_speech_behavior_p8b
Ran 5 tests — OK

python3 -m unittest \
 tools.semantic_harness.tests.test_contextual_bonds_p8a \
 tools.semantic_harness.tests.test_contextual_actor_context_p2 \
 tools.semantic_harness.tests.test_contextual_speech_style_p3 \
 tools.semantic_harness.tests.test_contextual_speech_behavior_p8b \
 tools.semantic_harness.tests.test_contextual_semantic_lab_persona_p6 \
 tools.semantic_harness.tests.test_contextual_acceptance_c6b \
 tools.semantic_harness.tests.test_contextual_choice_registry_p1 \
 tools.semantic_harness.tests.test_contextual_dynamic_trading_p5
Ran 30 tests in 65.466s — OK
```

Additional P8B checks passed: `luac5.3 -p` on changed realization/style/presenter/worker Lua; `python3 -m json.tool` on EN/TL realization catalogs and the translation manifest; `git diff --check`; and the existing P3 style/gender/TL regression set.

## Next Chunk — P8C choice-provider completion

## P8C choice-provider completion

Revision `1543eab3` (`feat: discover contextual dialogue providers generically`).

Implementation evidence:

- `DialogueChoiceRegistry.Collect` now consumes only the bounded canonical provider candidate contract (`frame` plus separate `display` label/utterance data), preventing raw legacy definitions from bypassing the existing static/capability authority adapters.
- The central suggestions builder no longer calls `CollectProvider("dynamictrading.trader")`; one bounded generic collection pass discovers registered canonical providers. Dynamic Trading remains the owner of trade state/content/effects and is unchanged.
- `projecthoomans.social_context` is a production provider for an owned companion. It contributes an existing WELLBEING semantic frame, exposes no relationship scores/private data, and clicks through the existing `semantic_click_frame` → `DialogueInput` path with no new action lane.
- Generic provider frames are resolved only against the current suggestion projection and current revision, then checked through the existing click-time authority/policy path. The provider candidate is stale/replay safe.
- `social_context` is assigned the semantic `CONTEXTUAL_SOCIAL` ranking class; Dynamic Trading remains `GAMEPLAY_ACTION`.

Focused real-worker validation:

```text
python3 -m unittest -v \
 tools.semantic_harness.tests.test_contextual_choice_provider_p8c \
 tools.semantic_harness.tests.test_contextual_choice_registry_p1 \
 tools.semantic_harness.tests.test_contextual_dynamic_trading_p5
Ran 10 tests in 13.461s — OK
```

The provider matrix proves generic social discovery/click authority, no private score leakage, generic Dynamic Trading discovery, unchanged trade ownership, stale rejection, and duplicate-click rejection.

## Next Chunk — P8D Semantic Lab tuning workflow

Extend the existing Semantic Lab only: arbitrary current utterance, apply-and-replay, baseline capture, A/B scenario rows, selectable bounded context dimensions/matrices, final localized wording and candidate-order comparison, semantic-family coverage, realization/bond/fallback inspection, and production Lua-worker traces. Python/Tk may edit scenarios and render results only; all semantic/style/provider policy remains in production Lua. Preserve one existing Tk app, worker, choice UI lane, translation backend, and action dispatcher.

## P8D Semantic Lab tuning workflow

Revisions `56596ecb` (`feat: extend semantic lab persona tuning workflow`),
`da2f38ed` (`fix: keep semantic lab tuning controls within layout`), and
`dfe4e3de` (`fix: scope social providers to active dialogue topics`).

Implementation evidence:

- The existing Semantic Lab now accepts the current utterance for baseline preview, production scenario reapply/replay, and persona/context matrix runs. No second worker, Tk application, parser, translation backend, choice UI, or action dispatcher was added.
- `LuaSemanticWorker.context_matrix` now reports production response wording, semantic/render template identity, translation key, realization family/variant/fallback, typed family-address argument, bounded candidate order, provider/source/ranking/display data, and the restored original scenario.
- The existing inspector receives the production persona catalog and exposes a canonical semantic IR trace alongside response realization and machine-readable speech-family coverage.
- The existing Tk controls provide Capture baseline, Apply + replay, arbitrary-utterance Persona matrix, and bounded sweeps for persona, approval, respect, familiarity, bond, and EN/TL language.

Focused validation:

```text
python3 -m unittest -v tools.semantic_harness.tests.test_contextual_semantic_lab_persona_p8d
Ran 3 tests — OK

python3 -m unittest -v \
 tools.semantic_harness.tests.test_contextual_semantic_lab_persona_p6 \
 tools.semantic_harness.tests.test_contextual_semantic_lab_persona_p8d
Ran 7 tests — OK
```

The P8D tests cover real Lua-worker baseline/replay/matrix traces, candidate ordering, canonical semantic identity, coverage inspection, and the existing Tk surface including bond sweep execution.

## P8E corrective final validation

P8E passed on `main`. The corrective acceptance matrix now covers bond mapping and synthetic family extension, no duplicate bond persistence, production relationship derivation/hysteresis, non-greeting realization matrices, friend/family/lover EN/TL term substitution, generic provider discovery, Dynamic Trading ownership, privacy, stale/replay safety, gameplay action authority, and the existing Semantic Lab.

Final evidence:

```text
python3 -m unittest -q \
 tools.semantic_harness.tests.test_contextual_bonds_p8a \
 tools.semantic_harness.tests.test_contextual_actor_context_p2 \
 tools.semantic_harness.tests.test_contextual_speech_style_p3 \
 tools.semantic_harness.tests.test_contextual_speech_behavior_p8b \
 tools.semantic_harness.tests.test_contextual_semantic_lab_persona_p6 \
 tools.semantic_harness.tests.test_contextual_semantic_lab_persona_p8d \
 tools.semantic_harness.tests.test_contextual_acceptance_c6b \
 tools.semantic_harness.tests.test_contextual_choice_registry_p1 \
 tools.semantic_harness.tests.test_contextual_dynamic_trading_p5 \
 tools.semantic_harness.tests.test_contextual_choice_provider_p8c \
 tools.semantic_harness.tests.test_contextual_suggestions_followup \
 tools.semantic_harness.tests.test_semantic_translation_integration
Ran 42 tests — OK

python3 -m unittest -q [impacted contextual conversation/suggestion C0–C4 and S1–S3/whats-up/follow-up modules]
Ran 52 tests — OK

xvfb-run -a python3 -m unittest -q \
 tools.semantic_harness.tests.test_contextual_semantic_lab_persona_p8d \
 tools.semantic_harness.tests.test_contextual_suggestions_s4 \
 tools.semantic_harness.tests.test_app
Ran 17 tests — OK
```

Toolchain and runtime gates passed:

- `python3 -m tools.semantic_harness.app --no-gui --doctor --doctor-json`: required checks PASS; Lua 5.3.6, worker syntax and READY/PING/CAPABILITIES PASS. The repository-local venv was not active and is a non-required warning.
- `pz_verify --dir Contents/mods/ProjectHoomans/42.20/media/lua --kahlua --severity ERROR --no-snippets`: 2,968 files scanned, 0 compatibility errors/warnings.
- `luac5.3 -p`: all 17 changed tracked Lua files parsed successfully.
- Translation catalog JSON validation and embedded translation smoke tests: 3/3 PASS; EN/TL public translation integration PASS.
- Bounded real-worker performance: 2 samples plus warmup per case, 6 serialized turns; bounded recent-event/dialogue caps and strictly increasing semantic sequences remained intact. This is non-native worker evidence, not SP/MP evidence.
- Persistence measurement: friend/mother/lover snapshots retain only detailed `startingRelationship`; derived `bond`, `speechStyleContext`, and `semanticSuggestions` are absent from NPC persistence and worker ModData projection.
- `git diff --check` passed. ProjectHoomans remains on `main` ahead of `origin/main`; psychopatzCore and DynamicTrading remain clean on their existing `main` branches at `443b3a8` and `5db64cb`.

## Developer-side handoff

**READY FOR USER LIVE TEST**

Native Project Zomboid SP/MP acceptance remains **UNTESTED / user-owned**. Do not publish or upload Workshop content as part of this handoff.
