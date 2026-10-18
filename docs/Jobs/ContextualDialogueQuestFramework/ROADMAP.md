# Roadmap — automatic all-supported semantic production flows

**Supersedes older 2026-10-18 ROADMAP phase-status table** for the expanded goal. Existing accomplished narrow-slice phases 0, 2A/2B/2C, 3A, 4A/4B/4C are **historically developer-accepted according to archived PROGRESS**, not invalidated; they do **not** meet the new bulk generation requirement. PR #4 branch audited at `f0b6e41b90b0`. No new generator runtime validation performed in this documentation change.

| Phase | Current status | Required outcome | Real developer acceptance |
| --- | --- | --- | --- |
| Historical baseline H | RECORDED, limited | Weather facts; existing command/task/gift adapter traces; one compiler-authored FOLLOW terminal flow; X11 source generation/reload | Retain prior evidence in `HISTORY_20261018.md`, do not repeat same CUA tests |
| **G0 — Generic action-flow schema and template foundation** | **CURRENT, NOT IMPLEMENTED** | Versioned action/permission/result nodes, generic template from registered metadata, capability coverage; generate ALL compatible simple commands | G0A: at least FOLLOW+STAY generated automatically from ONE template and loaded into production; actual authorized/denied result branches and replies, no duplicate legacy dispatch; unsupported rows explicit |
| G0B — Parameterized task workflows | FUTURE | Generic task/location/item templates populated from registered target/parameter metadata | WAIT_AT and an independently compatible second task where real descriptor supports it; safe unresolved-target and authority outcomes |
| G0C — Multi-stage transactional flows | FUTURE | Workflow-state generator from gift/consent/transfer service metadata | Generated GIFT offer/selection/consent/result flow; correct item/target; no duplicate transfer; actual worker trace |
| G1 — Automatic coverage + regeneration in Semantic Lab | FUTURE | Enumerate all registered semantics/flow candidates; Generate Missing, Regenerate Selected, coverage and conflict report, safe source/translation manifests | Every compatible capability has generated production flow; every incompatible has exact reason; incremental, deterministic rebuild, real worker and usable GUI |
| G2 — Language/context/social flow generation | FUTURE | Reviewed lexical patterns, response-only/gate templates, NPC personality, memory, relationship and time/weather facts | Real multi-turn context, participant isolation, EN/TL, known/unknown and negative semantics; no invented knowledge |
| G3 — Quest workflow generation | FUTURE | Consume registered server-owned quest/domain contract to generate quest offer, lock, accept/progress, refusal/completion dialogue | Actual authenticated quest event/reward lifecycle; idempotent, scoped SP/MP service; no fake quest mutation |
| G4 — End-to-end developer release handoff | FUTURE | Scale limits, collision/precision metrics, modular assets, full harness GUI/worker compile/restart, performance and residual tests | Correct coverage denominator, no unsafe commands or known relevant regressions, READY FOR USER LIVE TEST; native PZ SP/MP and Workshop exclusively user-owned |

## ONE Next Chunk policy

`PROGRESS.md` exclusively defines Next Chunk **G0A**. It must be implemented and tested as an *actual generic generator* and real Lua production-flow behavior, not only an audit, one cloned Follow JSON document, a UI count, or isolated Python graph tests. Once accepted, move to G0B; never convert hundreds of capabilities before a representative generic family proves correct. Existing manually authored flows continue working during staged migration.

## Gates and prioritization

Source correctness and no double-dispatch supersede visual polish. A full coverage inventory can classify gaps without guessing effects. Distinguish `eligible` vs `supported template` vs `generated+loaded` vs `runnable` vs `verified`. Don't conflate automatic generation of supported semantics with creation of arbitrary code, new game mechanics or LLM-level language understanding. Previous READY FOR USER LIVE TEST is scope-limited, not final status for the clarified goal.
