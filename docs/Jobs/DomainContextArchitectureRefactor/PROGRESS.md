# Progress — Domain & Context Architecture Refactor

**Status:** IN PROGRESS — P0–P4 developer gates accepted; P5 Conversation/Semantics is active.

## Parent objective

Complete P0–P8 in `ROADMAP.md` and every developer gate in `ACCEPTANCE.md`.
A phase/chunk completion does not complete this parent goal. Continue automatically.

## Current repository and architecture

- Existing `main` only; planning baseline `15cadee70be11b790ce4c48bfb7bd51badd8233b`.
  Initially clean, origin fetched, ahead 7 / behind 0. No concurrent edits found.
- Accepted: P0 `4205a1d7`, P1 `24d61abc`, Inventory pilot `b4535421`,
  tooling-baseline evidence `19749cef`, ordered composition `55049e99`, first persistence slice `034766f9`, Health/Identity `fa5b2a2d`; remaining P4 schema/restoration `0f7f326e`, public conversation close `2ad53120`.
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
- Current seven probes: **33 files / 4,501 lines / 167,228 bytes**, -42,294 bytes
  versus P0. Persisted inventory: 7 → 4 files, same depth, -25,710 bytes; removed
  envelope/bootstrap context is explained in `RETRIEVAL.md` and caller-tested.
  Memory's supplementary owned import closure: 83,367 → 55,416 bytes.
- Health/Identity slice: `P4B_VALIDATION.json`, `P4B_MCP_TRACES.json`. Health
  body/compact modules remain separate; immutable identity codec stays cohesive.
  Method bodies match pre-change source; obsolete health paths removed, no shims.
  Health/stamina context: 43,166 → 17,694 bytes at the same four-file count.
  Identity: 21,594 → 14,144 bytes, one additional generic-helper file explained.
- Latest full isolated Lua: **982/982**, 4 workers, 7.99 seconds.
  Focused owning-domain/restart/binding matrix: **118/118**; diagnostic Python
  **22/22**; NPC tooling **6/6**.
- Changed-runtime installed PZ Kahlua: P2 **36/36**, P3 **54/54**, first P4 slice
  **34/34**, Health/Identity **11/11**, remaining schemas **19/19**; static Kahlua zero errors. Diff checks clean.
- Semantic-tooling evidence: original 194-module baseline had 124 pass,
  65 fail, 5 GUI timeouts. Current complete isolated run: 195 modules, 155 pass,
  40 fail, no timeouts, 786 tests. Focused inspector repairs (15 tests) bring
  the derived current state to 157 pass / 38 pre-existing failures; this is not
  claimed a second full run. `P5B_TOOLING_VALIDATION.json` preserves both facts.
  Fact traffic remains complete; dispatch assertions are explicit. GUI tests
  use a per-process XIM fallback after native backtrace diagnosis, not a skip.
- No native Project Zomboid launched; no Workshop publication.

- P4 completion: `P4C_VALIDATION.json`, `P4C_MCP_TRACES.json` and
  `PERSISTENCE_OWNERSHIP.md`. Social, progression, companion directives, carrier
  proof, traits and travel restoration use public owning contracts. Fourteen
  moved method bodies and carrier/trait conditions retain previous logic.
  Mixed private Primitives/RecordState providers and unused camp serializer
  removed; optional Core interfaces retained as explicit public adapters.
  Carrier-proof context: 4 files / 32,132 bytes → 2 / 6,658; native admission
  policy is a separate boundary, preserved by the binding/restart matrix.

- First P5 slice: `P5A_VALIDATION.json`. Public Lifecycle.Finish owns close
  delivery/cleanup; lifecycle entry directly binds callbacks. Start/heartbeat
  support remains separate; obsolete private factory/finish chain removed.
  Conversation close: 7 → 6 files, 3 → 2 handoffs; 981/981 Lua, 24/24 owning
  regressions, 3/3 installed Kahlua, zero new debt. P5 is not yet accepted.

- P5 public-subdomain/tooling slice: `SEMANTIC_SURFACES.md` and
  `P5B_MCP_TRACES.json`. 44 supported semantic entry paths; foreign implementation
  and Internal namespaces are guarded. Typed identity-result transport is owned
  by Networking at its existing path. Raw wire traffic and lifecycle facts stay
  observable separately from gameplay dispatch. Six changed tooling Lua files
  compile with installed Kahlua; owning diagnostic Python 22/22; focused semantic
  evidence 29 tests pass. P5C/D and its remaining failures are not accepted yet.

- Semantic-session ownership slice: `P5C_VALIDATION.json`. Public cold-load
  query/cleanup seam owns active view and semantic working fields. Conversation
  and identity-result presentation use that seam. Phase order and exact moved
  statements preserved. Owning cleanup context: 7,115 → 1,164 bytes at one file;
  full close context gains one justified file, remains 5,608 bytes below P0.
  Full Lua 982/982; focused 30/30; semantic/authority/translation Python 16/16;
  installed Kahlua 4/4, static zero errors, dependency guard zero new debt.

## Next mandatory chunk

**Continue P5D — Prove/invert remaining cycle direction and resolve fixtures.**

1. Use the established public subdomain map to review remaining Social/World/
   Identity and Conversation/Knowledge/UI dependency cycles with exact source
   and caller evidence; retain only separately justified composition relations.
2. Preserve useful catalogs, authority boundaries and independent test seams;
   consolidate artificial provider chains only where retrieval evidence warrants.
3. Migrate foreign implementation access and remove unjustified cross-domain
   cycles; preserve semantic IR, suggestions, social director, observatory,
   optional LLM and SP/MP authority. Consolidate only with retrieval evidence.
4. Individually repair or prove supersession of the 38 remaining pre-existing
   tooling failures (old flow/category/realization/lineage fixtures). Preserve
   behavior; never suppress lifecycle facts to satisfy dispatch assertions.
5. Validate focused/full suites, graph/dependency guards, installed Kahlua,
   retrieval probes and diff; update this current state and continue P6–P8.

## Remaining gates

P5–P8/final acceptance are mandatory, including the remaining semantic
Python failures. M12 body-binding native acceptance remains user-owned;
its identity/lease, loaded-envelope, restart and visual-authority contracts must
be preserved. Historical logs and root `AGENTS.md` remain unchanged.
