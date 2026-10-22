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

## Next Chunk — P8B behavioral speech completion

Audit every exposed persona/relationship/role/situation input against actual `SpeechStyleContext` use. Add real effects or explicitly mark informational controls. Replace central trait-name checks with declarative speech metadata where practical. Build a machine-readable response-family coverage inventory and expand production-backed realization beyond greeting across wellbeing, needs, medical, identity, knowledge/context, acknowledgement, apology, offer/help, dispute/refusal, threat/hostility, event reaction, companion/action acknowledgement, Dynamic Trading entry, and quest/commitment where authoritative families exist. Keep semantic response identity and gameplay authority unchanged, use friend/family/lover as bounded realization classes, and preserve deterministic neutral fallback. Add focused real-worker matrices before continuing to P8C.
