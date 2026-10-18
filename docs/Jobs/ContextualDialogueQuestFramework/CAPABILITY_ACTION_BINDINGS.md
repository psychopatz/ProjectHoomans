# Capability binding and generated-action orchestration contract

## Source-backed current runtime

Existing `PNC_SemanticCapabilityCatalog` discovers action names/descriptor bindings; `PNC_SemanticCommandAdapter` executes FOLLOW/STAY/GO HOME via approved `SendCompanionCommand`, `PNC_SemanticTaskAdapter` routes WAIT_AT/FETCH and other supported tasks to existing `RequestSemanticTask`, `PNC_SemanticDialogueInput_Gifts` owns OFFER/GIFT selection/consent/inventory-transfer. The engine/fact bus is **observation**, not a callable function catalog. Earlier accepted tests of these routes do not make them first-class generated action flows.

## Metadata published by owning gameplay service

A versioned *data descriptor*, not Lua callback or guessed function name:
- `capabilityId`, domain `owner`, `workflowKind` (simple_command / parameterized_task / multi_stage_transaction / response_only / quest_command), public trigger frames + registered language pattern references
- `dispatcherRoute` allowlisted to existing adapter / workflow, `commandID` or task workflow ID, `requiredArgs`/slot types, `targetScope`, `permissionIDs`, contextual preflight gate facts
- `resultClasses`, event/async correlation ID and failure types, responses from known EN/TL pools, descriptor version and source module
- `generatedFlowStatus` / missing fields / template eligibility and fingerprint.

For complex gift interactions, workflow owner supplies an explicit staged descriptor rather than pretending GIFT behaves like a simple command. The generator may propose metadata extensions but cannot invent game mechanics, consent rules or side effects.

## Required flow-level semantics

Flow response/control is selected by validated, versioned action-capable nodes or declared action-result transitions, without arbitrary Lua functions in authored source. The existing parser and policy decide recognized intent. **Exactly one side-effect owner:** existing DialogueInput Actions / approved adapter, not FlowKernel Preview and not an additional network call from the graph. Results (authorized rejection, admitted/queued, failed, completed) feed back into flow state and response selector. Request ID and speaker/addressee/quest/target bind each pending action. Queued ≠ completed. Unknown permission, unresolved target or unregistered capability → clarify/deny with zero unauthorized effects. Ensure mixed legacy routes remain safe and no double-trigger under both graph and old policy.

## Template acceptance progression

- **Simple command:** Follow + Stay from the SAME generic descriptor renderer, load both production flows, run through actual Lua parser/dispatcher; prove true flow response/result transitions, no fallback terminal-only pool, no duplicate command, denied and negated zero unintended execution.
- **Parameterized:** Stay vs Wait At remain distinct; Wait At's location/target is resolved or clarification, then use existing task adapter and admission results.
- **Multi-stage:** Gift OFFER/selection/consent/InventoryTransfer with actual authoritative result and no duplicate item transfer.
- **Future:** Contextual response-only and quest/knowledge actions use approved providers; no invented quest authority.

The action picker must distinguish `recognized`, `registered`, `eligible`, `dispatched`, `admitted`, `completed` from a capability "appearing in a list." Unsupported capabilities report why generation is unavailable. Do not modify domain implementation just to make a screenshot more interesting; focus on real generation and behavior.
