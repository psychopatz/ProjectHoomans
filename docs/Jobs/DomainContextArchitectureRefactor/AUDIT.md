# Audit — Domain & Context Architecture Refactor

**Audit date:** 2026-10-30  
**Repository:** `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`  
**Observed branch:** `main`  
**Observed HEAD:** `2c4bdc433df4f2f534842a1e117b0cfea1f8dfe8`  
**Observed worktree:** clean at audit time  
**Upstream state:** `main...origin/main [ahead 6]`

## Verdict

The existing monolith-decoupling work is valuable and should not be reversed. Codebase MCP makes semantically meaningful smaller modules especially useful because it can retrieve the implementation slice relevant to a change.

The next architectural problem is **reasoning locality**, not simply file size.

Project Hoomans now needs a domain-level boundary pass that preserves useful internal decomposition while reducing cross-domain implementation imports, dependency cycles, artificial provider handoffs, composition knowledge, duplicated responsibilities, and documentation context.

## Current source shape

Direct source inventory at the audited HEAD found:

| Metric | Observed value |
|---|---:|
| Lua files under current 42.20 runtime tree | 3,260 |
| Approx. Lua LOC excluding two giant DebugCatalog files | 472,146 |
| Median Lua file | ~120 lines |
| Lua files <= 80 lines | 1,050 |
| Lua files <= 40 lines | 507 |
| Parsed `require` calls in non-DebugCatalog Lua | 4,781 |
| Files ending `_Core.lua` | 122 |
| Shared Semantics files in top-level semantics directory | 176 |
| Client Semantics files in top-level semantics directory | 114 |

These values are descriptive, not defects by themselves.

The two very large animation debug catalogs are generated/data-like assets and must not drive production architecture decisions merely because of byte size.

## Composition evidence

Current source requires are concentrated in composition roots:

| File | Direct require count observed |
|---|---:|
| `server/PNC/Composition/PNC_ServerComposition.lua` | 125 |
| `client/PNC/Composition/PNC_ClientComposition.lua` | 118 |
| `shared/PNC/Composition/PNC_SharedComposition_Foundation.lua` | 76 |
| `...IdentitySocial.lua` | 67 |
| `...InventoryWorld.lua` | 44 |
| `...CombatRuntime.lua` | 42 |

Composition roots are expected to have high fan-out, but this evidence shows they currently know many implementation-level files. The target is for composition to know domain registration/entry seams rather than hundreds of provider details.

## Checked-in architecture analyzer snapshot

The repository's checked-in root architecture-audit snapshot currently reports:

- 3,315 production files;
- 414,602 production LOC scored;
- 97 analyzer-detected logical subsystems;
- 246 production findings;
- 33 dependency-cycle findings;
- 9 cross-subsystem coupling findings;
- production health 80.1/100.

The highest reported refactor pressure is:

- Conversation: 100;
- Persistence: 100;
- UI: 100;
- Semantics: 71.8;
- Composition: 68.2;
- Colony: 62.2.

This snapshot is triage evidence, not current acceptance proof. P0 must regenerate/freshen graph evidence before using finding IDs as implementation authority.

## Dependency-cycle evidence

The checked-in analyzer identifies cycles including forms of:

```text
Conversation -> Persistence -> Conversation
Conversation -> UI -> Conversation
Conversation -> UI -> Knowledge -> Persistence -> Conversation
Conversation -> UI -> WorldDiscovery -> Persistence -> Conversation
Colony -> Production -> Settlement -> Persistence -> Conversation -> UI -> Colony
```

These cycles are a higher-value target than mechanically splitting another large function. Cycles increase both runtime coupling and MCP reasoning expansion because there is no obvious domain boundary at which retrieval can stop.

## Existing refactor history

The historical `docs/architecture/PROJECT_HOOMANS_REFACTOR.md` is approximately 310 KB and over 4,300 lines. It records roughly 240 behavior-preserving refactor chunks. The prior monolith refactor document is also approximately 279 KB.

The historical effort successfully introduced many useful seams, but its dominant mechanical pattern often became:

```text
large module
  -> stable entry
  -> provider A
  -> provider B
  -> internal handoff table
  -> provider C
```

That pattern is not inherently wrong. It becomes a context problem only where the providers:

- always load together;
- have the same owner and reason to change;
- are not independently reusable/testable;
- communicate through artificial internal tables;
- must all be retrieved to understand one operation.

## Important correction to the refactor methodology

**Do not equate small files with fragmentation.**

With Codebase MCP, smaller semantically named modules can materially reduce token use and improve retrieval precision. Examples such as Commands, Queries, Mutations, Repository, Adapter, Presentation, or Diagnostics are useful when they represent real responsibilities.

The anti-pattern is not “many files.” The anti-pattern is **many files without independent architectural meaning**.

Likewise, a large function/module finding is a request to inspect responsibility density, not an automatic extraction order.

## Documentation/agent context

Root `AGENTS.md` is already in the desired lean state: it contains durable repository-wide policy and does not currently carry active goal history. This job must not add phase state or migration history to it.

Current goal truth belongs only under this job directory.

## Primary risks

1. **Behavioral churn disguised as cleanup.** This is an architecture migration; gameplay changes require separate evidence and scope.
2. **Micro-file inflation.** Splitting can improve MCP retrieval, but splitting only to lower line counts increases handoffs.
3. **Over-consolidation.** Merging useful independently retrievable modules would regress Codebase MCP locality.
4. **Compatibility immortality.** Transitional aliases/providers can become permanent if they lack explicit retirement criteria.
5. **Mass file moves.** Moving large directory trees before public seams are real creates Git churn without improving ownership.
6. **Stale analyzer optimization.** Old graph/finding IDs must not be treated as fresh after structural edits.
7. **Composition order regression.** Current PZ load order is behavioral and must be preserved until an equivalent domain registration path is proven.
8. **SP/MP authority regression.** Existing server/client/shared responsibilities and the active body-binding work must remain intact.

## Planning conclusion

The next refactor should measure and optimize **change-local context**:

> How many files, public surfaces, dependency hops and unrelated subsystems must Codebase MCP retrieve before an agent can safely understand and modify one behavior?

The roadmap therefore begins by making that measurable before broad code movement.
