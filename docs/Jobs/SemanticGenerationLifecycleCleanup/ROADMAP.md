# Roadmap — Portable PSDL / ConvoEngine Portability Closure

**Parent status:** COMPLETE.
**Active phase:** G8R7D (Closed).
**Completion boundary:** G8R7A–G8R7D accepted.

## G8R7A — descriptor-selected backend dispatch

The portable plan is a real production seam, but generic compilation still directly calls `render_pz_backend_from_portable_plan()`, and the combined target descriptor currently forces `backend: "pz-lua"`.

Introduce one backend-dispatch authority:

```text
target descriptor.backend
→ backend registry / resolver
→ backend.render(portable_plan, target/package context)
```

Requirements:
- generic conversation compilation must not directly select the PZ renderer;
- `combined_target_descriptor()` derives and validates backend identity from active descriptors;
- incompatible mixed-backend owner sets fail closed;
- unknown backend IDs fail closed;
- current PZ generation stays behaviorally/byte stable unless a justified generated delta is required;
- adding a non-PZ test backend must not require editing generic compiler control flow.

A minimal `portable-json` or test backend is enough to prove dispatch. Do not build Unity/Godot here.

**Gate:** a descriptor-selected non-PZ backend is exercised through the normal compiler path with zero generic compiler routing edits.

## G8R7B — executed Reference VM ↔ Lua/PZ trace equivalence

Current G8R5 proves projection equivalence, not executed runtime equivalence.

Reuse the existing Lua ConvoProbe / ConvoEngine studio trace infrastructure rather than inventing another simulator.

For the same real production Portable Dialogue Plan semantics, compare Reference VM and Lua/PZ execution for:
- exact recognition;
- fuzzy recognition;
- fuzzy-recovered mutating confirmation;
- profanity recognition;
- beat entry/maintain/exit;
- behavior selection;
- camp action/result branch;
- deterministic realization selection where supported.

Normalize both sides to a small versioned semantic-trace contract covering, when applicable:
- recognition rule/dialogue ID;
- recognition mode/confidence class;
- confirmation requirement;
- selected beat/behavior/dialogue;
- action/result outcome;
- reply branch;
- realization/template identity.

**Gate:** both runtimes execute the same real scenario and normalized traces agree. Table membership/projection checks alone are insufficient.

## G8R7C — authored/canonical lineage clarity

Compact production source is `psychopatz.psdl.v2`, but normalized lineage currently reports `sourceSchema = psychopatz.convo-engine.v1`.

Preserve both concepts explicitly, preferably:

```text
authoringSchema = psychopatz.psdl.v2
canonicalSchema = psychopatz.convo-engine.v1
sourcePath = authored compact source path
```

Equivalent naming is acceptable if unambiguous.

Requirements:
- diagnostics still point to authored compact files;
- canonical IR schema/version stays explicit;
- no consumer treats canonical schema as authored schema;
- compatibility loading remains truthful for any legacy source.

**Gate:** representative dialogue/behavior/beat records expose truthful authored + canonical lineage with focused tests.

## G8R7D — final committed closure

After G8R7A–C:
1. run focused backend/trace/lineage tests;
2. reconstruct the three-repository committed vector;
3. canonical check must be clean before apply;
4. run production G8R tests and lifecycle tests;
5. run `audit-s6m8 --check-determinism`;
6. perform isolated generated-output deletion/rebuild and verify second-pass no-op;
7. reconcile ROADMAP/PROGRESS/HANDOFF to one COMPLETE state;
8. commit participant repos first and ProjectHoomans/job docs last;
9. rerun acceptance from the committed vector.

**Gate:** no remaining developer-side portability gate and all active docs agree on COMPLETE.

## Final acceptance

The goal is complete only when backend choice is descriptor-driven, Reference VM and executed Lua/PZ runtime agree on the semantic trace contract, lineage is truthful, and final committed-vector generation/rebuild/determinism gates pass.

No native Project Zomboid launch is required unless Lua ConvoProbe cannot exercise a required semantic behavior.
