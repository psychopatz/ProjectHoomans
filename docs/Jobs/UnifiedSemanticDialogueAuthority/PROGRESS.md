# Unified Semantic Dialogue Authority — Current Progress

**Status:** IN PROGRESS — P0, P1 and P2 accepted; P3 is the active implementation slice.

## Audited baseline

- ProjectHoomans: `f2390998d30dcab7ee1110a850c97b38f8fb1ee9` at goal creation;
  P0 began from clean `main == origin/main`.
- PsychopatzCore: `cf28189c57f7810f31d25c46c11eb88080f47baa`, clean
  `main == origin/main`.
- Semantic Observatory & Dialogue Quality developer acceptance is foundation.
- Semantic Interaction Lifecycle P0–P12 remains foundation/history; its earlier
  P11 “legacy authority complete” claim is superseded only by residual
  prose/content owners documented in this active audit.
- No source save was mutated, native Project Zomboid was not launched, and no
  Workshop operation occurred while creating the goal or accepting P0.

## Verified starting facts

- Semantic response/realization authority already exists and modern event
  producers often use it.
- PsychopatzCore SocialFlavor client can still choose registered prose when
  selected text is absent.
- Project Hoomans still registers first-party SocialFlavor prose families.
- `PNC_ConversationToolReplyCatalog.lua` remains a separate first-party wording
  owner.
- Wellbeing/small-talk/ask-about still advertise legacy conversation-registry
  authority.
- Generic compatibility Flavor registrations still exist.
- `SemanticInteractionLifecycle` already records NPC speech, beats, event refs,
  and response windows.
- `DialogueContextState` already owns bounded pending follow-up/agenda state.
- `ResponsePlan` already owns bounded offers/fact refs.
- Suggestions/ContextResolver already provide contextual follow-up machinery.
- The event-follow-up feature must therefore reuse the existing lifecycle, not
  create another registry or state system.

## Phase state

| Phase | State |
| --- | --- |
| P0 — authority inventory/baseline | **ACCEPTED** |
| P1 — standardized semantic event realization boundary | **ACCEPTED** |
| P2 — NPC-initiated event follow-up bridge | **ACCEPTED** |
| P3 — lower-risk native SocialFlavor migration | **IN PROGRESS** |
| P4 — complex medical/incapacitated migration | NOT STARTED |
| P5 — ToolReplies + legacy registry migration | NOT STARTED |
| P6 — compatibility semantic adapters | NOT STARTED |
| P7 — canonical content coverage / Studio observability | NOT STARTED |
| P8 — retire first-party legacy prose authority | NOT STARTED |
| P9 — scale/MP/final acceptance | NOT STARTED |

## Accepted P0 — authority inventory and characterization

- Re-enumerated every first-party `Flavor.Register` family, generic Flavor
  resolve caller, ToolReply wording path, legacy registry category,
  compatibility adapter, and semantic speech/presentation path.
- Replaced `MIGRATION_MATRIX.md` with actual production callers, fact
  ownership, target pools/flows, content owners, follow-up eligibility, tests,
  and retirement disposition.
- Added
  `tests/pnc_unified_authority_p0_characterization_smoke.lua`, which locks the
  observed `resolvedText` → legacy `flavorID` fallback gap before P1 closes it.
- Baseline focused harness evidence: semantic `87/87` in `1.81s` wall clock;
  social/compatibility selection `24/24` in `0.63s`; P0 characterization
  selection `5/5` in `0.52s`.
- P0 intentionally removed no selector and changed no semantic authority.

## Accepted P1 — semantic presentation boundary

- `PNC_SocialFlavorPresentation_Receive_Payload.lua` now normalizes the
  existing producer `resolvedText` field into the native `text` field and marks
  semantic-owned packets explicitly.
- `PNC_SocialFlavorPresentation_Receive.lua` rejects semantic-owned packets
  without selected text before Core queue admission, so they cannot silently
  invoke `Flavor.ResolveDetailed`.
- Receive provenance now passes the normalized event type into the lifecycle
  envelope builder.
- Focused boundary evidence: `pnc_unified_authority_p1_boundary_smoke` and
  the P0 characterization/presentation regressions pass `6/6`.
- Generic compatibility packets remain eligible for the generic Core Flavor
  fallback contract.

## Accepted P2 — NPC-initiated event follow-up bridge

- Event reactions now select one production `SocialReactions` realization and
  carry its exact `ResponsePlan` offer IDs, `eventRef`, `factRefs`, pool and
  realization provenance through `RecordNPCSpeech` and the existing lifecycle
  response window.
- Existing Suggestions projects only the active, disclosed event offers. It
  does not reselect a catalog variant, scan other NPCs/events, or persist
  rendered text.
- Event context-reference frames now carry `QUESTION` meaning, so clicked and
  typed follow-ups converge through the existing parser/router and local
  response path. Answers use authoritative event facts or an explicit unknown
  response.
- Real production-worker coverage now proves horde selection, lifecycle
  provenance, bounded offers, click/typed parity, no-fact suppression and
  lazy expiry. The existing Lua smoke test covers the same boundary and
  stale/private/no-facts cases.
- P2 focused evidence: Python worker `2/2`, Lua selection `5/5`; no native
  Project Zomboid or source save was used.

## Immediate Next Chunk — P3

Migrate the lower-risk native SocialFlavor families to semantic-first
production event flows while preserving the existing queue and presentation
infrastructure:

1. Finish semantic-first migration evidence for farewell, safety, player-spoke,
   witnessed kill, follower abandonment, horde/retreat and leader loss.
2. Move accepted wording into the existing Dialogue Content/translation owner
   where a family is migrated; keep legacy definitions only as characterized
   source material until parity is proven.
3. Add one-family-at-a-time negative proof that missing semantic realization
   cannot select first-party SocialFlavor prose.

After the P3 family gates pass, continue automatically through P4–P9.

## Stop conditions

Stop before developer-side completion only for:

- genuine unsafe repository divergence/concurrent ownership conflict;
- missing required dependency/toolchain with no accepted fallback;
- a proven architecture conflict requiring user decision;
- an explicit user-owned native acceptance gate after all developer work is
  complete.

A phase/test passing is not a stop condition.
