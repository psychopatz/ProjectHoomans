# Roadmap — Semantic Generation Lifecycle Cleanup

**Parent status:** REOPENED — G0–G6 accepted; G7 corrective structural ownership refactor active.
**Completion boundary:** G0–G7 accepted.
**Parent objective:** eliminate confirmed semantic generation leftovers and make future cleanup automatic, safe, closed-set and recipe-driven.

A phase/chunk completing is not completion of the parent goal. G0–G6 are accepted groundwork, not the current completion boundary. Continue through G7 unless a genuine blocker or explicit user-owned live gate remains.

## G0 — Baseline inventory and ownership classification

**Status:** ACCEPTED (`CODE_VERIFIED`, `GENERATED_OUTPUT_VERIFIED`).

Re-audit current exact workspaces for ProjectHoomans, PsychopatzCore and DynamicTrading/DTCommon.

Build a machine-readable inventory of:
- generated Lua roots/files;
- generated conversation translation files;
- mixed authored/generated UI catalogs;
- Conversation/Text outputs;
- manifests/registries;
- lexicon generated outputs relevant to this lifecycle;
- historical/obsolete output roots and known legacy paths.

Classify each surface as:
- fully CodeBuilder-owned;
- mixed authored/generated;
- authored/preserved;
- ambiguous;
- confirmed retired.

Do not delete anything in G0.

**Gate:** every candidate cleanup surface has explicit owner, policy and evidence; ambiguous paths are isolated rather than guessed.

## G1 — Generation recipe and desired-artifact ledger

**Status:** ACCEPTED (`CODE_VERIFIED`, `TEST_VERIFIED`).

Add the compact CodeBuilder generation recipe in PsychopatzCore and a validated recipe schema.

Refactor generation planning so current compilers/renderers can produce one desired artifact ledger before filesystem mutation.

The ledger must cover all enabled owners and artifact classes required by this job.

**Gate:** recipe + ledger can describe a current generation with no runtime writes, and unknown owners/policies fail closed.

## G2 — Check-mode reconciler

**Status:** ACCEPTED (`CODE_VERIFIED`, `TEST_VERIFIED`).

Implement the canonical reconciliation entrypoint in dry/check mode.

It must report:
- desired/current;
- missing;
- content drift;
- stale proven-owned artifacts;
- retired paths that reappeared;
- ambiguous/unowned artifacts;
- mixed-catalog stale generated keys;
- preserved authored neighbors.

No writes are allowed in check mode.

**Gate:** fixture tests demonstrate accurate detection across Lua, ordinary translation, Text translation and mixed UI catalog cases.

## G3 — Apply-mode safe cleanup and mixed-key ownership

**Status:** ACCEPTED (`CODE_VERIFIED`, `TEST_VERIFIED`).

Implement apply mode using the validated desired ledger.

Requirements:
- validate complete plan before mutation;
- prune only proven CodeBuilder-owned stale files/keys;
- preserve authored/mixed content;
- rewrite desired artifacts canonically;
- run a post-write closure check;
- fail if closure is not exact.

Introduce generated-key ownership for mixed UI catalogs so removed generated keys disappear while package-authored keys survive.

Unify or delegate existing `Conversation/Text` desired-set cleanup through the same lifecycle model rather than maintaining contradictory semantics.

**Gate:** generate A+B → remove B source → apply → B is absent; authored neighboring data remains byte-stable where not regenerated.

## G4 — Programmatic legacy retirement and repository cleanup

**Status:** ACCEPTED (`CODE_VERIFIED`, `TEST_VERIFIED`, `GENERATED_OUTPUT_VERIFIED`).

Using G0 evidence, encode confirmed obsolete outputs as recipe retirements/tombstones.

Run the reconciler against isolated/output-root fixtures first, then against the real participant repositories while preserving unrelated dirty work.

Remove all confirmed semantic generation leftovers through the reconciler, not ad-hoc shell deletion.

Do not delete active hash-sharded modules referenced by the current registry.

**Gate:** current repositories contain no confirmed retired artifacts; `--check` reports zero stale/retired/ambiguous owned output after apply.

## G5 — Regression and determinism closure

**Status:** ACCEPTED (`CODE_VERIFIED`, `TEST_VERIFIED`, `GENERATED_OUTPUT_VERIFIED`).

Add permanent regression coverage for:
- source deletion removes obsolete generated file;
- source rename retires old path;
- owner migration Hoomans → Core removes former Hoomans output;
- owner migration to DTCommon routes and cleans correctly;
- mixed UI generated-key deletion preserves authored keys;
- obsolete translation domain file is pruned;
- Conversation/Text retains closed-set behavior;
- retired path reintroduction fails check;
- unknown/unowned file is never automatically deleted;
- two consecutive generation/apply passes are byte-identical and produce zero diff.

Run affected Python tests, full CodeBuilder generation tests and relevant repository test suites.

**Gate:** all lifecycle regressions pass and a second clean reconciliation is a no-op.

## G6 — Agent workflow and documentation acceptance

**Status:** ACCEPTED (`CODE_VERIFIED`, `TEST_VERIFIED`, `GENERATED_OUTPUT_VERIFIED`).

Finalize the small root `AGENTS.md` semantic-generation rule.

Ensure the canonical recipe/check/apply invocation is discoverable from the recipe/help output itself.

Update existing semantic generator documentation only where necessary to remove contradictory manual-cleanup guidance.

Prove an agent can answer:
- which source to edit;
- which command checks generated state;
- which command applies safe cleanup;
- why a candidate was deleted/preserved;
without reading the full generated tree.

**Gate:** documentation and CLI agree; no active instruction tells agents to manually patch/delete generated semantic runtime artifacts.

## G7 — Structural ownership refactor and recipe compaction

**Status:** ACTIVE / NOT YET ACCEPTED.

Normative design: `G7_STRUCTURAL_OWNERSHIP_REFACTOR.md`.

The post-G6 audit found that the reconciler is dynamically correct for generated Lua and `Conversation/Text`, but the steady-state recipe still carries migration-era exception inventory: per-file preserve lists, a large historical retirement list, and mixed-catalog ownership that is not universally self-sufficient under the advertised default CLI.

G7 must finish the migration without reopening accepted ConvoEngine semantic naming/sharding contracts.

### G7A — classify current preserved surfaces by real purpose

Audit every currently preserved translation/catalog and the hand-written Lua neighbors. Classify each as:
- hand-written engine/adaptor code;
- canonical CodeBuilder semantic source/output candidate;
- ordinary application/tooling translation;
- obsolete.

Use callers and canonical source lineage. Do not decide from path/name alone. `Flows.json` is a proven example where runtime text duplicates wording already present in canonical `companion_flows/follow.json`; use that as a regression case, not as a one-off deletion rule.

**Gate:** every preserve exception has a target ownership class and migration action; no deletions yet.

### G7B — migrate semantic/dialogue wording to canonical families

Move first-party dialogue/semantic wording out of hand-authored runtime translation catalogs and into the owning ConvoEngine families using the accepted CodeBuilder authoring/migration path.

Preserve accepted naming/sharding rules:
- one coherent semantic family/module per source file;
- lowercase semantic `snake_case.json` source names;
- concise semantic canonical IDs;
- stable numeric realization keys remain wording handles, not semantic IDs;
- named reply outcomes remain semantic outcomes;
- no `Legacy`, `Compat`, `Old`, `V1`, `Migrated`, `PartNN`, or phrase-per-file sharding;
- deterministic collision-safe generated chunking may retain active hash-suffixed shards;
- reuse `catalog_naming.py`; never create a second naming algorithm.

Ordinary application/tooling translations must move/remain outside CodeBuilder generated ownership rather than being listed forever as preserves.

**Gate:** no migrated dialogue family depends on a hand-authored runtime wording catalog as its canonical text authority.

### G7C — compact structural recipe and remove migration inventories

Refactor `generation_recipe.json` so steady-state entries describe structural surfaces/policies, not historical filenames.

Requirements:
- remove growing per-file preserve inventories;
- remove the large one-time historical retirement file list after caller/source-zero proof;
- keep only compact structural tombstones when they prevent a real root-level regression;
- do not list active hash shards or current generated files/keys;
- dynamically derive the desired artifact set from canonical source.

Prefer structurally generated-owned text (`Conversation/Text/convo/...`) and ordinary authored assets outside that surface over mixed generated/authored catalogs. Mixed-key ownership is transition/compatibility only.

**Gate:** the recipe remains small when new families/assets are added; adding/removing normal semantic content requires no recipe edit.

### G7D — dynamic future-family and canonical-CLI proof

Add a synthetic future family F:
1. create it through canonical source;
2. generate arbitrary Lua/text outputs;
3. remove F from canonical source;
4. do **not** edit the recipe, add a retirement, add a preserve entry, or list its output paths/keys;
5. run ordinary reconcile;
6. prove every F-owned generated artifact disappears while ordinary authored code/assets remain.

Also execute the recipe/help-advertised canonical `--check` and `--apply` commands exactly as documented from their documented working directory. String-presence tests are insufficient.

**Gate:** future-family cleanup is fully dynamic and the canonical CLI is truthful in the real multi-repository workspace.

### G7E — naming/sharding regression closure

Run ConvoEngine naming/layout/modularity audits and affected generation/runtime tests to prove the structural cleanup did not regress accepted semantics.

Required invariants include:
- no migration-history canonical names;
- no `PartNN`/phrase-per-file source fragmentation;
- one coherent semantic family per source module;
- deterministic generated naming/chunking;
- active hash-suffixed shards preserved when desired;
- no `psdl.*`, `pnc.psdl.*`, or `Conversation/Text/psdl/` steady-state output;
- no manual generated-file moves;
- two consecutive reconcile/apply passes are a no-op.

**Gate:** G7 structural acceptance passes and the parent goal may return to COMPLETE.

## Final developer acceptance

The parent goal is developer-complete only when G7 is accepted and:

```text
reconcile --check
→ missing = 0
→ drifted = 0
→ stale = 0
→ retired_present = 0
→ ambiguous = 0
```

for every enabled participant/owner, immediately after a successful canonical apply/generation; G5 regressions remain passing; G7 dynamic future-family, recipe-compaction, canonical-CLI, and naming/sharding gates also pass.

Native Project Zomboid is not required for this cleanup/lifecycle acceptance unless new evidence shows runtime-only behavior is involved.

## Stop rules

Do not:
- create a new branch;
- broadly stage unrelated dirty work;
- manually delete guessed legacy files;
- patch generated Lua/translation outputs as semantic source-of-truth;
- collapse active generated shards based on filenames;
- launch native Project Zomboid merely to satisfy this job;
- push/publish unless separately authorized.

If ambiguous historical output cannot be proven safe to delete, report it and continue all other implementable work rather than guessing.
