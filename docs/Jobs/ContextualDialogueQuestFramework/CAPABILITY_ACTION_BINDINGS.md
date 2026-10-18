# Typed capability / action-binding contract

**Status:** DESIGN, not a claim that the current Flow Registry accepts these fields. Implement only via validated versioned schema and existing dispatcher/authority ownership.

## Existing production routes to preserve

| User meaning | Core IR / policy | Dispatch owner | True authority / result semantics |
| --- | --- | --- | --- |
| "Follow me" | REQUEST + FOLLOW → COMMAND_ACCEPTED when eligible | `PNC_SemanticDialogueInput_Actions` → `PNC_SemanticCommandAdapter` → `SendCompanionCommand("follow")` | Existing companion-command registry/owner validates and enqueues order; returned acceptance not automatically movement completed |
| "Wait here" / "Stop" | REQUEST + STAY/STOP | Command adapter `stay` | Current order, permission and receiver controls |
| "Wait at that location" | REQUEST + WAIT_AT plus valid destination | Task adapter → `RequestSemanticTask` | Server task service/handler validates location, leases, execution result |
| "Here's a bandage for you" | OFFER + GIFT; possible follow-up consent | Gift-specific input path, selection, inventory transfer | Existing inventory/gift authority and receipt; never a blind `GIFT()` function |
| "Give me..." / "Fetch..." | REQUEST + GIVE/FETCH | Task adapter / inventory resolution | Existing item classification, availability, authoritative inventory transaction |
| "Go home" | REQUEST + GO, destination HOME | Command adapter `return_home` | Existing companion command authority |

**Known trap:** `PNC_SemanticCapabilityCatalog.ListActions` merges policy registrations, adapter registrations, context constraints and Core pattern emissions. Its `recognized` boolean can mean **discovered**, not proven matched by real NLU. `dispatchable` can mean a registered transport exists, not that this user/NPC is authorized. Editor must present these dimensions separately.

## Proposed public capability descriptor (example, not runnable API)

```lua
{
    id = "pnc:companion.follow",
    owner = "PNC.CompanionCommands",
    meaning = { intent = "REQUEST", action = "FOLLOW" },
    route = "existing_companion_command", -- fixed allowlisted route
    commandID = "follow",                  -- registry-resolved, not arbitrary Lua
    arguments = { npcID = "actor_target", scope = "single_or_group" },
    requires = { "conversation_or_companion_authority", "resolved_target" },
    result = { "requested", "rejected", "queued", "accepted", "completed" },
}
```

For multi-stage gifts, descriptor instead binds an existing **workflow ID** with selected item/recipient/consent/transfer and correlated result. Action descriptors do not copy functions from the registry or serialize callbacks into drafts. Addons register a bounded, public descriptor next to their own handler; Semantics consumes that published contract.

## Versioned definition/flow reference

An interaction references a capability ID and explicitly maps flow conversation states to result classes. A concrete node schema must be separately versioned and validated by the *production* Flow Registry. Don't overload `triggers` to mean execute; do not execute from `FlowKernel.Preview/Commit` or route around `PNC_SemanticDialogueInput_Actions` permission gates. Prefer a **single side-effect-bearing decision/dispatch path**: parser → policy+eligible flow → existing approved dispatcher → actual result → response/follow-up. Flow-binding can constrain and annotate that path, never dispatch twice.

### Outcome states (must appear in harness)

- `recognized`: IR action and selected registered pattern. Does not execute.
- `eligible`: confidence, negation, conversation, world and relevant typed gate checks passed.
- `bound`: a real adapter/workflow/handler with compatible parameter schema exists.
- `dispatched`: exact request/command issued once (or safely not issued).
- `admitted`: authority returned acceptance / queued; not necessarily physical completion.
- `completed/failed`: correlated domain result where available. Explicitly mark `not_observable_in_headless_harness` if real native executor cannot be observed.

For unknown handler, bad target, stale request, unauthorized, negative command, low-confidence executable action or unresolved item: fail closed and explain. UI cannot claim accepted because a generic reply was spoken.

## First vertical implementation — FOLLOW (one autonomous chunk)

1. Audit current branch in local checkout. Confirm command catalog has `FOLLOW`, adapter resolves to `follow`, and worker can exercise `PNC_SemanticDialogueInput_Actions.DispatchAction` with its existing mocked transport.
2. Add minimal, typed capability binding **metadata/validated mapping** visible from Semantic Lab's action inspector. Distinguish parser trigger from executable route; use the existing policy/adapter path, not new arbitrary callbacks.
3. In the existing Simulation UI, select the interaction and run `Follow me`; render actual selected IR/pattern/flow or explicit no-flow, binding ID/handler, permission outcome, request/transport, selected NPC text and side effects. Trace the first denied case and negated case.
4. A validated authorable FOLLOW definition/draft must not accidentally dispatch from Preview, and **one committed request** produces at most one command. If no flow was taken, the inspector must show that truth instead of fabricating one.
5. Add real-Lua worker tests including one positive mock-authority dispatch, unauthorized request, negation, `Are you following me?` question, fuzzy ambiguity, and identical repeated preview with zero side effects. Preserve base identity/wellbeing/weather behavior.
6. Report exact fixture limitations (headless mocked authority ≠ native command completion) and next chunk. Do not add Stay/Wait At/Gift features until this thin slice proves the contract.

## Follow-on differentiated test paths

- **STAY vs WAIT_AT:** ensure nearby stay order and destination task are separately bound, reject absent coordinates/ambiguous target, return real server task admission results.
- **GIFT:** test offer → correct NPC target → selector → consent → real authenticated transfer/denial; multi-turn and partial completion, no double gifting.
- **Group and MP:** broadcast command targets and permission scopes aren't inferred from single-NPC authoring.
- **Quests:** only expose typed queries/commands once Quest domain has authoritative implementation, no fake progress from event observations.

## Acceptance rule

The capability UI must display what **can be parsed**, what **can be dispatched**, and what **actually happened**. Every handler call remains inside its existing domain. A screenshot of a new "Action" node, a catalog count or a success reply without transport/authority result is NOT acceptance.
