# Unified Semantic Dialogue Authority — Current Progress

**Status:** IN PROGRESS — P0 through P8 accepted; P9 is the active implementation slice.

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
- `PNC_ConversationToolReplyCatalog.lua` remains only migration/source material;
  semantic ToolReply pools now own production selection.
- Wellbeing/small-talk/ask-about report semantic response-flow authority while
  ConversationBlocks retain registry data, gates, branches, effects, and repeat
  behavior.
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
| P3 — lower-risk native SocialFlavor migration | **ACCEPTED** |
| P4 — complex medical/incapacitated migration | **ACCEPTED** |
| P5 — ToolReplies + legacy registry migration | **ACCEPTED** |
| P6 — compatibility semantic adapters | **ACCEPTED** |
| P7 — canonical content coverage / Studio observability | **ACCEPTED** |
| P8 — retire first-party legacy prose authority | **ACCEPTED** |
| P9 — scale/MP/final acceptance | **IN PROGRESS** |

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

## Accepted P3 — lower-risk native SocialFlavor migration

- Farewell, conversation safety, player-spoke acknowledgement, witnessed
  player kill, follower abandonment, horde detection/stamina retreat and
  leader loss now select semantic response plans before presentation. Their
  packets carry selected text, semantic ownership, response-plan/realization
  provenance, bounded event refs and disclosed fact capsules where the event
  supports them.
- Direct social-event producers no longer inherit a generic lifecycle speech
  beat before their semantic delivery edge. This avoids duplicate selection
  and preserves the selected plan's exact follow-up offers.
- Event follow-up offers are filtered by authoritative disclosed facts before
  they enter the existing lifecycle window. Unsupported abandonment/safety
  questions remain hidden rather than producing speculative answers.
- Existing `PNC_SocialFlavorDefinitions_*` files remain migration source
  material for later canonical content/retirement work; no first-party
  migrated caller uses them as the meaning selector.
- P3 negative characterization coverage runs without loading those definition
  shards and proves semantic selection/text for all listed families. The
  existing witness, abandonment and leader pipeline tests now assert explicit
  semantic ownership and provenance.
- P3 focused evidence: Lua `6/6`, production worker P2 follow-up `2/2`, and
  the existing family regressions remain green. No native Project Zomboid or
  source save was used.

## Accepted P4 — complex medical/incapacitated migration

- Added phase-specific semantic medical pools for incapacitated call, update,
  repeat, witnessed teammate hurt, and treatment acknowledgement. The selected
  ResponsePlan and wording are produced before the existing presentation queue.
- Downed distress now carries a typed event reference, an authoritative bounded
  fact capsule, selected text, semantic ownership, and filtered follow-up offers.
  Teammate hurt and treatment use the same lifecycle contract; missing attacker,
  need, or health facts do not create speculative offers.
- Existing health, wound, treatment, stamina, and inventory authorities remain
  unchanged. Legacy incapacitated and teammate prose definitions remain only as
  migration source material in this slice.
- P4 negative proof deliberately omits first-party SocialFlavor definitions and
  still verifies semantic call/update/repeat/medical selection. Focused Lua
  evidence is `5/5`, including the new medical authority smoke and direct
  producer regressions. `pz-verify` reports zero Kahlua errors on the changed
  Lua surface.

## Accepted P5 — ToolReplies and legacy category ownership

- Added bounded semantic ResponseCatalog pools for social ToolReply outcomes,
  ask-name identity outcomes, and companion order acknowledgements/rejections.
  The compatibility `Build` API remains stable for PBrainZ, while
  `BuildDetailed` carries semantic ownership, content owner, response-plan,
  realization, and pool provenance.
- Production ToolReplies no longer require or read
  `PNC_ConversationToolReplyCatalog.lua`; the old table remains source material
  only. Existing EN/TL wording keys continue to resolve through the same
  translation facade remains migration/source material below the canonical
  Dialogue Content owner established in P7.
- The three legacy conversation categories now report
  `semantic_response_flow` as meaning authority and explicitly retain
  `conversation_registry` only for eligibility/gates/effects data. Branch,
  effect, and repeat authority is unchanged.
- P5 negative proof substitutes a legacy ToolReply table and verifies that the
  semantic result is unchanged. Focused P5 plus PBrainZ, translation,
  Conversation registry/flow, and P1–P4 regressions pass `16/16`.

## Accepted P6 — compatibility semantic adapters

P6 is accepted. Bandits, Necroa mask warnings, Project ALife meta/encounter/
faction events, and the additional Companion Dogs greeting/feed adapter now
select bounded semantic compatibility pools before presentation. Provider
facts and native Necroa zombie captions remain external compatibility
authority; Hoomans-owned missing realizations suppress delivery rather than
falling through to first-party legacy prose.

Focused P6 compatibility, producer, and P1–P5 regression evidence passes
`16/16`; the producer coverage includes Bandits damage commentary, Necroa
mask warning, Project A-Life meta presentation, and Companion Dogs feed.

## Accepted P7 — canonical Dialogue Content and Observatory ownership

P7 is accepted. The migrated semantic families now resolve through the existing
generated Dialogue Content Registry rather than legacy first-party prose keys:
168 bounded phrase families and 179 phrase records have stable semantic
template/content identities, explicit content owners, EN/TL key parity, and
content-only phrase variation. ToolReply semantic templates no longer derive
their realization identity from hashed legacy fallback text; the old keys remain
translation/source material for migration review.

ResponsePlan literal segments are promoted at the semantic normalization seam
to Dialogue Content translation segments. ResponsePlan still selects meaning
and bounded follow-up offers exactly once; SpeechRealization applies the
selected content phrase without introducing another selector. Semantic Lab
response-pool list/detail now exposes production authority, content owners,
plans, bounded follow-up offers, fact references, and selection provenance.

P7 evidence: focused Python content/Observatory/compiler regression `34/34`,
production Lua P4–P7 semantic/content smoke `4/4`, the new P7 Kahlua smoke
`0` errors, and CodeBuilder generation repeated deterministically with
`168` families / `179` phrases on both runs.

The generated Dialogue Content source and registry remain compile-time,
source-controlled artifacts; runtime inspection is bounded and lazy. Existing
legacy definition files remain migration source material but are no longer
loaded by production composition; P8 proves that no first-party caller still
uses them as a selector.

## Accepted P8 — first-party selector retirement

P8 is accepted. Production composition no longer loads the migrated
`PNC_SocialFlavorDefinitions_*` shards or Bandits/Necroa Hoomans flavor
definition shards. Project ALife definitions remain unrequired source material
for the external adapter. Semantic event, medical, compatibility, greeting,
and companion acknowledgement paths therefore enter presentation only after
ResponseCatalog selection.

The diary hydrator now preserves selected persisted wording and resolves only
canonical Conversation Content keys; it cannot reselect from a `flavorID`.
The command interaction queue cannot replace a selected semantic realization
with a legacy line, and missing semantic NPC acknowledgement/ambient
realization fails explicitly. The remaining CompanionCommandFlavor calls are
bounded compatibility-only helpers for non-semantic command/emote callers.
Conversation category metadata now reports semantic response-flow authority
and registry data/effects projection rather than legacy registry authority.

P8 evidence: Lua retirement/semantic negative smoke `6/6`, composition and
command/diary regression set `8/8`, Python category/legacy/content set `20/20`,
and `pz-verify` Kahlua scans for the eight changed Lua files `0` errors / `0`
warnings.

P9 routing/content repair slice is accepted: event context-reference patterns
now require the matching disclosed lifecycle offer when an event window is
active, preserving ordinary quantity/weather/health question routing; ToolReply
responses reuse the existing SpeechRealization seam so generated Dialogue
Content owns EN/TL wording; and candidate review compares semantic plan
metadata separately from editable wording. The real-worker routing regression
set is `42/42` in `150.76s`; targeted ToolReply/translation/observatory checks
are green. The complete P9 acceptance gate remains active.

## Immediate Next Chunk — P9

Run the complete developer-side acceptance once: full headless Python,
focused Xvfb GUI/lifecycle modules, production Lua, installed-PZ Kahlua,
CodeBuilder/content idempotence, source/save data-safety, performance timing,
and `git diff --check`. Keep generic PsychopatzCore SocialFlavor infrastructure
and external provider compatibility authority intact.

## Stop conditions

Stop before developer-side completion only for:

- genuine unsafe repository divergence/concurrent ownership conflict;
- missing required dependency/toolchain with no accepted fallback;
- a proven architecture conflict requiring user decision;
- an explicit user-owned native acceptance gate after all developer work is
  complete.

A phase/test passing is not a stop condition.
