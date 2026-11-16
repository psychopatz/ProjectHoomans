# Agent Runbook — Semantic Generation Lifecycle Cleanup

## Purpose

Execute the cleanup/lifecycle roadmap without turning generated-file archaeology into manual agent work.

G0–G6 are accepted groundwork. The parent goal is complete only when G7 also passes.

## Startup

For every repository that may be changed:

1. verify actual branch, HEAD, upstream and worktree state;
2. read that repository's durable root instructions;
3. preserve unrelated staged/unstaged/untracked work;
4. inspect current CodeBuilder files rather than assuming the planning anchors remain current;
5. use the job's `PROGRESS.md` as current accepted truth.

Primary job/document owner: ProjectHoomans.

Likely participant repositories:
- ProjectHoomans
- psychopatzCore
- DynamicTrading when DTCommon generation is enabled or affected

Do not create a new branch.

## Source-of-truth order

For semantic generation lifecycle questions prefer:

1. exact current CodeBuilder source/tests;
2. current canonical ConvoEngine source families/manifests/text sources;
3. generated recipe + desired artifact ledger once implemented;
4. generated registries/manifests;
5. this job's architecture/roadmap;
6. historical Git evidence only when classifying legacy output.

Generated runtime files are evidence/output, not semantic authoring authority.

## G7 structural-refactor rule

The reconciler already exists. G7 must simplify ownership rather than add more exception inventory.

- do not add new per-file preserve entries for ordinary future semantic content;
- do not add one-off retirement entries merely because a normal generated family was removed;
- do not use filename/hash patterns as deletion proof;
- do not patch generated Lua/JSON to fix semantic behavior;
- dialogue/semantic wording belongs in canonical ConvoEngine family source;
- ordinary application/tooling text belongs outside generated ownership;
- before changing source naming/sharding, read `psychopatzCore/Docs/semantic_dialogue_language_standard/CONVO_ENGINE.md` and `NAMING_AND_LAYOUT.md`; preserve their accepted contracts.

## Target steady-state workflow

After G3 is accepted, ordinary semantic generation maintenance should become:

```text
1. edit canonical semantic source
2. run reconciliation --check
3. inspect proposed stale/missing/drifted report
4. run reconciliation --apply
5. run reconciliation --check again
6. run affected semantic tests
```

The exact CLI is allowed to follow existing project conventions, but there must be one obvious recipe-driven check/apply entrypoint.

## Safe cleanup rules

An artifact may be removed automatically only when CodeBuilder ownership is proven by the accepted architecture.

Never delete because:
- it looks old;
- it is untracked;
- it contains a hash suffix;
- another similarly named generated file exists;
- it is not directly referenced by a quick grep;
- its modification timestamp is old.

Unknown or ambiguous artifacts are reported, not deleted.

## Mixed authored/generated catalogs

Treat mixed catalogs as migration/compatibility seams, not the desired architecture. Where one must temporarily remain, key ownership must be automatic and bounded. G7 should preferentially split generated ConvoEngine text into its generated-owned subtree and leave ordinary application translations outside it.

## Legacy retirement procedure

For each confirmed historical leftover:

1. identify current path and repository;
2. establish why it is CodeBuilder-owned/obsolete;
3. record the retirement in the recipe/tombstone mechanism;
4. prove check mode detects it;
5. prove apply mode removes it;
6. prove a second check is clean;
7. keep a compact **structural** anti-regression tombstone only where reappearance of an old root/class is itself a regression; remove one-time filename tombstones after closure.

Do not perform step 5 before steps 1–4.

## Validation discipline

Every phase must include deletion-path tests, not only creation-path tests.

At minimum, use isolated output roots/fixtures before applying cleanup to real repositories.

Do not require native Project Zomboid unless exact evidence shows the lifecycle cannot be validated statically/harness-side.

## Git discipline

- Preserve unrelated user/agent work in all participant repositories.
- Stage exact phase-owned paths only if closing an accepted phase.
- Never use `git add -A` for cleanup.
- Never reset/stash/discard uncertain changes.
- Local phase commits may be used by the implementing agent according to root policy; do not push without explicit authorization.
- In a multi-repo accepted phase, participant repo commits precede the primary/job repo commit.

## Documentation discipline

- ROADMAP: full objective and gates.
- PROGRESS: current verified state + exactly one Next Chunk.
- HANDOFF: replaceable session baton.
- ARCHITECTURE: stable lifecycle contracts.
- AGENTS.md: only the brief durable semantic-generation rule.

Do not copy file inventories or current cleanup counts into AGENTS.md.
