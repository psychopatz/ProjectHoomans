# Roadmap — Semantic Generation Lifecycle Cleanup

**Parent status:** IN_PROGRESS.
**Completion boundary:** all developer-side phases G0–G6 accepted.
**Parent objective:** eliminate confirmed semantic generation leftovers and make future cleanup automatic, safe, closed-set and recipe-driven.

A phase/chunk completing is not completion of the parent goal. Continue through G0–G6 unless a genuine blocker or explicit user-owned live gate remains.

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

**Status:** NOT STARTED.

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

## Final developer acceptance

The parent goal is developer-complete only when:

```text
reconcile --check
→ missing = 0
→ drifted = 0
→ stale = 0
→ retired_present = 0
→ ambiguous = 0
```

for every enabled participant/owner, immediately after a successful canonical apply/generation, and all G5 regression tests pass.

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
