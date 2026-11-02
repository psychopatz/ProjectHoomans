# Roadmap — Core Semantic & Relationship Foundation

**Status:** IN PROGRESS at planning/documentation stage.

The full P0-P7 roadmap is the developer completion boundary. After each accepted chunk, update PROGRESS and continue automatically to the next mandatory chunk.

## P0 — Cross-repository convergence audit and contracts

### P0A — Re-establish current repository truth

Before production edits:

- inspect branch/HEAD/status/upstream for Core, DynamicTrading and Hoomans;
- preserve unrelated dirty work, especially any current DynamicTrading conversation edit;
- identify current Core Social/Actors/Semantics/Conversation public APIs;
- map Hoomans relationship/social state fields and semantic subdomains;
- map Dynamic Trading standalone versus DTHoomans semantic entry points;
- identify all duplicate/shared relationship fields and all direct cross-mod semantic dependencies;
- capture focused test baselines.

Gate: a source-backed ownership/migration table exists and no production authority is moved on assumptions.

### P0B — Freeze public contracts

Define/test the smallest stable APIs for:

- Core relationship query/event/update/migration;
- namespaced relationship extensions;
- semantic pack registration/unregistration/diagnostics;
- capability-gated semantic action providers;
- relationship-aware conversation context;
- actor/provider binding identity.

Gate: contracts can be exercised without loading Project Hoomans.

## P1 — Make Core the canonical shared relationship authority

### P1A — Schema convergence

Reconcile Core Social with the common subset of Hoomans relationship state.

Promote only genuinely shared concepts. Keep Hoomans-only bond/romance/boundary/consequence policy outside Core.

### P1B — Safe Hoomans migration/adapter

Migrate existing Hoomans records non-destructively to canonical Core social state.

Hoomans RelationshipService becomes an adopter/facade over Core shared authority plus Hoomans extension behavior rather than a competing shared owner.

### P1C — Event and query convergence

Route applicable Hoomans and Dynamic Trading social events/queries through Core authority.

Gate: one actor/target pair has one shared approval/respect/familiarity/memory truth under Core, with Hoomans-specific extension behavior preserved.

## P2 — Complete the generic Core semantic/conversation foundation

Audit Hoomans semantic runtime pieces and move/promote only mechanism-level code missing from Core, such as reusable flow/pack/context/response infrastructure.

Requirements:

- no PNC/Hoomans imports from Core;
- preserve existing Core parser/IR/router APIs;
- semantic pack ownership and capability metadata are explicit;
- generic relationship context reads Core Social;
- no Hoomans action semantics move to Core;
- existing Hoomans semantic harness remains usable through adopter registration.

Gate: a small synthetic adopter can register a semantic pack and relationship-aware conversation without Hoomans.

## P3 — Standalone Dynamic Trading semantic/story pack

Implement rich Dynamic Trading conversation using Core directly.

Mandatory coverage:

- greeting/farewell;
- trader/guard identity/role context;
- trade and referral choices;
- settlement/trader whereabouts facts where available;
- caravan/journey/commercial story content;
- trader small talk/rumors;
- relationship-aware variants;
- radio conversation integration where applicable;
- trade action remains Dynamic Trading authority.

DTAbstract/Core mode must not require or initialize Project Hoomans.

Gate: Core + DTCommon + DTAbstract can run meaningful relationship-aware trader conversation and trade semantics with zero Hoomans semantic registry dependency.

## P4 — Convert Project Hoomans into an additive semantic/social adopter

Register Hoomans content/actions against Core public contracts.

Preserve:

- existing dialogue quality/content corpus;
- semantic flow behavior;
- Hoomans NPC commands/tasks/combat/cognition;
- server authority;
- social director/knowledge integrations;
- optional LLM integration;
- Semantic Lab observability.

Remove duplicate shared relationship authority and migrated deep coupling where Core public seams now exist.

Gate: Hoomans behavior remains equivalent while shared semantics/social state comes from Core.

## P5 — Remove cross-adopter coupling and enforce boundaries

Requirements:

- Dynamic Trading standalone paths do not import Project Hoomans/PNC semantic internals;
- DTHoomans is an optional physical/integration adapter only;
- Core imports neither adopter;
- capability tests prove Hoomans-only actions cannot leak into DT-only sessions;
- dependency/static checks guard the new boundaries;
- obsolete temporary compatibility paths are removed after callers migrate.

Gate: the dependency graph is Core <- adopters, with no hidden reverse authority.

## P6 — Hot-plug/save migration and removal matrix

Automate developer-side acceptance for at least:

1. Core + DT create/save/reload.
2. Add Hoomans to that save.
3. Verify same actor IDs, identity, base relationship and memories.
4. Exercise Hoomans extension/capabilities.
5. Remove Hoomans and reload.
6. Verify DT still works and shared state is unchanged.
7. Re-add Hoomans and verify extension recovery.
8. Start Core + Hoomans, then add DT.
9. Remove/re-add DT with Hoomans remaining healthy.
10. Repeated load/migration is idempotent.
11. Missing extension owner preserves opaque data.
12. Migration conflicts fail visibly without destructive reset.

Gate: no duplicate actors, no relationship forks, no repeated legacy imports, no erased inactive extension data.

## P7 — Full developer acceptance and handoff

Required:

- focused Core semantic/social/actor tests;
- Dynamic Trading standalone semantic/trading tests;
- Hoomans semantic/social regressions;
- cross-repo hot-plug matrix;
- changed Lua syntax/Kahlua/static checks;
- relevant broad suites;
- performance/bounded-work checks;
- `git diff --check`;
- coherent commits and documented repository revisions;
- no unauthorized Workshop publication/native game automation.

Final state is READY FOR USER LIVE TEST with a concise native SP/MP matrix.

## Completion rule

Do not mark complete because Core Social compiles, one semantic pack works, DT standalone opens, Hoomans migrates once, or one configuration passes.

Completion requires the complete shared-authority + standalone-DT + additive-Hoomans + hot-plug/removal outcome.
