# Semantic Dialogue Orchestrator — architecture contract (proposal)

## Ownership and pipeline
- PsychopatzCore: normalization, grammar registry, matching, deterministic candidate interpretation, validated semantic IR, reusable *generic* typed-capture machinery if truly necessary.
- Project Hoomans: game-aware candidate eligibility, dialogue-flow registry, bounded session state, policy arbitration, reaction/response planning and existing service dispatch.
- MarketSense: item classifications; PBrainZ: optional realization/retrieval, never authority; Project Hoomans server: identity, relationships, inventory, tasks and network admission.

Proposed flow:

    input -> Core match candidates -> Hoomans candidate eligibility
         -> active-flow statechart + global safe interrupts
         -> existing dialogue policy and situational reaction selection
         -> existing response catalog -> translation key
         -> presentation / explicit authorized command (server validated)

Preserve old `Parser.Parse` public behavior for other callers. A new optional `ParseCandidates`/equivalent API, if needed, should be bounded, deterministic, inspectable and backwards compatible, with no per-frame parsing. **No new API name is considered implemented until reviewed.**

## Candidate eligibility (not simply another priority number)
Every candidate reports: pattern ID, grammar/IR, exact/fuzzy provenance, confidence, typed-slot extraction, currently eligible flow(s), rejection reasons and action-risk class. Rules:
- Explicit identities like `My name is Alex` may be understood outside an active identity flow. Ambiguous `I'm <phrase>` forms require a validated name interpretation and appropriate conversation context, not a generic unrestricted wildcard.
- A health/adjective/status phrase is not a name claim by default. Avoid naive dictionaries that reject real names merely because they resemble ordinary words; ambiguous forms must **clarify**, not mutate trust.
- Full grammar coverage and concrete typed slots matter. Fuzzy corrections cannot silently promote an ambiguous input to a gameplay action.
- Non-identity topic switches must not be automatically classified as deliberate identity evasion. Such evasion, if supported, needs explicit intentional behavior and a reviewed authoritative gate.
- Only a validated, accepted identity claim or explicit authorized evasion event may reach the server request adapter. Server independently verifies admission, actor and event parameters.

## Hierarchical conversational flow contract
Reusable lightweight registered flow (declarative Lua tables or existing compatible registry) contains:
- Stable flow ID/version, triggers, typed slots and initial node.
- Node transitions keyed by accepted *semantic frames* (intent, subject, slots), not raw string matching.
- Response plan IDs referring to the existing conditioned response catalog.
- Bounded state with active flow, current node, speaker/addressee, pending slot obligations, optional suspended flow stack and expiration policy.
- Explicit on-unrelated behavior: suspend, clarify, continue, cancel or ignore; NO default punishment or implicit task action.
- Pure `preview` that does not record turns, send transport, commit effects or consume obligations. Accepted/committed turns advance once.
- A response-only NPC turn must not masquerade as the player's identity answer.
- Deterministic priority tiers: safety/authority -> explicit active obligation -> high-confidence direct request -> safe global interruption -> fallback/clarify. Ties remain explainable and bounded.

## Composition and extensibility
A flow module owns triggers/state transitions/response-plan references; the existing response catalog owns context-eligible wording variants; the TranslationCatalogModularization job owns file-based localization bundles. A new flow should be registrable without adding a special-case `elseif` to the central policy. Existing modules are migrated incrementally, starting identity and wellbeing. Do not duplicate whole-response pools or native UI translation files.

Optional future response-plan structure: acts such as ACKNOWLEDGE, DISCLOSE, ASK_FOLLOWUP, RETURN_TO_TOPIC with context-constrained argument slots, followed by deterministic template realization. Keep grammar and localized sentence order safe; avoid naive random concatenation of arbitrary fragments.

## Performance and compatibility
- Work only on conversation events, with immutable bounded context snapshots; no scanning entire registries every NPC tick.
- Cache/static-index registered triggers at startup; cap candidate count and suspended depth, expire idle flow sessions.
- Preserve public IR version 1, network command schemas, response payloads, server leases/replay checks, relationship mutation ownership, SP/MP behavior and save compatibility unless a reviewed migration is strictly required.
- Avoid temporary directory creation under watched Build 42 `media/` while the game runs (repository `AGENTS.md`).
