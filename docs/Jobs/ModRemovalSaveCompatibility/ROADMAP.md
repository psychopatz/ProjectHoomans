# Roadmap — Mod Removal & Save Compatibility

**Parent completion boundary:** Explain and repair the reported 8-capacity failure if it is caused by supported mod code or persistent state, and establish removal-safe behavior with rigorous regression proof. Phase completion never ends the parent task while mandatory developer work remains.

## P0 — Save-safe reproduction and baseline

- Verify reference-save identity and game/build version; capture checksums and immutable snapshot of relevant evidence before experiments, outside the original save.
- Identify which localPlayers record is active and decode/inspect capacity, Strength, traits, equipment, debug/admin states using trusted engine serialization or read-only instrumentation.
- Compare: affected save with no mods; matched-attribute clean vanilla character; same affected save with relevant mods enabled (only on copies); fresh PNC-enabled save, then disabled; and optional reduced mod combinations.
- Measure real carrying behavior as well as displayed value. Record a pass/fail matrix, exact versions and loaded mod IDs.
- Gate: reproducible symptom or a documented diagnostic limitation; no unsupported claim of cause.

## P1 — Complete mutation/ownership trace

- Trace player stat/trait/weight/debug state and item/container mutations from creation, save, load, mod integrations and removal.
- Trace player vs NPC inventory code and Core actor/player-identity ownership; inspect PNC, psychopatzCore, DynamicTrading/DTCommon/DTHoomans/MarketSense only as implicated.
- Distinguish player ModData, global ModData and physical item persistence. Instrument APIs to identify writers without polling per frame.
- Review mod unload expectations and historical save schema changes only when implicated by evidence.
- Gate: assign cause to a concrete file/function/schema/event or explicitly prove an external/vanilla-only cause with contrasting experiments.

## P2 — Correct fix and recovery contract

- At the authoritative owner, remove or correct any verified mutation/leak or lifecycle ordering defect; prefer native vanilla calculations and canonical player state.
- A disabled mod cannot execute cleanup: enforce safe behavior at save/write boundaries or via supported vanilla state rather than relying on a disabled mod.
- If already-affected saves need repair, design an opt-in, idempotent, backup-verified recovery path with field-specific before/after report and rollback. No magic numerical reset or generic ModData purge.
- If the cause is external/vanilla-only, document that result and do not invent PNC code changes.
- Gate: minimal justified correction with no duplicate authority, compatibility shims or unrelated refactoring.

## P3 — Automated regression and safety

- Prefer existing production-Lua harness/test infrastructure and real relevant services; mock engine-only seams narrowly.
- Cover 8-value reproduction where feasible, correct default/matched-strength capacity, weak/strong traits, worn bags and nested inventory, several items, player death/respawn, multiple localPlayers entries, repeated reload, remove/reinstall, missing dependencies and stale namespaced data.
- Test unaffected saves, other mods and schema evolution. Ensure SP/MP server authority remains correct; ensure no extra per-tick work.
- Prove opt-in recovery is idempotent, leaves unrelated save data untouched, and fails closed on ambiguous player-record identification.
- Gate: focused tests plus relevant baseline tests and deterministic save lifecycle assertions passing. Synthetic tests alone do not prove native game behavior.

## P4 — Native acceptance and final handoff

- Prepare exact manual/agent-harness SP acceptance on a copied reference save; run native game only when expressly authorized by the user, otherwise deliver a minimal user-owned procedure.
- Confirm affected character capacity is correct for actual attributes, items are retained, no missing-mod crash occurs, re-enable produces no stale-state duplication, and independent unaffected saves remain unchanged.
- If MP applies, validate server-side state, reconnect, owner changes and mod-list mismatch protections.
- Gate: evidence-labeled results and user-live-test handoff if that final gate is outside execution authorization.

## Mandatory final acceptance

No premature goal completion after diagnosis, first fix, one smoke test or one passing simulation. If genuine cause is not attributable to PNC or participants, a clear external root-cause proof + appropriate safe remedy + relevant regression assurance completes developer ownership; do not create new code just to claim implementation.
