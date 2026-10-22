# Contextual Dialogue Persona & Choices — Current Progress

**Updated:** 2026-10-22

**Parent status:** IN PROGRESS — corrective P8 sequence

**Completed corrective phase:** P8A — bond vocabulary + production-faithful Semantic Lab baseline

**Next mandatory phase:** P8B — behavioral speech completion

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

Revision pending: production-backed speech-family completion is implemented locally and validated; commit it before moving to P8C.

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

Audit the current `DialogueChoiceRegistry` collection path and remove remaining central provider-specific discovery calls. Make registered providers discoverable through one bounded generic contract while preserving root/flow/response-plan offers, privacy, deterministic ranking/dedupe, click-frame identity, stale/replay rejection, existing authority/effect ownership, Dynamic Trading isolation, and one existing Core `choicesPart` UI lane. Add one real contextual social/relationship provider and focused real-worker provider-discovery tests before continuing to P8D.
