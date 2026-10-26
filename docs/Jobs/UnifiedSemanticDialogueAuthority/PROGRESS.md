# Unified Semantic Dialogue Authority — Current Progress

**Status:** IN PROGRESS — new parent goal initialized. No implementation phases are accepted yet under this roadmap.

## Audited baseline

- ProjectHoomans: `181b58bcc30dc65dc61d19a49d6238abca50ece9`, clean `main == origin/main` at goal creation.
- PsychopatzCore: `cf28189c57f7810f31d25c46c11eb88080f47baa`, clean `main == origin/main`.
- Semantic Observatory & Dialogue Quality developer acceptance is complete and becomes foundation.
- Semantic Interaction Lifecycle P0–P12 implementation remains foundation/history; its earlier P11 “legacy authority complete” claim is superseded only for residual prose/content owners documented by this new audit.
- No source save was mutated, native Project Zomboid was not launched, and no Workshop operation occurred while creating this goal.

## Verified starting facts

- Semantic response/realization authority already exists and modern event producers often use it.
- PsychopatzCore SocialFlavor client can still choose registered prose when selected text is absent.
- Project Hoomans still registers first-party SocialFlavor prose families.
- `PNC_ConversationToolReplyCatalog.lua` remains a separate first-party wording owner.
- wellbeing/small-talk/ask-about still advertise legacy conversation-registry authority.
- generic compatibility Flavor registrations still exist.
- `SemanticInteractionLifecycle` already records NPC speech, beats, event refs and response windows.
- `DialogueContextState` already owns bounded pending follow-up/agenda state.
- `ResponsePlan` already owns bounded offers/fact refs.
- Suggestions/ContextResolver already provide contextual follow-up machinery.
- Therefore the new event-follow-up feature must **reuse the existing lifecycle**, not create another registry/system.

## Phase state

| Phase | State |
| --- | --- |
| P0 — authority inventory/baseline | **NEXT / IN PROGRESS** |
| P1 — standardized semantic event realization boundary | NOT STARTED |
| P2 — NPC-initiated event follow-up bridge | NOT STARTED |
| P3 — lower-risk native SocialFlavor migration | NOT STARTED |
| P4 — complex medical/incapacitated migration | NOT STARTED |
| P5 — ToolReplies + legacy registry migration | NOT STARTED |
| P6 — compatibility semantic adapters | NOT STARTED |
| P7 — canonical content coverage / Studio observability | NOT STARTED |
| P8 — retire first-party legacy prose authority | NOT STARTED |
| P9 — scale/MP/final acceptance | NOT STARTED |

## Immediate Next Chunk — P0

Start with source-truth reconciliation, not deletion.

1. Re-enumerate every production caller of:
   - `Flavor.Register`;
   - generic SocialFlavor `Resolve/ResolveDetailed`;
   - `PNC_SocialFlavorDefinitions_*`;
   - `PNC_ConversationToolReplyCatalog`;
   - legacy conversation-registry category ownership;
   - compatibility flavor adapters;
   - semantic social/event realization and speech delivery.
2. Update `MIGRATION_MATRIX.md` with actual file/caller, authoritative facts, semantic target pool/flow, content owner, follow-up eligibility and disposition.
3. Add focused characterization tests for any family whose old behavior is not already covered.
4. Capture baseline counts/timings/state sizes needed by `PERFORMANCE_AND_SCALING.md`.
5. Do not remove a legacy selector in P0.

After P0 gate passes, continue automatically through P1–P9.

## Stop conditions

Stop before developer-side completion only for:

- genuine unsafe repository divergence/concurrent ownership conflict;
- missing required dependency/toolchain with no accepted fallback;
- a proven architecture conflict requiring user decision;
- an explicit user-owned native acceptance gate after all developer work is complete.

A phase/test passing is not a stop condition.
