# Phase 6 — native SP/MP and performance status

## Gate status

**OPEN — not accepted.** No production semantic behavior changed in this
checkpoint. A bounded non-native Semantic Lab performance measurement is now
recorded separately, but the required native evidence cannot be obtained from
the current workspace without a controlled Project Zomboid client and, for
multiplayer, a controlled authoritative server/client pair.

## Evidence boundary

- The native UI surface was unavailable in this session, so no controlled
  single-player scenario could be entered, observed, or replayed.
- No controlled multiplayer session was available. In particular, there is no
  evidence for server authority, action leases, late callbacks, group turns,
  or save/reload behavior.
- Existing console/process observations were not tied to a reviewed semantic
  scenario and are not promoted as native acceptance.
- [`PHASE6_SEMANTIC_PERFORMANCE.md`](PHASE6_SEMANTIC_PERFORMANCE.md) records a
  real-Lua-worker measurement of deterministic turn latency, serialized
  context size and provider-disabled/enabled behavior. It does not establish
  Project Zomboid engine dialogue overhead, native queue/tick cost or server
  authority.
- Live PBrainZ provider success remains **NOT TESTED**; Phase 5 only covered
  deterministic parity and provider rejection/fail-closed behavior.

## Required continuation

Phase 6 remains the sole next chunk. It needs a separately controllable native
SP/MP environment before its gate can be accepted:

1. exercise the accepted semantic slices in Build 42 SP;
2. exercise authoritative MP actions, groups, leases, late callbacks and
   save/reload boundaries;
3. capture bounded semantic performance measurements;
4. separately normalize one real provider-success response, if available.

Until that environment exists, the correct status is **native SP: NOT TESTED**
and **native MP: NOT TESTED**, rather than a Semantic Lab or replay result being
treated as native proof.
