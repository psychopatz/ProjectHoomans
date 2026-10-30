# Progress — Domain & Context Architecture Refactor

**Status:** IN PROGRESS — P0–P3 accepted; P4 classification and first repository slice validated. P4 remains active.

## Parent objective

Complete P0–P8 in `ROADMAP.md` and every developer gate in `ACCEPTANCE.md`.
A phase/chunk completion does not complete this parent goal. Continue automatically.

## Current repository and architecture

- Existing `main` only; planning baseline `15cadee70be11b790ce4c48bfb7bd51badd8233b`.
  Initially clean, origin fetched, ahead 7 / behind 0. No concurrent edits found.
- Accepted: P0 `4205a1d7`, P1 `24d61abc`, Inventory pilot `b4535421`,
  tooling-baseline evidence `19749cef`, ordered composition `55049e99`.
- MCP project `project-hoomans`; explicitly refreshed against actual source.
  Statement-form IMPORTS and heuristic alias/builtin resolution need the
  documented literal-import/source fallback. Matching HEAD alone is insufficient.
- P0 runtime: 3,258 maintained executable Lua files, 2 generated runtime catalogs;
  282 common declarations/catalogs separately classified. P3 added 47 policy-free
  registrations without moving providers or changing their bodies.
- Current boundary/cycle manifestations: 82, zero new debt. P4 separates the
  schema-neutral storage mechanism from envelope coordination; Persistence is
  outside the three smaller owner SCCs. Existing three-file UI/debug import SCC
  remains. These counts are manifestations, not independent architectural cycles.
- Ratchet: 193 entries after P2 removed fifteen resolved endpoints from P1's 208.
  P3/P4 have added no debt endpoints; 111 entries in that ratchet now resolve
  (four in P3 and 107 further manifestations in the first P4 slice).

## Accepted evidence and validation

- P0: `P0_BASELINE.md`, `P0_ARCHITECTURE.json`, `RETRIEVAL.md` and fixed behavior
  probes. Original set: 37 files / 5,530 lines / 209,522 bytes.
- P1: `OWNERSHIP.md`, `DOMAIN_CONTRACTS.json`, dependency/context guards.
- P2: `INVENTORY_PILOT.md`, `P2_VALIDATION.json`. Public item-state/rollback and
  Equipment/Supply seams; obsolete transfer handler removed with command bodies
  preserved. Transfer: 5 → 4 files, 3 → 2 handoffs, -10,976 bytes.
- P3: `COMPOSITION_SEAMS.md`, `REGISTRATIONS.json`, `P3_VALIDATION.json`.
  Roots: 488 → 270 imports, 25,390 → 14,011 bytes; expanded ordering identical.
  Registration adds an assembly hop and a bounded domain-local startup surface;
  complete expanded source/file count is not claimed to shrink.
- P4 first slice: `PERSISTENCE_OWNERSHIP.md`, `P4A_VALIDATION.json`.
  Public ModData mechanism; identical Reset compatibility object/body semantics;
  Memory repository loads bounded schemas/catalogs; Inventory owns lazy snapshot
  interop. Body hints, journal/travel and save coordinator behavior preserved.
- Current seven probes: **33 files / 4,638 lines / 172,836 bytes**, -36,686 bytes
  versus P0. Persisted inventory: 7 → 4 files, same depth, -25,710 bytes; removed
  envelope/bootstrap context is explained in `RETRIEVAL.md` and caller-tested.
  Memory's supplementary owned import closure: 83,367 → 55,416 bytes.
- Latest full isolated Lua: **979/979**, 4 workers, 8.90 seconds.
  Focused persistence/restart/binding/knowledge: **42/42**; diagnostic Python
  **21/21**. NPC tooling P0 baseline: **6/6**.
- Changed-runtime installed PZ Kahlua: P2 **36/36**, P3 **54/54**, first P4 slice
  **34/34**; static Kahlua zero errors. Diff checks clean.
- Immutable P1 semantic-tooling baseline: 194 modules, 124 pass, 65 fail,
  5 GUI-related timeouts; 764 reported tests, 2 skips. In-process discovery
  aborted in Tk cleanup (exit 134). These pre-existing failures remain final
  gates, bounded in `P0_TOOLING_BASELINE.json`. P5 must preserve lifecycle fact
  transport and distinguish it from gameplay dispatch before repairing assertions.
- No native Project Zomboid launched; no Workshop publication.

## Next mandatory chunk

**Continue P4B/C — Remaining domain codec ownership.**

1. Use the established graph/source classification to move health and identity
   schema meaning behind owning repositories; review social/progression/command
   codecs and optional Core adapter namespaces without creating artificial files.
2. Preserve exact formats, bounds, lazy hydration, migration/reset policy,
   startup body hints, Follow travel reconciliation and domain Save ordering.
3. Remove superseded private imports/aliases where safe; classify retained
   compatibility paths. Avoid duplicate canonical state and service locators.
4. Validate owning focused suites, dependencies, installed Kahlua, probes and diff;
   only accept P4 after its complete roadmap gate is met, then continue P5.

## Remaining gates

Remaining P4 work and P5–P8/final acceptance are mandatory, including semantic
Python failures/timeouts. M12 body-binding native acceptance remains user-owned;
its identity/lease, loaded-envelope, restart and visual-authority contracts must
be preserved. Historical logs and root `AGENTS.md` remain unchanged.
