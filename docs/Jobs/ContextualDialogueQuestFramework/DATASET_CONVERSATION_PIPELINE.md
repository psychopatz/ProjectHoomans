# Dataset-assisted contextual language Code Builder — proposed pipeline

**Status:** PLANNED. Datasets are **offline development-time sources for linguistic and dialogue-state candidate generation**, not a runtime LLM, executable capability authority, or megabyte-scale in-game corpus. Preserve the existing parser/compiler algorithms, reviewed WordNet/common-interaction/semantic-definition sources and automatic capability/flow generator **while relocating compiler implementation and canonical sources into `tools/semantic_harness/codebuilder/`** during the S0 migration. The old `tools/semantic_compiler` paths are historical entrypoints and may remain only as temporary delegated shims; no dual editable copies.

## Evidence and candidate sources

- **WordNet:** existing reviewed lexical input; limited allowed senses, safe synonyms/verb inflections; obey its source/notice terms. No indiscriminate synonym expansion.
- **MASSIVE:** intent/slot and paraphrase candidates, English and Tagalog; mapping required to actual Core IR. Dataset metadata/license and specific revision must be verified before import; not every generic assistant intent is a gameplay command.
- **Schema-Guided Dialogue (SGD):** intent/slot, multi-turn state and clarification/correction examples, primarily for **training the compiler's conceptual mappings and test fixtures**, not directly importing NPC lines. Before redistribution or packaging, review dataset's share-alike attribution/license conditions and derived-output status.
- **Out-of-scope/adversarial samples** (e.g., CLINC/OOS after license review): recognition rejection and ambiguity tests; never automatically map unrelated service intents to gameplay primitives.
- **Reviewed Hoomans authored examples:** survival/social/medical/gift/quest language with vetted expected referents, facts and accepted/denied outcomes; source of in-game text and translated EN/TL output unless reuse license explicitly permits another source.

Dataset names above are **planned candidates**, not an assertion that corpus downloads, adapters or redistribution clearance already exist.

## Source provenance and safety ledger

For every external source record sourceName, version/revision/URL/checksum, source language, license and attribution, allowed use (analysis / training/evaluation / redistribution), transformation, derivation, review decision, semantic target, negative examples and collision score. License terms are checked by a documented human/owner decision before distributed files can include derived content. When in doubt import evaluation metadata only and author new Project Hoomans text.

Keep raw corpora in an explicit untracked or external cache **outside `Contents/mods/**/media`** and never ship it implicitly. No runtime network call/embedding model. The generated Lua includes only approved compact semantic rules, fact/slot conditions and Hoomans-authored response/localization assets.

## Integration into existing Code Builder

```text
Licensed dataset snapshot
 -> source-specific read-only import adapter
 -> normalize / dedupe / redact sensitive source metadata
 -> candidate intent, dialogue act, slot, follow-up and positive/negative examples
 -> map to existing Core IR / flow / registered fact & capability
 -> collision, ambiguity, authority and license validator
 -> reviewed canonical semantic authoring spec (one source of truth)
 -> existing tools/semantic_compiler/build.py
 -> modular Lua patterns + contextual flow/agenda rules + response pools + EN/TL + manifests
 -> new production Lua worker and decision trace
 -> report precision, abstentions, false execution and regression delta
```

The adapter should first convert a **bounded fixed sample** and produce an *offline review report*, not modify the mod. A candidate mapping that lacks a registered intent/slot/flow capability remains `unmapped` with reason. Unclear explicit "yes"/"do it" never becomes an executable order without an eligible pending request and server permission.

## Incremental rollout

- D0 source/license/manifest baseline and 25–100 selected multi-turn evaluation examples; no dataset download in native game.
- D1 one small, reproducible MASSIVE intent/slot normalization adapter; reviewed positive+negative examples and EN/TL mismatch report, no auto-approval.
- D2 one small SGD-like dialogue-act/state adapter and missing-slot/correction/follow-up test fixture; source records remain external.
- D3 map **reviewed** examples to canonical context-frame / dialogue-act definitions and existing Core IR without modifying production gameplay code.
- D4 expose dataset candidate review/approve/reject, provenance, collisions and coverage in existing Semantic Lab; run compiler diff and fresh Lua worker before marking produced artifact accepted.
- D5 grow coverage only where measured errors justify it; regression matrix and runtime/performance budgets limit expansion.

## Quality bar

Measure recognition precision and recall for scoped tests, false executable dispatch rate (target zero on adversarial negative set), wrong referent rate, clarification/abstention, unknown-fact fabrication, EN/TL parity and incremental Lua size/startup cost. Preserve provenance from selected pattern to reviewed dataset candidate. Avoid "millions of examples loaded" and "NLP accuracy 100%" claims. Data volume is not a quality metric.


## Semantic Studio ownership supersession (2026-10-19)

Implementation entry point for future corpus adapters and review is **`tools/semantic_harness/datasets/`**; the existing CodeBuilder lives **`tools/semantic_harness/codebuilder/`** after S0. The only top-level product entry point is Semantic Lab GUI/CLI; do not construct a new dataset application or an independent compiler runner. The reviewed canonical authoring definition is shared by dataset view, graph, code and compiler. S0A must preserve current behavior byte-for-byte before S4 actual corpus ingestion.
