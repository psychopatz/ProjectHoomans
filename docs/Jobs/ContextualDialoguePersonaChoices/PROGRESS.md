# Contextual Dialogue Persona & Choices — Current Progress

**Updated:** 2026-10-24  
**Parent status:** REOPENED — P10/P11/P11J runtime-parity foundation retained; P12 save-backed offline Semantic Lab is mandatory.  
**Current mandatory phase:** P12B — Core reader reuse + save catalog.
**Current local baseline audited:** ProjectHoomans `main` at `b1cb1846`; upstream is synchronized.
**Normal Semantic Lab runtime requirement:** Project Zomboid CLOSED/OFFLINE is supported and expected.  
**Source save mutation:** FORBIDDEN.  
**Optional live profiler:** disabled by default; read-only enrichment only.

## Accepted foundation to preserve

Current source already materially contains:

- production semantic Lua worker;
- production Talk-start projection shared with native conversation;
- contextual What's Up hub;
- semantic Flow / Hub / ConversationBlock runtime graphs;
- actor-centric Player/NPC/Relationship/World workbench;
- generated NPC personality and real trait catalogs;
- directed relationship standing and durable bond services;
- automatic friend promotion;
- proposal policy/service and harness diagnostic proposal operation;
- production recruitment/community authority in the worker;
- structured inventory + Advanced JSON;
- replay/Compare/activity logging;
- deterministic identity/backstory work;
- native Talk parity target catalog/matrix/GUI/CLI;
- current synthetic scenario/configure infrastructure.

Do not discard those systems.

## Architectural pivot

The remaining parity drift is now mostly caused by **state origin**.

Normal Semantic Lab still starts from synthetic scenario data for significant mod-owned state and engine-derived values.

Examples include:

- manually selected NPC profile;
- hand-authored actor relationship fields;
- adapter reconstruction of bond/friend promotion;
- needs;
- time;
- weather;
- world age;
- other scenario-defined runtime facts.

P12 changes the normal product architecture to:

```text
real saved mod state
+ explicit offline engine fixtures
+ optional read-only live profiler snapshot
        ↓
immutable imported source snapshot
        ↓
isolated mutable harness working world
        ↓
production Lua
```

Synthetic scenarios remain for CI/tests/malformed fixtures only.

## Save reader foundation

PsychopatzCore already owns the low-level read-only Build 42.20 parser:

```text
psychopatzCore/tools/profiler/moddata_reader.py
GlobalModDataReader
```

P12 must reuse it.

Do not build another `global_mod_data.bin` decoder.

Known first persisted roots include:

```text
PNC_Core_Global
PNC_npc<ID>
PNC_PlayerCharacters
```

and additional Core/Hoomans/DynamicTrading roots discovered by their state providers.

## Relationship parity finding

The current worker still reconstructs relationship policy in SemanticAdapters.

For example, the harness currently:

- resolves relationship state;
- reconstructs starting bond;
- performs its own 80/50/60 friend-promotion check;
- creates a harness social event;
- caches the result in `Runtime.relationships`.

This is now architectural debt.

P12 must instead import the real relationship record:

```text
npcRecord.social.relationships[playerEntityKey]
```

and run mutations through production relationship services in the isolated working world.

## Engine fixture rule

Project Zomboid does not need to be active.

Engine/transient values may remain editable fixtures when not available from supported offline readers, including:

- needs;
- time;
- weather;
- climate;
- current activity;
- position;
- nearby zombie density;
- other engine-only facts.

These must be explicitly marked:

```text
source = FIXTURE
```

rather than presented as saved truth.

## Optional live profiler rule

Live enrichment is optional.

The game side must be:

- disabled by default;
- enabled by external settings/config text only;
- restart-required;
- not exposed as a normal in-game toggle;
- strictly read-only.

Semantic Lab may consume a live snapshot and copy it into the harness working world.

Semantic Lab must never send gameplay mutations back to the running game.

## Historical P12A checklist (completed)

On the user's actual local checkout:

1. read root `AGENTS.md` and the ContextualDialoguePersonaChoices docs in documented order, including `SAVE_BACKED_OFFLINE_SEMANTIC_RUNTIME.md`;
2. inspect local ProjectHoomans/PsychopatzCore/DynamicTrading branches, HEADs, upstream/divergence, dirty/concurrent work; existing `main` only;
3. audit current scenario ownership:
   - Python `scenario.py`;
   - Lua worker Runtime/scenario;
   - configure/apply/replay paths;
   - workbench draft state;
   - relationship/runtime caches;
   - inventory/knowledge/provider state;
4. define one versioned source snapshot contract containing:
   - immutable imported state;
   - source metadata;
   - provenance;
   - raw provider payloads where needed;
5. define one mutable working-world contract copied from the source snapshot;
6. define provenance classes:
   - SAVE;
   - FIXTURE;
   - LIVE;
   - DERIVED;
   - HARNESS_MUTATION;
   - MISSING;
7. define override/patch semantics so a mutation does not destroy the imported source value;
8. define reset boundaries:
   - reset turn;
   - reset conversation;
   - reset selected actor mutations;
   - reset working world to imported snapshot;
   - reload source from disk;
9. keep current synthetic scenario loading as an explicit Developer/Test source so CI remains deterministic;
10. change normal product abstractions so future P12 save imports target the source/working-world contracts rather than adding more fields directly to the legacy flat scenario;
11. add tests proving:
   - worker mutations cannot alter the immutable source snapshot;
   - reset working world restores imported values;
   - provenance survives configure/mutation/reset;
   - fixture/test mode still works;
12. do NOT implement binary save browsing yet unless a minimal seam is required for the contract;
13. run focused Python/Lua/Tk checks and `git diff --check`;
14. update this ledger with exact evidence and continue automatically to P12B if green.

## Completed Chunk — P12A Snapshot/provenance architecture

Implemented on the existing ProjectHoomans `main` checkout:

- versioned Python `ImportedSourceSnapshot` and mutable `HarnessWorkingWorld` contracts;
- stable `SAVE`, `FIXTURE`, `LIVE`, `DERIVED`, `HARNESS_MUTATION`, and `MISSING` provenance values;
- immutable imported values retained separately from normalized working state;
- patch projections with imported/effective values, mutation provenance, and source baseline;
- Lua `IMPORT_SOURCE`, `RESET_TURN`, `RESET_CONVERSATION`, `RESET_ACTOR_MUTATIONS`, and `RESET_WORLD` boundaries;
- `CONFIG` retained as a working-world edit and `reload_source` reserved for explicit source rereads;
- synthetic scenarios retained as `FIXTURE` / `developer_test` source;
- no save browsing or second binary save decoder added in P12A.

Evidence:

- `tools/semantic_harness/tests/test_save_backed_snapshot_p12a.py`: 2 tests passed;
- source model rejects mutation of imported nested state, while working relationship patches report `HARNESS_MUTATION` over `SAVE`;
- production Lua inventory gift mutation changed only the working projection; the Python source snapshot remained equivalent after conversation reset and working-world reset;
- reset restored the normalized imported baseline without rereading disk;
- focused compatibility validation: 10 existing worker/inventory/runtime/session tests passed;
- `python3 -m py_compile`, `luac5.3 -p`, and `git diff --check` passed;
- the broader legacy `test_harness` module ran 24 tests but retains 2 identity-presentation assertion failures outside P12A.

## Current Exact Next Chunk — P12B

Reuse `psychopatzCore/tools/profiler/moddata_reader.py` and `GlobalModDataReader` for a read-only offline save catalog. Do not add another `global_mod_data.bin` decoder. Discover compatible saves and enumerate the required persisted roots, failing closed for unsupported, corrupt, missing-table, and invalid-schema inputs.

## P12A acceptance

Developer evidence must prove:

```text
SOURCE SNAPSHOT
immutable
        │ copy
        ▼
WORKING WORLD
mutable through production Lua
```

A relationship/recruitment/inventory test mutation against the working world must not alter the source snapshot object or serialized source representation.

Resetting the working world must reproduce the original imported values exactly.

## Ordered remaining P12 milestones

After P12A continue automatically:

- **P12B:** reuse Core reader + save catalog;
- **P12C:** real Player/NPC/relationship import;
- **P12D:** save-backed World Browser;
- **P12E:** dynamic mod-state providers;
- **P12F:** explicit offline engine fixture provider;
- **P12G:** optional read-only live profiler provider;
- **P12H:** production mutations in isolated world, including outstanding normal proposal-route completion;
- **P12I:** source-aware UI + full relationship parity;
- **P12J:** save-backed Talk/semantic/replay parity;
- **P12K:** final parity/safety matrix.

See `SAVE_BACKED_OFFLINE_SEMANTIC_RUNTIME.md`.

## P11J / P11M disposition

P11J Talk parity infrastructure is retained as completed foundation.

Do not replay old P11J2 instructions.

The outstanding P11M normal production proposal-action requirement remains mandatory, but is folded into **P12H** so it is proven against the same isolated save-backed runtime instead of a separate fixture-only path.

## Handoff condition

Do not report **READY FOR USER LIVE TEST** from fixture-only acceptance.

P12 is complete only when the normal Semantic Lab workflow can:

```text
load real saved world
 -> select real saved Player/NPC
 -> import real mod-owned state read-only
 -> run production semantic/conversation services offline
 -> mutate only isolated harness state
 -> reset safely
 -> prove source save unchanged
```

Optional profiler enrichment is not required for P12 completion unless its specific P12G gate is being tested.
