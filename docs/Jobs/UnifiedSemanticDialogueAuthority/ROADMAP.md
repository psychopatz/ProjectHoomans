# Roadmap — Unified Semantic Dialogue Authority

**Parent status:** IN PROGRESS — P0–P10 and P11A–P11D are accepted foundation; P11E–P11I remain active/mandatory, followed by mandatory P12 pragmatic conversational intelligence before live-test handoff.
**Completion rule:** phases organize work; completing a phase does not complete the parent goal. Continue automatically until all developer-side gates pass or a genuine blocker is reached.

## P0 — Reconcile authority inventory and freeze baseline

Audit the current post-P12/post-Observatory source rather than trusting older P11 “complete” claims.

Required:

- enumerate all `Flavor.Register`, `ResolveDetailed`, SocialFlavor conditional selection, ToolReply catalog reads, conversation-registry authority and compatibility prose paths;
- classify each path as gameplay/domain authority, semantic decision authority, content-only, presentation-only, transport-only, compatibility-only or dead;
- update `MIGRATION_MATRIX.md` with actual callers and tests;
- capture baseline behavior/performance for representative event speech and Conversation follow-up;
- add characterization tests where deletion/migration would otherwise be blind.

**Gate:** no first-party legacy dialogue owner is ambiguous.

## P1 — Standardize the semantic event realization boundary

Make one reusable path for known NPC/world/social events:

```text
authoritative facts
→ semantic event/context
→ explicit pool/flow
→ ResponseCatalog/ResponsePlan
→ realization/content
→ delivery
```

Required:

- reuse existing RealizationAuthority/ResponseCatalog/ResponsePlan;
- standardize event/fact/plan/realization provenance;
- ensure semantic selection occurs once before presentation;
- add guard/diagnostic preventing Project Hoomans semantic-owned events from silently falling through generic SocialFlavor prose selection;
- preserve generic Core compatibility for other adopters.

**Gate:** representative event can be delivered with SocialFlavor definitions removed/substituted without changing semantic selection.

## P2 — NPC-initiated event follow-up bridge

Reuse the existing lifecycle rather than adding a new subsystem.

Required:

- carry selected response-plan offers through `RecordNPCSpeech` / beat / response window;
- project eligible event follow-ups through existing Suggestions;
- typed follow-ups resolve through existing NLU + pending/context-reference resolution;
- clicked and typed equivalents converge;
- preserve interruptions/expiry/freshness;
- answer from event/fact refs or current authoritative re-observation;
- no transcript persistence or new event-chat database.

**Gate:** horde event end-to-end: NPC speaks → player follows up typed/clicked → grounded answer, all through existing semantic lifecycle.

## P3 — Migrate lower-risk native SocialFlavor families

Migrate first-party families whose context maps cleanly to existing semantic pools:

- farewell;
- conversation safety;
- player-spoke/social acknowledgement;
- witnessed player kill;
- follower abandonment;
- horde detection;
- leader loss.

Required per family:

- semantic condition/response mapping;
- accepted EN/TL wording moved into canonical content ownership where appropriate;
- optional grounded follow-up offers;
- presentation queue receives already-selected text;
- old first-party selector retired after parity.

**Gate:** listed families have one semantic authority and no hidden prose fallback.

## P4 — Migrate complex medical/incapacitated/retreat families

Migrate:

- witnessed teammate hurt;
- zombie stamina/retreat;
- incapacitated call;
- incapacitated update;
- incapacitated repeat;
- related medical/mercy/rescue wording.

Preserve health/medical gameplay authority. Convert legacy audience/need/mercy/grief-style classifiers into neutral semantic context providers when still useful.

**Gate:** medical event matrix is semantic-first, grounded, follow-up capable, bounded and parity-tested.

## P5 — Migrate ToolReplies and legacy conversation-registry categories

### ToolReplies

Move social reactions, ask-name, order acknowledgements/rejections and other first-party ToolReply wording into semantic response/content ownership.

### Legacy registry categories

Finish semantic ownership for:

- `projecthoomans:wellbeing`;
- `projecthoomans:small_talk`;
- `projecthoomans:ask_about`.

Do not replace ConversationBlocks effect/branch authority.

**Gate:** ToolReply catalog no longer owns migrated production prose and no target category reports `conversation_registry` as conversational authority.

## P6 — Compatibility semantic adapters

Audit/migrate first-party compatibility speech for:

- Bandits;
- Necroa;
- Project ALife;
- other current Project Hoomans compatibility adapters discovered in P0.

Provider/addon systems keep gameplay truth. Adapters expose bounded facts/event refs to semantic response selection.

**Gate:** compatibility speech uses semantic-first Project Hoomans realization without requiring first-party legacy prose fallback.

## P7 — Canonical content coverage and Studio observability

Expand Dialogue Content/translation ownership incrementally so migrated wording has one canonical content owner.

Required:

- stable phrase IDs;
- EN/TL parity;
- content-only phrase variation separated from semantic variants;
- Studio/Observatory can discover migrated event families, content owner, provenance and follow-up offers;
- no giant replacement database; generated/runtime artifacts remain bounded.

**Gate:** migrated families are inspectable/editable through the established content workflow with no duplicate text authority.

## P8 — Retire first-party legacy prose authority

After all family gates pass:

- remove/deprecate obsolete Project Hoomans `PNC_SocialFlavorDefinitions_*` decision content;
- remove/deprecate ToolReply production prose selectors;
- remove obsolete role/audience/need/grief response selectors;
- make missing semantic realization fail explicitly instead of choosing hidden first-party Flavor prose;
- retain presentation/transport/localization/TTS compatibility infrastructure that remains useful;
- rename misleading modules only when it reduces ambiguity without compatibility breakage.

**Gate:** source/caller audit finds no Project Hoomans first-party legacy prose selector above the semantic authority line.

## P9 — Scale, multiplayer, no-split final acceptance

Required:

- sparse pair/thread state;
- bounded event/follow-up stress;
- private/player-specific context isolation;
- no per-tick scans;
- no source-save mutation;
- no duplicate delivery/TTS;
- no semantic/gameplay authority regressions;
- full harness/Lua/Kahlua/content/idempotence/performance gates;
- final migration matrix complete.

**Gate:** one semantic conversation architecture owns direct and event-driven NPC speech plus grounded follow-up. Only user-owned native SP/MP acceptance remains.


## P10 — Canonical semantic cleanup and legacy purge

P0–P9 proved semantic-first behavior. P10 makes that architecture the literal
steady-state source/schema/UI structure.

Detailed contract: `P10_CANONICAL_SEMANTIC_CLEANUP.md`.

### P10A — hard legacy-file purge

Delete first-party SocialFlavor definition shards, ToolReply literal catalog,
and first-party compatibility Flavor-definition source after semantic/content
parity proof. Remove worker/composition loads and replace legacy-definition
tests with absence + semantic-parity tests.

### P10B — retire CompanionCommandFlavor wording registry

Migrate command/emote/greeting/rejection/dog wording into the canonical
ResponseCatalog → SpeechRealization → Dialogue Content path, then remove the
parallel registry/definitions and obsolete flavor IDs.

### P10C — normalize semantic helper names

Rename/merge FlavorText semantic context and FlavorAddress semantic addressing;
remove internal legacy aliases and update callers/tests. Rename Project Hoomans
presentation APIs/variables where Flavor terminology now falsely implies a
content authority.

### P10D — Dialogue Content schema v2

Remove migration-era IDs/metadata, use semantic identity as the canonical join,
derive mechanical IDs/keys where safe, group shared ownership once, and do not
keep a permanent v1 compatibility reader.

### P10E — hierarchical Studio

Derive a shared semantic tree projection for Responses and Dialogue Content.
Humanize branch labels, show counts, support search/auto-expand, and keep full
canonical IDs in detail views. No second hierarchy database.

### P10F — final no-legacy acceptance

Run source-absence, semantic/content parity, PBrainZ/compatibility, Studio,
CodeBuilder/idempotence, Lua/Kahlua, save-safety and resource-aware Python
acceptance. Record before/after source/runtime bytes and wall-clock timings.

**P10 gate:** Project Hoomans has one semantic response authority, one Dialogue
Content wording authority, one semantic lifecycle/context authority and a
presentation-only speech layer; no first-party legacy dialogue registry,
migration-era content schema, or misleading Flavor namespace remains.

Only after P10 passes may the parent return to `READY FOR USER LIVE TEST`.

## P11 — Modular Conversation Architecture & Contextual Authoring

P10 proved the zero-legacy semantic runtime. P11 makes the authoring/content/tooling
model scalable and user-facing.

Detailed contract: `P11_MODULAR_CONVERSATION_ARCHITECTURE.md`.

### P11A — steady-state hygiene

Remove remaining migration-only fallback/vocabulary/test archaeology, reconcile
stale P10 status, and rename legitimate compatibility speech bridges whose
names still imply obsolete Flavor authority.

### P11B — one first-party wording path

Migrate live first-party wording from `Responses.json`, `Realizations.json`,
LocalResponse English fallbacks and static mapping modules into Dialogue
Content. Runtime handlers return semantic template IDs plus bounded arguments.

### P11C — modular Conversation sources

Split monolithic/mixed authoring files into domain shards with one deterministic
manifest/compiler. Separate NLU/pattern authoring from response/content wording.

### P11D — canonical Conversation UI Registry

Move static landing/hub/child/order/label/navigation structure into one
declarative registry. It may reference registered predicates/providers but may
not own gameplay/domain authority.

### P11E — semantic taxonomy cleanup

Replace `semantic.generated.*` IDs with domain-meaning IDs for tasks, commands,
gifts and other generated flows. Keep generator provenance as metadata only.

### P11F — Studio consolidation

Use one Conversation explorer. Fold route/conditions/follow-ups/sources into the
selected item and retire Interactions as a redundant everyday browser.

### P11G — contextual Developer Tools editor

Repurpose Developer Tools to edit the currently selected Conversation item:
EN/TL wording, phrase variants/styles, and Conversation UI hub/child
presentation/navigation. Normal authoring must not require raw JSON or Lua.

### P11H — agent-friendly authoring API

Expose the same bounded inspect/edit/add/remove/reorder/validate/preview/write/
compile services to agents and the GUI, with stale guards and deterministic
outputs.

### P11I — final modular acceptance

Run architecture/source absence, EN/TL, UI registry, selected-item editor,
agent-service parity, typed/clicked/event, generated-flow, PBrainZ/
compatibility, save-safety, resource-aware Python, focused Xvfb, Lua/Kahlua and
CodeBuilder idempotence/performance gates.

**P11 gate:** Project Hoomans has one semantic meaning authority, one first-party
wording authority, one Conversation UI/navigation registry, one Conversation
browser and one contextual authoring service used by both humans and agents.

P11 completion is now an intermediate architecture/tooling gate. After P11 passes, continue automatically into P12; do **not** return the parent to `READY FOR USER LIVE TEST` yet.

## P12 — Pragmatic Conversational Intelligence & Dialogue Director

P11 leaves Project Hoomans with one clean semantic/content/navigation authoring
architecture. P12 makes the same runtime authority conversationally smarter and
less dependent on exact phrasing.

Detailed contract: `P12_PRAGMATIC_CONVERSATIONAL_INTELLIGENCE.md`.

### P12A — recognized-to-response parity and cognition baseline

Reproduce and repair the user-observed class where the parser recognizes a
high-confidence social meaning such as `HOSTILE_REMARK` but the displayed NPC
reply degrades to generic clarification. Trace the actual Core+Hoomans Lua
worker through selected IR, policy branch, response pool/plan, realization and
final text. Add a durable no-degrade regression.

### P12B — pragmatic interpretation

Use bounded candidate interpretations plus conversation context to distinguish
answer, challenge, accept/refuse, dismissal, interruption, ambiguity and other
conversational functions. Preserve quoted/negated/third-person safety.

### P12C — bounded conversation state

Extend the existing DialogueContextState/lifecycle with bounded topic salience,
pending questions/offers/requests, recent dialogue acts, referents,
commitments and suspended topics. Prove ellipsis/pronoun follow-ups and strict
player/NPC isolation.

### P12D — Dialogue Director

Choose among reusable conversational behaviors such as answer, clarify,
challenge, warn, retaliate verbally, defuse, refuse, ask follow-up, return to
topic and end conversation. Selection must be explainable and may use existing
personality/relationship/context projections without duplicating domain truth.

### P12E — beats and bounded initiative

Add lightweight conversational beat pressure over the existing lifecycle.
Prove argument escalation/reconciliation, first-contact interruption, one
grounded NPC follow-up, cooldown, dismissal and clean exit without scripted
sentence trees.

### P12F — safe underspecified-language inference

Normalize ordinary paraphrases into shared semantic desired states. Context may
help resolve language, but ambiguous social speech must never become an
irreversible gameplay mutation without sufficient authoritative intent.

### P12G — compositional response planning

Use existing ResponsePlan + Dialogue Content to express the selected behavior
with grounded facts, tone/style and optional return-to-topic. Preserve EN/TL,
offline determinism and PBrainZ parity against the same semantic plan.

### P12H — cognition observability

Extend the existing Semantic Lab/Observatory so a selected turn explains:
candidate meanings → pragmatic/context resolution → Director candidates and
rejection reasons → selected behavior → ResponsePlan/facts → final text →
effects/authority route. Raw JSON stays diagnostic, not the primary view.

### P12I — held-out conversational acceptance

Run noisy/typo, interruption/resumption, ellipsis/pronoun, ambiguity,
hostility/apology, wellbeing/medical, safe command inference, world-event
follow-up, typed/clicked, multi-NPC/player, EN/TL and PBrainZ parity scenarios.
Protected negatives must produce zero false gameplay dispatch. Run full
resource-aware Python, focused Xvfb, native Lua, Kahlua,
CodeBuilder/idempotence, save-safety, bounded-memory and performance gates.

**P12 gate:** Project Hoomans conversation is context-sensitive, explainable,
multi-turn and naturally tolerant of ordinary supported paraphrases while
retaining one semantic authority, one wording authority and conservative
gameplay-effect boundaries.

Only after P12 passes may the parent return to `READY FOR USER LIVE TEST`;
native Project Zomboid SP/MP remains the user-owned final acceptance surface.
