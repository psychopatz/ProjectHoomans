# Audit — G8R7 Portability Closure

**Evidence:** CODE_VERIFIED, TEST_VERIFIED, GENERATED_OUTPUT_VERIFIED.

## Accepted baseline

Verified from the committed vector:
- 577 compact `psychopatz.psdl.v2` production families and zero verbose authoring families;
- production compiler calls `compile_portable_plan()` and PZ projection renders from it;
- handwritten profanity registrations are removed and generated patterns are present;
- real camp source uses the `hoomans.camp.establish` capability boundary;
- PZ owner/output package descriptors are external data;
- synthetic adopter uses normal compilation/ledger routing;
- canonical check clean with `desired=384`;
- G8R tests 5/5, lifecycle tests 3/3, naming audit zero violations;
- independent deletion of 378 generated files rebuilt byte-identically and remained clean on second apply.

## Remaining findings

### Backend dispatch is still PZ-specific

Generic production compilation calls `render_pz_backend_from_portable_plan()` directly. `combined_target_descriptor()` sets `backend = pz-lua` unconditionally. No backend registry/dispatcher was found.

### Current trace equivalence is projection-only

G8R5 executes `PortableReferenceVM`, then verifies selected IDs/actions against PZ-generated plan/behavior/beat projections. It does not execute a Lua/PZ semantic trace.

Existing ConvoEngine studio support already provides `simulate_convo_engine_family()` through the live Lua ConvoProbe.

### Lineage conflates authored and canonical schema

Representative compact records report `sourceSchema = psychopatz.convo-engine.v1` while authored files are `psychopatz.psdl.v2`.

### Closure docs disagree

Previous PROGRESS/HANDOFF claimed COMPLETE while ROADMAP/committed job state did not.

## Conclusion

Reopen only G8R7 for backend dispatch, executed runtime conformance, truthful lineage, and final committed documentation closure.
