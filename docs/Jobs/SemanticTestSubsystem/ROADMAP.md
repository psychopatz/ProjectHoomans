# Roadmap — full developer-side objective

**Parent goal:** One reusable Semantic Test subsystem that runs declarative behavioural cases through actual production Lua, replaces duplicated declarative smoke scaffolding and fragmented historical runner formats, integrates into existing agent CLI and Semantic Lab Simulation/Observatory, preserves imperative contract tests, improves trace quality and reduces maintenance/context cost.

| Phase | Mandatory acceptance |
| --- | --- |
| P0 — Inventory/classify | Enumerate all semantic-related test entrypoints and fixture loaders (not only 146 pnc_semantic* tests); record case/assertion/runner/coverage map, old commands, baseline pass/fail/time; classify declarative/mixed/imperative/native; identify test gap and duplicate patterns. |
| P1 — Canonical core | Stable versioned fixture schema and validator, loader, controlled expansion, real-worker adapter, bounded observation paths, assertion operators, reset/isolation, deterministic results, CLI case/suite/tag filters and invalid-case negative tests. |
| P2 — Behaviour pilot | Migrate What's up?, wellbeing, identity/self-state collisions and EN/TL variants into fixtures; verify each against real production parser/flow/realization with old-vs-new same-source parity; preserve explicit negative controls. |
| P3 — Multi-turn and existing families | Migrate/reuse Observatory and C0A case families incl. interruption, lifecycle, suggestions, realization, context/relationship/storage deltas. Preserve valuable C0A characterization and observability outputs; delete duplicate mechanics only after all callers covered. |
| P4 — Broad safe migration | Convert remaining declarative and separable mixed tests in bounded batches; retain and normalize imperative Lua contract tests; prove missing/colliding tests, zero weakened gates, report what intentionally remains Lua. |
| P5 — Tooling integration | Reuse existing Semantic Lab Simulation/Observatory and agent CLI for browse/filter/run/failures/traces, with human-editable validated fixture flow, no new competing UI/test engine. |
| P6 — Cleanup and efficiency | Remove dead runners/duplicate fixture formats/replaced Lua smoke files once parity and ownership confirmed; enforce default declarative behavioural test policy; duplicate-case lint; benchmark test runtime, fixture size, context/retrieval cost and report regressions honestly. |
| P7 — End-to-end developer acceptance | Full applicable production Lua, Python, translation/CodeBuilder, focused GUI, Kahlua and real-worker evidence; clean Git diff; current-source revision provenance; documented user-owned native SP/MP handoff only if applicable. |

Each phase is a gate, **not** a stopping point. Continue autonomously P0 -> P7; stop only at full developer-side acceptance or a concrete technical/authorization conflict. Do not invent a fixed numeric test-deletion target: measured coverage/quality determines safe removals.
