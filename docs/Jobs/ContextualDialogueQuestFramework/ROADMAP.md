# Roadmap — Semantic Studio (one integrated semantic development environment)

**Scope addition recorded 2026-10-19, based on remote `71162cb4f78cc4cd408a4a145486d5ebadc943c1`.** Earlier G0–G3 and C0–C6 developer slices are accepted according to their previous ledger, archived as `HISTORY_C0_C6_20261019.md`; native game acceptance remains user-owned. The new S0–S6 productization phase remains OPEN. **Only `PROGRESS.md` names the current Next Chunk.**

| Phase | Status | Product deliverable | Developer acceptance |
| --- | --- | --- | --- |
| Historical G/C | RECORDED ACCEPTED (narrow scope) | Generated production actions/quests, contextual Lua turns, reviewed seed compiler, X11 Studio callbacks, optional-provider controlled parity | Preserve old evidence, don't repeat C0–C6 or claim real-game verification |
| **S0A — Embed compiler** | **CURRENT / NOT STARTED** | Move `tools.semantic_compiler` implementation under `tools.semantic_harness.codebuilder`, route old callers through thin shims, move canonical source data only after import audit | Same CLI behavior, actual Lua and EN/TL/manifest files byte-identical, Python focused tests + real worker, no duplicated writer |
| S0B — One authoring/build service | PLANNED | Central typed `Load/Validate/PreviewDiff/GenerateApproved/ReloadWorker` and single output path/manifest authority shared by Tk/CLI | Preview effect-free, generated modules deterministic; no GUI-specific writers or second CLI implementation |
| S1 — In-app Dataset Library | PLANNED | Browse/edit/review all current lexical/dialogue seeds, provenance, accepted/rejected patterns, concept/flow links and EN/TL status inside Semantic Lab | Select existing dataset and modify reviewed utterance without manual JSON dialog, preview candidate and output diff |
| S2 — Typed semantic blocks | PLANNED | Versioned reusable language/fact/context/condition/dialogue/response/registered-action/memory/quest blocks and compositional subflows | Reuse identical block in 2 different compiled flows; typed validation, no copied effect handler |
| S3 — Unified graph + code view | PLANNED | Source-of-truth declarative spec, synchronized block graph/code editor, typed ports, layout persistence and auto-layout/search | Bidirectional supported grammar round-trip, safe unsupported handwritten Lua handling and undo/reload |
| S4 — Large dataset adapters | PLANNED | Actual licensed, versioned MASSIVE and SGD-style source ingestion/candidate mapping after S1/S2 are usable | Proven imports, provenance and false-command collision review; no raw corpus in runtime |
| S5 — End-to-end generation UX | PLANNED | Dataset/blocks→flows→canonical source→compiler→mod Lua/EN/TL/manifest→fresh worker trace in ONE app | No external source-file gymnastics; generated production behavior/authorization and deterministic rebuild |
| S6 — Productization acceptance | PLANNED | Workspace usability, performance, agent CLI parity, module reuse, error handling, EN/TL and packaging | Human/agent creates and debugs new contextual flow in Semantic Lab without manual source edits; no native PZ claims |

## Phase ordering

- Begin with **S0A**, not another C0–C6 worker-baseline or a broad UI rewrite. S0A must leave all current production Lua behavior unchanged. Keep compatibility shims only for real external callers and remove after a documented later migration gate.
- S0B eliminates duplicated orchestration; S1 makes existing 31-ish authored patterns browseable before adding major corpora; S2/S3 unlock true reusable composition; S4 grows imported datasets; S5 proves fully integrated generation; S6 closes usability.
- Existing `CONVERSATIONAL_INTELLIGENCE.md` and `DATASET_CONVERSATION_PIPELINE.md` remain standing design contracts for C phases, not instructions to recode historically accepted phases.
- Every accepted S phase must include actual product-surface evidence and worker/compile behavior, not a green unit test, a screenshot, or a file move alone.

## Boundaries

Use the existing Core parser, Hoomans runtime Lua registry and gameplay authority. One runtime interpreter; one compiler writer; one authoring definition. No full external corpora in Project Zomboid, no arbitrary eval callbacks, no unauthorized gameplay action, and no staging directories in a live watched media tree. Native PZ SP/MP and Workshop release remain user-owned.
