# Construction project contract

Construction, component reconstruction, facility upgrades, and reinforcement
are funded when their work order is created. The storage service atomically
reserves and commits the complete recipe before the order is visible to the
worker scheduler. A funded order owns its materials; worker assignment,
travel, live/abstract execution, pause/resume, save/load, and replacement
workers never acquire or consume that recipe again.

The persisted construction order is intentionally small. It keeps the
facility, progress, recipe revision, funding marker, and storage identity.
Worker claims, paths, stations, collection handles, blockers, and reservation
handles are runtime state. Load recovery drops those fields and returns an
unfinished non-paused project to `WAITING_FOR_WORKER`.

Cancelling an unfinished funded project is authoritative and idempotent. The
remaining work fraction is multiplied by the sandbox
`ConstructionCancellationRefundMultiplier` (default `1.0`), rounded down per
ingredient, and deposited through the storage transaction API using the work
order ID as the transaction key. A completion that has started cannot race a
successful cancellation.

Component deconstruction keeps its separate
`ComponentDeconstructionRefundPercent` rule because it refunds the component
being removed rather than unfinished project work.
