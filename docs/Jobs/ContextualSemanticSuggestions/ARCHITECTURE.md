# Architecture and contracts
## Single path
Player typed text -> existing Core NLU candidate interpretation -> active Hoomans dialogue flow / response plan -> suggestion candidate providers; NPC reply -> existing semantic response plan / selected dialogue acts -> same candidate providers. A lightweight input-preview adapter may produce **non-executing** suggestions while typing. Flow transition options and approved registered gameplay capabilities are further candidate sources.
Candidate registry -> declarative constraints -> visibility/eligibility decisions -> deterministic ranking/deduplication/top-K -> Hoomans UI & Semantic Lab projections. Button click carries a typed, stable semantic frame through the **existing** dialogue orchestrator, not a second NLU interpretation or direct server gameplay mutation. On execution, authoritative gameplay owner validates the request again; visibility is never authorization.
## Ownership
PsychopatzCore may own only generic versioned suggestion registry, predicate AST all/any/not, strict typed comparisons, deterministic ranking helpers and bounded trace contracts if its existing infrastructure does not already do so. ProjectHoomans owns dialogue content, speech realization, romance/social compatibility rules, eligibility adapters for real actor identity/traits/relationships/knowledge/inventory/factions, client presentation, conversation state, and server action adapters. Respect current Core NPC Foundation ownership and do not clone identity, relationship or knowledge state. Inspect current API first; use existing public APIs, no private state writes.
## Versioned proposal
```lua
{
 schema="semantic.suggestion.v1", id="social.ask_about_wellbeing",
 source={kind="npc_response_plan", turnID="..."},
 labelKey="conversation.suggestion.ask_wellbeing", -- existing Core-backed EN/TL catalogs
 semantic={intent="QUESTION", subject="WELLBEING", slots={}},
 target={npcId="..."}, orderHint=0,
 conditions={all={{provider="dialogue", field="topic", op="eq", value="wellbeing"}}},
 onDenied="hide" -- or "disable" (no hidden-fact disclosure)
}
```
Exact keys/API must be adapted to existing contracts after audit; schema is a design example, not evidence of existing implementation. No arbitrary Lua callbacks or user-authored executable code in candidate definitions. Providers are explicitly registered and read-only; unknown/malformed predicates fail closed.
## State, privacy, semantics
Separate (a) candidate discovery, (b) eligibility, (c) visibility, (d) ranking, (e) click-time server admission. Hide secret/disclosure-sensitive suggestions when ineligible; disabled may be used for obvious requirements but must not leak unknown facts, private traits, unlearned secrets or relationship numeric thresholds. A suggestion must not reveal hidden NPC orientation or backstory to the player through disabled labels/tooltips, logs, or tool payloads. Romance options use participant orientation/attraction compatibility where canonical data supports it, age/adult suitability when relevant, relationship conditions and consent at action time. Never assume that a trait such as gay alone proves compatibility or consent; unsupported dimensions must fail closed or use generic alternatives.
Server validates target, speaker, request revision/turn, flow membership, permissions, current conditions, anti-replay, and exact one-effect admission. Clicks are stale-safe and idempotent. Queued/admitted is not completed. Typed equivalent and button equivalent should converge in semantic/action result; buttons do not bypass policy. No generated content directly dispatches actions; existing DialogueInput/approved adapter owns the side effect.
## Localization/performance
Use registered EN/TL translation keys and typed args through existing PNC.Translation/Core manager; UI labels and displayed player utterances are separately localized while semantic IDs stay stable. Partial-input preview is debounced/bounded and never executes game effects; no semantic pipeline per frame or NPC tick. Cache by bounded turn/state revision, cap candidates/evaluations/trace output and default to 3–5 suggestions, preserving predictable selection. Persist only existing dialogue/state owners' required data, not button catalogs or per-turn copies in ModData.
## Harness
Extend existing Semantic Lab Tk studio, Lua worker, scenario projection, conversation inspector and CodeBuilder only as needed. Authoring uses existing typed CodeBlocks/InteractionSpec and approved generation paths; never ship scratch JSON as production. Audit must show provider facts provenance, candidate source, predicate outcomes with safe redaction, hidden/disabled reason codes, ranking, chosen button, frame, flow transition, response realization, server/action outcome. No new harness, interpreter, translation store or button-specific execution lane.

## Implemented authored-topic route — `what's up`

The reviewed dataset compiler maps the explicit `what's up` alias set to one canonical `CONVERSATION_TOPIC` frame with `categoryID = projecthoomans:whats_up` and `route = conversation_category`. The client semantic input adapter sends that frame to the existing conversation composer; it does not parse the visible utterance again.

After the existing category authority selects a block, the current native composer node is exposed as a read-only semantic projection. The same projection feeds the in-game context and the existing Lua worker/Semantic Lab. Each visible or disabled authored choice becomes a typed `conversation_choice` frame carrying category, block, node, and choice IDs. A choice click enters the existing `RequestChoice` and outcome handler; the suggestion layer never owns branch state or effects.

The projection is bounded for inspection and privacy, not truncated to five UI slots. The selected topic/branch group is presented through Core's scrollable choice list, while the inspector retains the bounded projection and predicate trace. Category preflight and click-time authority admission remain separate, and unknown/private/hostile conditions fail closed without exposing protected facts.

## Semantic-first production presentation

The player-facing Hoomans conversation surface is Core's existing native `choicesPart`. Hoomans projects the current production root node and authored flow/response-plan offers into typed, localized candidates, then adapts the selected group into that Core-owned list. Root candidates are grouped by topic, conversation action, conversation utility, or owned-companion action. The projection remains bounded at 24 candidates for inspection and privacy/performance; it is not a five-slot UI limit, and Core's native list scrolls when a selected group contains more rows.

Root candidate frames carry `origin = conversation_root`, the current root node ID, and a stable source choice ID. Category frames re-enter the existing category preflight/request path; root system, identity, and companion frames select the original production choice. The resolver compares the frame with the current production node before dispatch. Existing closures remain the only owners of conversation effects, responses, lifecycle transitions, and gameplay actions.

PsychopatzCore contributes the generic `choicePartVisible` seam and owns the native choice-list layout, scrolling, hover/tooltips, interaction gating, and session ordering. Hoomans opts into that one surface (`choicePartVisible = true`) and owns only the semantic projection and gameplay policy. There is no parallel Hoomans button-grid part. Each adapted row carries a typed frame and a closure that calls the existing `SubmitSemanticFrame`; it does not execute a gameplay effect or create a second parser/response path. Initial root rendering does not initialize semantic turn state; a router is created only when a turn or click requires it. This preserves authoritative `contextBefore` snapshots.

Core also provides the generic `choicePresentation` seam on `Session:setChoices()`. It runs after Core has normalized authored choices and before Core writes its native choice part, including queued-response completion (`finishPending()`), authored node entry, and conversation-spec refresh. Hoomans supplies the current semantic projection through that callback and returns `nil` when no valid semantic rows exist, preserving Core's authored fallback. The callback is presentation-only and guarded by Core; it cannot replace session state, click dispatch, or effect ownership. This closes the lifecycle race where a direct semantic projection was visible for one frame and then overwritten by the authored `pendingChoices` menu.

The worker mirrors the same production projection in HELLO/CAPABILITIES, SNAPSHOT, RESET, LANGUAGE, and semantic-click observations. Root refresh is read-only, preserves EN/TL translation-manager ownership, and clears on a finished conversation. Stale/duplicate receipts are checked before existing handlers are entered. Native SP/MP/server acceptance is not implied by this harness contract and remains a user-owned test gate.

## Inventory identity contract for semantic GIVE

Inventory query records may be compact: the stable inventory map key is authoritative even when the denormalized `item.id` field is absent. The selector therefore carries the map key through match, score, deterministic ordering, and the selected `itemID`. This is a read-only selection repair; lease/revision checks, server authority, and the existing transfer handler remain unchanged. A successful semantic preview or admission is not itself a transfer.
