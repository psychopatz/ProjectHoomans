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