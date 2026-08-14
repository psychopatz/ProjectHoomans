# Tasking domain foundation

Tasking is an authority-only, runtime coordination domain. It owns candidate
collection, eligibility orchestration, semantic precedence, assignment, task
leases, safe preemption, live/abstract executor selection, a bounded dirty NPC
queue, and lightweight diagnostics.

Tasking does not own need values or thresholds, wounds, inventory mutation,
resource consumption, facility state, navigation, animation, research progress,
crafting progress, or outputs. Provider registries, candidate descriptors,
dirty indexes, leases, and diagnostics are runtime-only and are not persisted.

## Public contract

External domains register small providers through `PNC.Tasking.Commands` and
submit NPC IDs to the dirty queue. Providers expose candidates, validate their
own eligibility, acquire their domain dependencies, and receive start/cancel/
complete boundaries. `PNC.Tasking.Queries` returns copied lease and diagnostic
snapshots; external callers do not mutate Tasking indexes.

A Task Intent contains IDs, a kind, source domain/reference, precedence,
urgency, capability, interrupt policy, and revision. It never carries domain
objects, functions, paths, NPC objects, or facility objects.

## Precedence and preemption

Precedence order is:

1. `HARD_EMERGENCY`
2. `CRITICAL_NEED`
3. `FORCED_ORDER`
4. `NORMAL_NEED`
5. `HIGH_WORK`
6. `NORMAL_WORK`
7. `OPTIONAL`
8. `IDLE`

Bands compare before urgency. Same-band challengers need an urgency improvement
of at least 0.08, preventing small score changes from causing task thrashing.
`ATOMIC_COMMIT` and `COMPLETING` cannot be preempted; these phases must remain
short. Current production work is treated as `NORMAL_WORK` at this compatibility
boundary and is released through `WorkService.Commands.ReleaseWorker`, leaving
progress, reservations, and transaction policy owned by Work.

## First vertical slice: Sleep / Bed

Needs owns the actionable/critical fatigue thresholds and the `ApplyRest`
command. Its provider emits Sleep intents only for eligible companions at home.
Facilities locates and exclusively reserves the `sleep.bed` component through
its existing capability index and reservation service. Tasking owns the lease.

The existing live facility behavior still performs movement and animation, but
calls `IndividualNeeds.Commands.ApplyRest` for the outcome. The abstract executor
skips physical pathfinding/animation and calls the same Needs command with a
bounded elapsed-time quantum. Completion, cancellation, failure, component
removal, and reservation loss release or invalidate the lease.

The previous five-second full-registry automatic-sleep scan has been removed.
Fatigue level transitions dirty only the affected NPC; startup performs one
bounded queue fill, each pump reevaluates at most eight dirty NPCs, and active
executor work is capped at sixteen leases per pump. Facility lookup uses the
existing capability index.

## Prepared, not migrated

Research, crafting, disassembly, treatment, and physical hydration keep their
current implementations. Their future providers can describe station or water
capabilities without moving progress, transaction, effect, or output logic into
Tasking.
