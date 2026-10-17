# Flow registration and arbitration design — proposed API only

This chapter defines **desired behaviors**, not executable Lua yet. Reconcile with the existing PNC context, policy, identity, response catalog and Core parser before naming actual public APIs.

## Flow module shape (illustrative)
```lua
return {
    id = "wellbeing",
    version = 1,
    triggers = { {intent = "QUESTION", subject = "WELLBEING"} },
    initial = "disclose_state",
    nodes = {
        disclose_state = {
            reaction = "DISCLOSE_WELLBEING",
            responsePool = "semantic.question.wellbeing",
            next = "await_player_status",
        },
        await_player_status = {
            accepts = { {intent = "INFORM", subject = "WELLBEING"} },
            onMatch = "acknowledge_and_finish",
            onUnrelated = "suspend",
        },
    },
}
```

This flow **does not** execute game actions or know translation paths. Its references resolve through existing response and translation registries.

## Minimal contract
- **Registry:** stable unique IDs, bounded rule count, explicit trigger frames, compile-time validation for unsupported IDs, missing nodes, duplicate transitions, unreachable states, slot schemas and conflicting owners.
- **Candidates:** optional backwards-compatible Core multi-candidate inspection (or existing diagnostics extended) with provenance/confidence, exact/fuzzy distinction, typed captures, clear negative/positive eligibility and deterministic limits; maintain existing `Parse` behavior for other consumers.
- **Arbitration:** hard authority/confidence guard -> active qualified obligation -> explicit safe topic switch/interrupt -> eligible global candidate -> clarification/fallback. A context bonus cannot make an invalid identity capture valid. Ties produce deterministic explanation or safe clarification, not a mutating guess.
- **State:** reuse `PNC_SemanticDialogueContextState` and Core DialogueState rather than another ModData transcript; bounded `flowId`, `nodeId`, speaker/addressee, typed slots, pending obligations and small suspend stack with expiration/retirement. Cross-speaker and group state isolation required.
- **Lifecycle:** PREVIEW returns candidates, reasons, selected flow/node and potential reply but **no message queue, network transport, context advance or relationship change**. Submit/accepted commits once, through current authoritative command and response lifecycle.
- **Response:** the flow emits existing response-catalog pool/variant IDs or a typed dialogue-act plan. The catalog selects contextual wording; translation maps a stable key to localized text; optional PBrainZ may rephrase but cannot decide authority.
- **Interruption semantics:** the committed `im fine thanks`/name fix is the minimum; general `REFUSE` intent should be scoped to which active question is refused, not automatically a standing identity refusal if multiple flows coexist.

## Minimum pilot
1. Identity pending; player asks `are you okay`; wellbeing flow takes turn, identity suspends.
2. NPC answers and asks after player; player says `im fine thanks`; wellbeing accepted without identity/evasion request.
3. Player later says `My name is Patrick`; qualified identity claim validated by existing server service.
4. Preview twice, submit once; one transcript step and at most one authorized outcome.
5. A named second NPC must not inherit the first NPC's pending identity or status.
6. English and Tagalog keep stable response IDs and correct placeholders.

Do not design a general mission scripting DSL, exhaustive English grammar or whole-drama manager from this pilot.
