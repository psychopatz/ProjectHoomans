# Progress — Domain & Context Architecture Refactor

**Status:** IN PROGRESS — P0–P4 developer gates accepted; P5 Conversation/Semantics is next.

## Parent objective

Complete P0–P8 in `ROADMAP.md` and every developer gate in `ACCEPTANCE.md`.
A phase/chunk completion does not complete this parent goal. Continue automatically.

## Current repository and architecture

- Existing `main` only; planning baseline `15cadee70be11b790ce4c48bfb7bd51badd8233b`.
  Initially clean, origin fetched, ahead 7 / behind 0. No concurrent edits found.
- Accepted: P0 `4205a1d7`, P1 `24d61abc`, Inventory pilot `b4535421`,
  tooling-baseline evidence `19749cef`, ordered composition `55049e99`, first persistence slice `034766f9`, Health/Identity `fa5b2a2d`; remaining P4 schema/restoration slice validated against that revision.
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
- Health/Identity slice: `P4B_VALIDATION.json`, `P4B_MCP_TRACES.json`. Health
  body/compact modules remain separate; immutable identity codec stays cohesive.
  Method bodies match pre-change source; obsolete health paths removed, no shims.
  Health/stamina context: 43,166 → 17,694 bytes at the same four-file count.
  Identity: 21,594 → 14,144 bytes, one additional generic-helper file explained.
- Latest full isolated Lua: **981/981**, 4 workers, 10.63 seconds.
  Focused owning-domain/restart/binding matrix: **118/118**; diagnostic Python
  **22/22**; NPC tooling **6/6**.
- Changed-runtime installed PZ Kahlua: P2 **36/36**, P3 **54/54**, first P4 slice
  **34/34**, Health/Identity **11/11**, remaining schemas **19/19**; static Kahlua zero errors. Diff checks clean.
- Immutable P1 semantic-tooling baseline: 194 modules, 124 pass, 65 fail,
  5 GUI-related timeouts; 764 reported tests, 2 skips. In-process discovery
  aborted in Tk cleanup (exit 134). These pre-existing failures remain final
  gates, bounded in `P0_TOOLING_BASELINE.json`. P5 must preserve lifecycle fact
  transport and distinguish it from gameplay dispatch before repairing assertions.
- No native Project Zomboid launched; no Workshop publication.

- P4 completion: `P4C_VALIDATION.json`, `P4C_MCP_TRACES.json` and
  `PERSISTENCE_OWNERSHIP.md`. Social, progression, companion directives, carrier
  proof, traits and travel restoration use public owning contracts. Fourteen
  moved method bodies and carrier/trait conditions retain previous logic.
  Mixed private Primitives/RecordState providers and unused camp serializer
  removed; optional Core interfaces retained as explicit public adapters.
  Carrier-proof context: 4 files / 32,132 bytes → 2 / 6,658; native admission
  policy is a separate boundary, preserved by the binding/restart matrix.

## Next mandatory chunk

**Continue P5 — Conversation and Semantics domain capsules.**

1. Establish current graph/source ownership, public entry/callers, inbound and
   outbound dependencies, affected tests and fixed conversation probe evidence.
2. Confirm durable Lifecycle/Authority/Presentation and interpretation/policy/
   social/realization/diagnostics subdomains before changing architecture.
3. Migrate foreign implementation access and remove unjustified cross-domain
   cycles; preserve semantic IR, suggestions, social director, observatory,
   optional LLM and SP/MP authority. Consolidate only with retrieval evidence.
4. Repair/classify semantic-tooling baseline failures and GUI timeouts without
   suppressing lifecycle fact transport to satisfy gameplay-dispatch assertions.
5. Validate focused/full suites, graph/dependency guards, installed Kahlua,
   retrieval probes and diff; update this current state and continue P6–P8.

## Remaining gates

P5–P8/final acceptance are mandatory, including semantic
Python failures/timeouts. M12 body-binding native acceptance remains user-owned;
its identity/lease, loaded-envelope, restart and visual-authority contracts must
be preserved. Historical logs and root `AGENTS.md` remain unchanged.
