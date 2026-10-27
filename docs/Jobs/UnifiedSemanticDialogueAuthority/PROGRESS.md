# Unified Semantic Dialogue Authority — Current Progress

**Status:** IN PROGRESS — P0 through P10, P11A and P11B0 are accepted foundation. P11B wording work is next and may resume only by cohesive Conversation domain shard; P11B–P11I remain mandatory afterward.

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
| P9 — scale/MP/final acceptance | **ACCEPTED** |
| P10 — canonical semantic cleanup / legacy purge | **ACCEPTED** |
| P11A — steady-state Conversation source hygiene | **ACCEPTED** |
| P11B0 — modular Conversation source & generation foundation | **ACCEPTED** |
| P11B–P11I — canonical wording, modular authoring refinement, UI registry, Studio and final acceptance | **NEXT / MANDATORY** |

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
source-controlled artifacts; runtime inspection is bounded and lazy. The
historical first-party definition files were removed in P10A after the
semantic/content parity proof; the remaining migration work is now limited to
the live CompanionCommandFlavor wording owner and naming/schema cleanup.

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

P9 is accepted. Event context-reference patterns require the matching disclosed
lifecycle offer when an event window is active, preserving ordinary
quantity/weather/health question routing. ToolReply responses reuse the
existing SpeechRealization seam so generated Dialogue Content owns EN/TL
wording, and candidate review compares semantic plan metadata separately from
editable wording. The real-worker routing regression set is `42/42` in
`150.76s`; the corrected ToolReply/translation/Observatory check ran `9`
tests with `8` PASS, `0` FAIL, and `1` expected Tk-only SKIP.

The new resource-aware Python acceptance runner executes each module in an
isolated subprocess, caps the default lane at four jobs, preserves one-worker
serialization inside each process, serializes canonical/generation mutators,
and reports module status, return code, timeout, duration, and a slowest-module
table. The latency-budget module is additionally isolated as a resource-
sensitive serial case; its existing assertion was not weakened. Runner
characterization coverage is `5/5`.

Final developer-side evidence:

- full headless Python: `157 PASS / 0 FAIL / 0 SKIP` modules, `56` expected
  display-dependent test skips, four active processes maximum, `368.15s`;
- focused Xvfb GUI/lifecycle lane: `29 PASS / 0 FAIL / 0 SKIP`, four active
  processes maximum, `101.72s`;
- full native Lua suite: `898/898 PASS` with four workers, `6.35s` wall time;
- installed-PZ Kahlua verification: `3195` files scanned, `0` flagged,
  `0` errors, `0` warnings;
- source/save safety subset: `8/8 PASS` in `29.41s`; real-save hash remained
  unchanged through the SAVE lifecycle tests;
- CodeBuilder ran twice after the final content update; all generated hashes
  remained identical (`168` phrase families, `179` phrases, `1` player-choice
  artifact);
- `git diff --check`: PASS.

Measured Semantic Lab startup samples were fixture worker-ready `1.73–1.94s`
and fixture-through-Explore `1.75–1.96s`; remembered-SAVE restoration completed
in `2.41–2.53s` after worker-ready at `1.60–1.73s`. The isolated real-worker
performance benchmark retained bounded six-event/twelve-turn observations and
strictly increasing worker sequences/timestamps. The old serial acceptance
remains diagnostic evidence only: its interrupted run reached `608.35s`, and
the earlier complete serial diagnostic was approximately `1001.81s` with
`635` tests, `25` failures, `4` errors, and `56` display skips.

## Post-P9 audit that reopened the goal

Audit baseline: `fa1d9f9f1332e5d2a870a02e6abcfd885d7a7f0f`.

The semantic runtime migration is accepted, but the source/UI steady state is
not yet clean enough for user live acceptance:

- `PNC_SocialFlavorDefinitions*` remains executable production-tree source with
  13 first-party Flavor registrations;
- first-party compatibility Flavor definitions remain;
- `PNC_ConversationToolReplyCatalog.lua` remains and the production worker still
  loads it as `tool_catalog`;
- `PNC_CompanionCommandFlavor*` remains loaded and still resolves wording for
  some command/emote/greeting paths;
- semantic context/address helpers still expose obsolete Flavor namespaces;
- Dialogue Content remains migration-heavy: ~242 KB, 168 families / 179
  phrases, 167 `.migrated.` IDs, 167 `MIGRATED_*` concepts, 167 `legacySource`
  entries and ~1,674 repeated locked fields;
- Responses is a flat 191-pool list and Dialogue Content is a flat 168-family
  list.

These findings supersede the previous `READY FOR USER LIVE TEST` handoff but do
not invalidate P0–P9 behavior/test evidence.

## Accepted P10A — dead first-party registry purge

P10A is accepted. The executable first-party prose registries are gone from
the production tree: all `PNC_SocialFlavorDefinitions*` shards, the Bandits,
Necroa and Project ALife Hoomans Flavor-definition files, and
`PNC_ConversationToolReplyCatalog.lua` were deleted. The production worker no
longer loads the ToolReply catalog, and no production/runtime load or require
reference to the deleted surfaces remains.

The semantic/content parity proof covers safety, player-spoke, witnessed kill,
follower abandonment (including the zombie cause), horde, retreat, all
incapacitated call/update/repeat phases, all leader-loss grief lanes, Bandits,
Necroa, Project ALife and Companion Dogs. Leader-loss close, colonist and
distant variants were restored in the existing ResponseCatalog and canonical
Dialogue Content source before deletion; CodeBuilder regenerated the existing
runtime registry and EN/TL artifacts deterministically.

P10A evidence: focused native semantic/retirement/lifecycle set `10/10 PASS`
in `0.13s` wall time; focused Python content/Observatory/compiler set
`27/27 PASS` in `22.04s`; targeted PZ Verify Kahlua scans covered `25` Lua
files with `0` errors / `0` warnings; deleted-surface and worker-load scans
are clean; `git diff --check` passes. The canonical source remains
migration-heavy until P10D (`246,392` bytes, `171` families, `182` phrases,
`170` migration IDs/concepts/source records).

## Accepted P10B — canonical command, emote, greeting wording

P10B is accepted. Project Hoomans command acknowledgements/rejections, player
and NPC emotes, greetings, and Companion Dogs wording now resolve through the
existing semantic ResponseCatalog → ResponsePlan/RealizationAuthority →
SpeechRealization → Dialogue Content path. The six `PNC_CompanionCommandFlavor*`
registry/definition files are deleted, composition no longer loads them, and
missing semantic realization is explicit rather than a first-party prose
fallback. External compatibility adapters still provide facts and event
identity only.

P10B evidence: the semantic command/emote/greeting negative-absence and parity
set passes `11/11`; focused Dialogue Content/Observatory/compiler tests pass
`9/9`; CodeBuilder regenerated `216` families / `395` phrases / `1` player
choice twice with identical artifact hashes; changed Lua syntax checks pass
for `33` files; `git diff --check` passes. P10D canonical-source groundwork
is included: schema v2 derives family IDs, concepts, translation keys, and
ownership from semantic IDs and removes migration metadata from the source.

## Accepted P10C — semantic naming and speech presentation cleanup

P10C is accepted. Project Hoomans now exposes social-context classification as
`PNC.Semantics.SocialContext` with `SocialContextConstants`, semantic
addressing as `PNC.Semantics.AddressResolver`, and PNC-owned delivery as
`PNC.SemanticSpeechPresentation`. The old `PNC.FlavorText*`,
`PNC.FlavorAddress*`, and `PNC_SocialFlavorPresentation*` production surfaces
are absent. Downed distress packets and the migrated event adapters use
`speechEventID`; the remaining `flavorID` fields are explicit transport
boundaries for generic PsychopatzCore or legacy Conversation Memory/Gossip
infrastructure. Threat, audience, need, grief, identity disclosure,
relationship-address terms, and repetition avoidance remain unchanged.

P10C evidence: the namespace/address/speech presentation native set is green,
the incapacitated speech lifecycle remains green after the naming cleanup, and
the P10F negative-absence smoke confirms the deleted production paths.

## Accepted P10D — compact Dialogue Content schema

P10D is accepted. CodeBuilder now consumes schema v2 canonical content with
semantic template identity as the join. Mechanical family IDs, concepts,
translation prefixes, style suffixes, fingerprints, and ownership are derived
deterministically. The current source is `105007` bytes with `216` phrase
families, `395` phrases, and `1` player-choice artifact; generated Registry,
EN, and TL artifacts contain no `.migrated.`, `MIGRATED_*`, `legacySource`,
`semanticAuthority`, duplicated response-pool/variant IDs, or migration-era
locked metadata. ResponseCatalog plans remain the meaning/follow-up authority;
Dialogue Content remains the wording authority.

P10D evidence: compact-content, generated-content, EN/TL parity, ToolReply,
and idempotence tests are green. Catalog wording fallbacks were removed for
the migrated command, greeting, compatibility, medical, social-reaction, and
ToolReply families; unavailable semantic realization is explicit.

## Accepted P10E — shared hierarchical Semantic Lab projection

P10E is accepted. Responses and Dialogue Content now project the same bounded
semantic tree directly from canonical `semantic.*` IDs. Branch labels are
humanized, descendant counts and full canonical IDs are visible, searches
retain matching ancestors and auto-expand matches, and leaf details remain
lazy. Existing paging, filters, source/provenance detail, and ownership
boundaries remain intact; no hierarchy database was introduced.

P10E evidence: the shared tree projection tests pass, including branch-match
auto-expansion, and the Studio panes retain bounded page and lazy-detail
behavior. Focused Xvfb Studio acceptance remains part of the final P10F gate.

## Accepted P10F — final zero-legacy acceptance

P10F is accepted. The repository now has literal canonical ownership: the
ResponseCatalog selects semantic meaning, Dialogue Content supplies the one
first-party wording realization, lifecycle/context owns continuation and
follow-up state, and `PNC.SemanticSpeechPresentation` only delivers selected
speech. The production tree contains zero `PNC_SocialFlavorDefinitions*`,
`PNC_ConversationToolReplyCatalog.lua`, `PNC_CompanionCommandFlavor*`,
`PNC.FlavorText*`, `PNC.FlavorAddress*`, or PNC
`PNC_SocialFlavorPresentation*` files, and zero worker/composition loads for
them. The negative absence smoke and source scans also prove no first-party
`Flavor.Resolve`/`Flavor.Register` wording path, no compatibility
`compatibilityFlavorID`, and no canonical-content migration markers remain.

The remaining Flavor terminology is compatibility transport only: generic
PsychopatzCore `SocialFlavorClient` queue/arbitration/TTS/nameplate APIs,
PBrainZ ambient submission, the Necroa-owned zombie-caption adapter, and
Companion Dogs' external presentation bridge. Their providers/transport carry
facts or event identity; Project Hoomans semantic pools choose Hoomans
meaning and Dialogue Content chooses Hoomans wording. `flavorID` remains only
at those explicit external Core transport boundaries.

The compact canonical source is schema v2: `105,007` bytes, `216` phrase
families, `395` phrases, and `1` player-choice artifact. Generated artifacts
are `205,402` bytes for the runtime Registry, `39,671` bytes for EN, and
`39,924` bytes for TL. The pre-P10 audit baseline was approximately `242 KB`,
`168` families / `179` phrases, `167` `.migrated.` IDs, `167` `MIGRATED_*`
concepts, `167` `legacySource` records, and about `1,674` repeated locked
fields. Two consecutive CodeBuilder runs produced identical SHA-256 outputs:
Registry `1fa7e66c367a9b200f7ae0881bb853057210ddcb3f1934ac802885e7133111b0`,
EN `9fe0479e03896e26754a2ea71e36d5883b171cf5b67592fd12e4189c94154558`, and
TL `66cbb1ba5aaa862ef7d5a459e1cd01bc312632b1091ce0a73b029665908d953c`.

Responses and Dialogue Content now share the derived semantic tree projection:
humanized branches, descendant counts, search ancestor retention and
auto-expansion, canonical IDs in details, exact provenance, bounded paging,
and lazy variant/detail retrieval. No hierarchy database was added. Existing
event follow-up, command/emote/greeting, medical, social, compatibility,
PBrainZ, and EN/TL parity coverage remains green.

Final developer-side evidence:

- Resource-aware headless Python: `159 PASS / 0 FAIL / 0 SKIP` modules, `56`
  expected display-dependent individual skips, maximum `4` active child
  processes, `393.81s` wall time. Slowest modules were Response Observatory
  `91.75s`, harness `59.65s`, contextual talk parity `45.39s`, contextual
  social reactions `41.77s`, and automatic flow generation `41.41s`.
- Focused Xvfb GUI/lifecycle lane: `14 PASS / 0 FAIL / 0 SKIP` invocations,
  `49/49` tests, four active subprocesses, `47.89s` wall time. The focused
  P3B module passed all four lifecycle tests in `25.32s`.
- Startup samples: fixture worker-ready `1.697–1.740s`, fixture through
  bounded Explore `1.721–1.765s`; remembered SAVE worker-ready
  `1.802–1.831s`, remembered restoration `2.692–2.697s`. The product remains
  read-only and uses the immutable imported source snapshot after worker
  restart.
- Native Lua: `901/901 PASS`, four workers, `6.85s` shell wall time.
- Installed-PZ Kahlua: project verifier `123` files, pass; full `pz-verify`
  scan `3,346` files, `0` errors / `0` warnings, no game launch.
- Source/save safety: `18/18 PASS` selected real-save/import/re-hydration
  tests in `55.90s`; the real save SHA-256 stayed
  `b5e53dd9e1c92cb4a8cc7cbe963953ca25c9c5617b6764a3da32deba96df6518`.
- Runner characterization, including bounded jobs, failure propagation,
  exclusive serialization, child cleanup, timing reports, and slowest-module
  reporting, remains `5/5 PASS`. The previous serial full-suite run remains
  diagnostic evidence only (interrupted `608.35s`; earlier complete diagnostic
  approximately `1001.81s`).
- `git diff --check`: PASS.

P10A–P10F are complete and remain accepted foundation. The prior
**READY FOR USER LIVE TEST** handoff is superseded by the post-P10 P11 audit
below; native SP/MP remains user-owned only after P11 developer acceptance.

## Post-P10 audit that reopened the parent goal

Audit baseline: `7c9e91d096f52909c1470b12a7e08e747ddc0ab4`.

Verified gaps:

- the canonical Dialogue Content source is still one ~105 KB / 216-family /
  395-phrase authoring monolith;
- `Responses.json` has 144 live production keys and `Realizations.json`
  remains a second live realization-key family;
- LocalResponse retains hard-coded English fallbacks and
  `LEGACY_TEXT_FALLBACKS`;
- current pattern/definition sources mix NLU, flows and response wording;
- 67/193 response pools are named `semantic.generated.*`, exposing build
  provenance as semantic taxonomy;
- Studio still separates Responses, Interactions and Dialogue Content;
- Interactions duplicates response pools while also containing genuinely useful
  route/trigger/flow/capability evidence;
- Developer Tools still exposes low-level Flow editor / Canonical source editor /
  Block contracts / Interaction composer / Legacy build workflow;
- Dialogue Content's safe editor can replace wording but cannot add/delete/
  reorder phrase variants;
- `conversation.landing:whats_up` is canonical, but its child membership/order
  is still distributed through Lua providers and group projection;
- dynamic relationship/gossip/camp/capability eligibility correctly remains
  production-owned and must not be moved into editable UI data.

These are post-P10 authoring/tooling/modularity defects. They do not invalidate
the accepted semantic runtime authority work.

## Accepted P11A — steady-state Conversation source hygiene

P11A is accepted. Migration-only runtime vocabulary was removed from the
category/composer/suggestion contracts: `legacyRegistry` and `migrationPhase`
are no longer emitted, and `legacyTrace` locals were renamed to neutral trace
names without changing Core debug behavior. The LocalResponse registration
seam for `LEGACY_TEXT_FALLBACKS` was removed. First-party compatibility bridge
names now describe speech/caption transport (`Bandits.SpeechBridge` and
`Necroa_ZombieCaptionAdapter`), and Companion Dogs uses a speech transport
name while retaining its external behavior.

The historical P8/P10 absence checks were consolidated into
`pnc_conversation_architecture_contract_smoke.lua`; domain and compatibility
behavior tests remain in place. Focused production-Lua coverage is `6/6 PASS`,
focused Python coverage is `15/15 PASS`, and the Project Hoomans Kahlua scan
reported `0` errors / `0` warnings across `3,164` files. No source save,
native Project Zomboid session, or Workshop operation was touched.

## Recovery audit — rejected P11B–P11H attempt

The repository was returned to verified P11A content through recovery commit
`18eacad50745e445c92639d1ce77d487d1da07fd`. Its tree matches P11A anchor
`08081ac8`.

The first bad implementation commit was `535c9598` (the previous P11B wording
consolidation). Established cognition/fact/gossip/social/state tests were green
before it and failed from that commit onward. The rejected stack also introduced
a 292-entry runtime-key alias architecture, retained the old Developer Tools
beside the new editor, and added an unauthorized mandatory P12.

Recovery validation:

- full native Lua: `897/897 PASS` in 6.57s;
- representative cognition/fact/gossip/social/state regressions: `5/5 PASS`;
- `git diff --check`: PASS.

Rejected P11B–P11H acceptance claims are void. P11A remains accepted.

## Accepted P11B0 — modular Conversation source & generation foundation

P11B0 is accepted. The Conversation authoring model is now explicit and
manifest-backed rather than dependent on filesystem discovery or one giant
canonical/runtime file. The pre-migration inventory is preserved in the
compiler characterization: Dialogue Content had `216` phrase families,
`395` phrases and `1` player choice; Common Interactions had `47` patterns
and `13` response pools; Grounded Personal Dialogue had `7` patterns and
`13` response pools; Semantic Definitions had `2` flows/definitions; and the
static Conversation UI provider had `10` suggestions.

The accepted foundation includes:

- twelve cohesive canonical shards under
  `tools/semantic_harness/codebuilder/sources/conversation/` and one explicit
  ordered manifest with duplicate-path, duplicate-ID, missing/unregistered
  shard, per-shard schema, global uniqueness and cross-reference validation;
- one existing-CodeBuilder Conversation compiler that validates independently,
  merges in memory, canonical-sorts, and emits per-shard plus whole-model
  fingerprints and canonical-ID provenance/location records;
- generated compatibility snapshots for the four retired monolithic source
  files, with the modular shards remaining the only authoring source;
- bounded generated Conversation runtime shards: `41` Lua files, a `6,481`
  byte registry hub, a maximum generated shard of `56,114` bytes, and explicit
  `64 KiB`/`48`-record compiler bounds;
- generated domain translation bundles, a generated-only read-only aggregate
  snapshot, and the stable-ID service path that reports an owning shard,
  validates stale fingerprints, and writes only that shard before regenerating;
- response-observatory translation overlays updated to recognize the modular
  Conversation translation tree without changing gameplay or publication
  behavior.

Acceptance evidence:

- P11B0 compiler/authoring tests: `4/4 PASS`; focused affected authoring,
  translation, dataset and runtime tests: `50/50 PASS`; response-observatory
  matrix: `20` tests, `18 PASS`, `2` expected skips;
- full Python discovery: `649` tests, `OK`, `56` expected skips;
- native Lua regression: `897/897 PASS`;
- two consecutive CodeBuilder generations matched byte-for-byte across `110`
  Conversation source/generated/translation artifacts;
- full Project Hoomans Kahlua scan: `3,387` files, `0` errors and `0` warnings;
  installed Project Zomboid Kahlua compiler: `123` files passed, `0` source
  writes, no game launch;
- `git diff --check`: PASS. Source-save guards remained green in the full
  suite, and no native Project Zomboid session, source save, Workshop
  publication or remote branch was touched.

## Accepted P11B — Wellbeing wording domain slice

The first post-P11B0 wording slice is accepted. The manifest-backed
`content/wellbeing.json` shard now owns ten fixed, no-argument
`semantic.question.wellbeing.*` families: default, injured, panic, stress,
thirst, thirst alternate, hunger, hunger alternate, fatigue, and fatigue
alternate. Default and injured preserve all four EN/TL style phrases; the
other eight preserve their neutral-only route behavior. Existing wellbeing
selection, health/need precedence, grounded/follow-up ownership, effects,
transport, and tool-call behavior remain outside the wording change.

The old static map entries, `Responses.json` records, and default/injured
`Realizations.json`/`Status.lua` wording are retired for the migrated IDs.
`Status.lua` retains only the empty registry-membership shell for the two
style-capable families. The canonical shard emits the bounded Wellbeing Lua
and EN/TL translation artifacts with generated Content keys. The
`semantic.question.wellbeing.unknown` route remains on its legacy map because
the same ID is already a response-pool owner; the compiler's global uniqueness
guard rejects a duplicate until that response-pool boundary is migrated as a
coherent slice.

Evidence: focused Wellbeing/compiler/authoring/translation/regression set
`77/77 PASS`; native Lua `897/897 PASS`; two consecutive CodeBuilder runs
matched across `120` source/generated/translation artifacts; Project Hoomans
Kahlua scan `3,388` files with `0` errors/warnings; installed Project Zomboid
Kahlua compiler `123` files passed with `0` source writes and no game launch;
`git diff --check` passes.

## Accepted P11B — Needs wording domain slice

The second post-P11B0 wording slice is accepted. Manifest-backed
`content/needs.json` now owns ten fixed, no-argument
`semantic.question.needs.*` families across offer, quantity, and proposal
wording. Hunger offer preserves its four EN/TL styles; the other nine families
remain neutral-only. Need predicates, grounded references, response plans,
follow-up flow state, and dynamic eligibility/effects remain in their existing
runtime owners.

The old ten fixed `Responses.json` keys, four hunger `Realizations.json` keys,
the static Needs translation-key map entries, and the legacy `NeedsHunger`
Status family are retired. Parameterized dataset variants remain in the flow
response-pool shard; no aliases or generated-source edits were introduced.

Acceptance evidence: focused Needs/compiler/contextual tests `12/12 PASS`; full
isolated Python acceptance runner `162` modules passed, `0` failed, `0` skipped;
native Lua `897/897 PASS`; two consecutive generations matched byte-for-byte
across `117` source/generated/translation artifacts (SHA-256
`8032228038781d5f87bfe24dfd18a70edc1de1414ac70223e243180f4b1d2ecb`); full
Project Hoomans `pz_verify --kahlua` scan passed over `3,389` files with no
errors or warnings; installed Project Zomboid Kahlua compiler passed `123`
files with `0` source writes and no game launch; `git diff --check` passes.

## Immediate Next Chunk — P11B Health wording domain shard

Characterize and migrate the cohesive fixed Health wording domain next,
preserving medical fact selection, dynamic health eligibility/effects, and
grounded/follow-up ownership. Use the manifest/compiler, generated domain
bundles, aggregate snapshot and ID-addressed authoring service; defer
parameterized medical response-pool boundaries until characterized. Do not
edit generated artifacts as sources, introduce aliases, or migrate one key at
a time.

Do not begin P11C, P11D or P11E taxonomy cleanup until the selected P11B domain
slice has its own characterization and acceptance evidence. Do not create P12
or another mandatory parent phase.

## Historical P11A starting instructions (completed)

Read `P11_MODULAR_CONVERSATION_ARCHITECTURE.md` before editing.

Start with steady-state hygiene:

1. re-enumerate remaining migration-only production vocabulary/fallbacks and
   exact callers;
2. remove `LEGACY_TEXT_FALLBACKS` only after canonical-content parity proof;
3. remove dead `legacyRegistry`, `migrationPhase`, `legacyTrace` and
   equivalent migration-only fields with caller proof;
4. rename legitimate compatibility speech bridges whose filenames still imply
   obsolete Flavor authority without changing external behavior;
5. consolidate historical P8/P10 absence tests into durable architecture
   contracts while preserving domain behavior tests;
6. run focused Lua/Python/Kahlua/idempotence checks;
7. update this progress ledger, then continue automatically through
   P11B–P11I.

Do not start by redesigning Semantic Lab. First make the source contracts clean,
then consolidate wording, modularize sources, introduce the Conversation UI
registry, clean semantic IDs, and finally rebuild the Studio/editor over those
canonical services.

## Stop conditions

Stop before P11 developer acceptance only for:

- genuine unsafe repository divergence/concurrent ownership conflict;
- a proven externally consumed Project Hoomans public API whose removal/rename
  requires a compatibility decision not already covered by the job;
- missing required dependency/toolchain with no accepted fallback;
- a proven architecture conflict requiring user decision.

A P11 subphase passing is not a stop condition. Continue automatically through
P11I.
