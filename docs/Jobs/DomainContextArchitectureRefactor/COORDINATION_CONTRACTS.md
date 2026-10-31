# Tasking and Production coordination

Public entries are `server/PNC/Tasking/PNC_Tasking.lua` and
`server/PNC/Production/PNC_WorkService.lua`. Each retains one command table and
one canonical owner. Foreign callers use these tables, not `Internal`.

| Command | Existing owner behavior |
| --- | --- |
| `Tasking.Commands.ApplyMovementRecovery(snapshot, lease, record)` | Project PathService movement/recovery state into the provider's snapshot. Does not create a second movement watchdog or advance the native lane. |
| `WorkService.Commands.ReleaseClaim(order, reason, cancelInputs, cleanupOperation)` | Preserve cancellation/input return, claim/reservation release, previous-order restoration and corpse-carry handoff semantics. |
| `WorkService.Commands.MarkAssignmentDirty(order, cause)` | Existing worker-interest/dirty-event propagation for a work-order change. No extra scan is added. |
| `WorkService.Commands.SetLiveOrder(worker, order, target, phase)` | Existing work-specific order projection through OrderSystem. |

These public fields reference the existing functions directly. Recovery binds
after its providers and before TaskExecutors/NeedFacility load, so executor
captures retain the proven PZ initialization order. Authority guards, timeouts,
retry bounds, lease ownership and cancellation order remain unchanged.

`Tasking.Commands.MarkPuppetOperaResumed` is an optional integration hook.
No implementation was found in the current maintained Tasking source; its
guarded absence remains unchanged. The existing heartbeat fixture supplies a
public command to exercise the optional collaborator. This migration does not
invent resume policy or enable a previously unavailable feature.

MCP can discover each public entry and retrieve the named owner implementation.
Function-reference aliases are incompletely represented as call edges, so use
the small entry source and literal caller checks alongside traces. Proof and
validation: `P7C_COORDINATION_PROOF.json`; fixed probes: `P7C_RETRIEVAL.json`.

## Client transport delivery and lifecycle

Networking's public `PNC.Client` methods now include RegisterServerCommand,
ApplyNPCKnowledgeSnapshot and ApplyScavengeSnapshot. Adapters/PuppetOpera register
through the public handler seam; gift replies and SP scavenge results use public
snapshot delivery. These are the exact existing functions, including existing
validation, stale-revision rejection, payload shape and presentation notification.

PresenceSync invokes public PumpInitialStateRequests at the same point before
snapshot work. The composition root wires public PumpCombatReplicas and calls
public ResetStealthDiscovery/ResetZombiePursuitDirectives. It supplies the same
public IsWorldReady predicate used by bootstrap/world requests. No function
wrapper, scheduler, state copy or identity authority is added. Owner-internal
references remain; foreign Client.Internal access is guarded.

P7G proofs record the unchanged provider bodies, current graph limitations,
bootstrap ordering and developer validation. M12 identity, server visual
authority, client 250 ms maintenance and restart contracts remain unchanged.
