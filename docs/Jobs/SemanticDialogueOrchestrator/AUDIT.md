# Source audit — 2026-10-17

## Scope and revision
GitHub code inspection, **not a new runtime execution**. ProjectHoomans main `c96cadda1570f59810552f9d3fc55d5c957ba670`; existing implementation branch `feat/contextual-semantic-harness-phase0a` at `fd852d746241d7e2f61df1c349ff63754afbe5ed` when checked. Existing PRs #1/#2 were open/unmerged. PsychopatzCore main has the existing deterministic parser; verify its exact current SHA again before implementation. User-provided screenshot is game-observed evidence, but the specific underlying parser trace and network/relationship effect have **not** been independently replayed for this goal.

## Verified collision mechanisms
1. `SemanticCatalog/PNC_SemanticCatalog_Identity.lua` registers forms `im`, `i'm` and `i am` followed by `any_phrase` capturing 1–2 tokens as a person name. For example `im fine thanks` can be a plausible but invalid identity candidate if the more specific wellbeing rule does not cover it.
2. `SemanticCatalog/PNC_SemanticCatalog_ConversationPatterns.lua` already recognizes several self-wellbeing states and exact optional `thank you`, but not necessarily `thanks` in the reported utterance. A new ad-hoc phrase alone is not a durable collision solution.
3. PsychopatzCore `PsychopatzSemanticParser.Parse` selects one best grammar match; confidence is computed from matching details, not dialogue eligibility. Pattern priority orders the registry and influences ties but is not a contextual arbitration protocol.
4. `PNC_SemanticDialoguePolicy_IntentBranch.lua` routes an identity claim before a self-state report; classifier `isIdentityEvasion` treats a non-identity question/utterance as evasion if an identity question remains pending.
5. `PNC_SemanticDialogueInput_Requests.lua` prepares `identity_claim` from `socialContext.identityClaim`, and can prepare `identity_evasion` on non-identity input while pending. Server `PNC_PlayerKnowledgeCommands_Identity.lua` validates claims against authoritative player names and can apply relationship effects. Thus parser/policy errors have an effect-bearing path.
6. `PNC_SemanticDialogueContextState_Turns.lua` already tracks bounded turns, topics and `pendingIdentityExchange`; avoid introducing a second transcript. The present clearing/retirement behavior must be traced through the actual live input lifecycle.

## Verified foundation — preserve
- Existing normalized grammar concepts, authored patterns, version-1 IR, semantic confidence and route selection in PsychopatzCore.
- Existing Hoomans intent policy, situation projection, conditioned response catalog, reference resolution, approved command/identity/gameplay authority and server validation.
- Existing real-Lua worker in `tools/semantic_harness/`, production `DialogueInput.Submit`, trace/results and conversation scenario editor; previous contextual goal reports numerous real-worker tests, but those results are **ledger-derived**, not rerun by this audit.
- Existing optional PBrainZ integration, offline compiler and authored reply bundles, multi-speaker context requirements.

## Key unknowns for mandatory Phase 0
- Exact candidate/winning IR for full screenshot transcript in the **current** implementation branch, including typo/punctuation variants.
- Timing of `pendingIdentityExchange`, response-only NPC turns, request preparation, transport, server identity admission and mutation.
- Native SP vs Semantic Lab mocked network parity and whether recorded game trace corresponds exactly to inspected revisions.
- Whether a safe narrow containment rule can be implemented within current architecture without breaking valid names or existing social flows.

## Verdict
Prioritize a **reproducible, effect-aware identity safety correction**, then candidate arbitration and bounded hierarchical flows. Do not port Façade Jess, rewrite response catalogs, increase priorities to hide collisions, create a global new DSL, or mark JSON fixture/replay validity as behavioral success.
