# Roadmap — G9 PSDL Package Ownership & Human-Readable Generated Layout

**Parent status:** COMPLETE.
**Active phase:** G9E (Closed).
**Completion boundary:** G9A–G9E accepted.

## G9A — self-contained adopter packages

Replace the current Core-owned federation package with real package descriptors at each semantic owner.

Expected ownership:
- PsychopatzCore package: compiler/stdlib/shared semantic primitives;
- ProjectHoomans package: Hoomans-owned semantic programs;
- DTCommon/DynamicTrading package: trading-owned semantic programs.

Requirements:
- each adopter source root has its own package descriptor and provenance/lock data as appropriate;
- Core package identity is not `ProjectHoomans`;
- Core package does not enumerate Hoomans/DT `externalSourceRoots` as adopter-specific knowledge;
- adopter packages import Core/shared packages through a generic package/import mechanism;
- package discovery remains descriptor/workspace driven and supports future unknown adopters;
- normal production compile/reconcile still produces equivalent semantic output.

**Gate:** an agent can open an adopter source root and find its complete package descriptor/import boundary there, while Core contains no adopter-specific source-root federation.

## G9B — semantic ownership audit and migration

Classify current non-dialogue semantic source by meaning, not historical location.

Ownership rule:

```text
reusable across unrelated games/mods → Core stdlib/shared package
meaningful only for one adopter/domain → adopter package
```

Audit at minimum:
- all 3 beats;
- all 30 behaviors;
- all realizations/recognition rules used by adopters;
- Core dialogue families;
- Hoomans horde/excursion/task/companion semantics;
- DynamicTrading-specific semantic logic.

Likely Hoomans-owned examples requiring proof/classification include:
- `behavior.scene_horde_*`;
- `behavior.scene_excursion_*`;
- `behavior.scene_task_work_*`.

Do not move generic constructs such as reusable social argument/reconciliation/deescalation merely because Hoomans currently consumes them.

Migration must preserve semantic IDs, imports, capability contracts, generated behavior and source lineage.

**Gate:** every semantic family has an explicit justified package owner, and adopter-specific programs no longer live in Core merely for compiler convenience.

## G9C — readable deterministic generated shard naming

Keep generated safety budgets:
- max generated shard bytes: currently 192 KiB;
- max records per shard: currently 32.

Do not solve readability by removing safety chunking.

Replace normal hash-first collision naming with deterministic semantic chunk names.

Current bad UX example:

```text
CompanionCommandsLifecycle.lua
CompanionCommandsLifecycle__3899a7d0.lua
CompanionCommandsLifecycle__7d8bcf74.lua
```

Preferred behavior:
- base directory/module reflects semantic family/domain;
- split chunks derive readable identity from contained semantic IDs or stable semantic ranges;
- use subdirectories when they improve clarity;
- long semantic names remain readable instead of being hashed solely because they exceed the current 32-character segment limit;
- hash suffix remains available only when a true unresolved collision/length constraint remains.

Naming must be deterministic from semantic content/lineage, independent of file enumeration order.

Adding/removing one family must not rename unrelated generated modules unnecessarily.

**Gate:** ordinary generated output contains no avoidable `__????????` names; any remaining hash suffix has an audit report explaining why a readable deterministic name was impossible.

## G9D — package/source navigation and audit UX

Make ownership and generation discoverable without repository archaeology.

Extend existing inspection tooling so an agent can locate a semantic ID and see:
- package/owner;
- authored source path;
- imported package dependencies;
- kind: dialogue/behavior/beat/recognition/realization;
- capability requirements;
- generated backend module(s);
- consumers/references when available.

Preferred CLI shape may be:

```text
psdl locate <semantic-id>
psdl get <semantic-id> --summary
psdl impact <semantic-id>
```

Do not create a duplicate index authority; derive from the canonical compiler/package model.

**Gate:** representative Hoomans/Core/DT semantic IDs are traceable source → package → portable plan → generated module with compact output.

## G9E — committed-vector migration/rebuild closure

After G9A–D:
1. run package/ownership/naming/navigation tests;
2. canonical reconcile check clean before apply;
3. run G8R7 portability tests and G8 production tests;
4. run lifecycle tests;
5. run naming/sharding determinism audit;
6. reconstruct final participant commit vector;
7. delete ledger-owned generated artifacts and rebuild;
8. verify second build no-op and final check clean;
9. verify no stale old hashed module references/artifacts remain;
10. reconcile active docs to COMPLETE;
11. commit participant repos first, ProjectHoomans/job docs last.

**Gate:** package ownership is self-explanatory, generated naming is readable/stable, and final committed vector remains fully deterministic.

## Non-goals

- do not remove shard size/record safety budgets;
- do not rename stable semantic IDs for aesthetics;
- do not move game mechanics into PSDL;
- do not build Unity/Godot backends;
- do not make Core know future adopters;
- do not hand-rename generated Lua.
