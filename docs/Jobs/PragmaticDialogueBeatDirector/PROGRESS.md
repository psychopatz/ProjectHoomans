# Progress — Pragmatic Dialogue Beat Director

**Status:** READY TO IMPLEMENT.
**Current branch:** `main`.
**Audited baseline:** `6fa471dec0fc1caec2d3b4871f56d4b102ae0e6f`.
**Current phase:** P0 — baseline, parity, and contracts.

## Verified starting foundation

- root repository policy is compact and job-local;
- worktree was clean and `main` matched `origin/main` at documentation start;
- production DialogueFlowRegistry exists and is data-only/validated;
- worker FlowEditor already exposes real production catalogs and worker-local
  flow validation/registration;
- existing tests prove a registered draft flow runs in a real worker turn;
- ResponsePlan is bounded and composable;
- Semantic Lab already has Flow Editor and live Interaction Explorer seams;
- modular Conversation CodeBuilder source is canonical;
- generated runtime/translation artifacts are downstream-only;
- EN fallback + data-driven locale generation already exist.

## Parent product gap

Project Hoomans still lacks a first-class pragmatic/dramatic beat layer and an
explainable director that can use semantic meaning + context + personality/
relationship/world state to choose among reusable conversational behaviors.

It also lacks a Beat Studio and compiler-owned beat/behavior source/string
workflow.

## Immediate Next Chunk — P0A

1. Recheck exact local `main`/upstream/status and actual Core checkout used by
   the worker.
2. Reproduce the hostile-language case through the real Lua worker, including
   typo/paraphrase variants.
3. Capture selected Core candidates/IR, policy branch, flow state, response
   source/plan, translation, final text, and side effects.
4. Reconcile the result against the existing hostile-language tests that forbid
   generic clarification.
5. If the worker/runtime path is wrong, repair that parity defect with focused
   regression coverage before implementing beats.
6. Map the exact compiler/manifest extension points for beat/behavior canonical
   sources and generated strings.
7. Record P0A evidence here, then continue automatically into P0B/P1.

## Mandatory continuation

The autonomous goal owns P0–P8. After each accepted chunk:

- update this file to current truth;
- select the next mandatory roadmap chunk;
- continue automatically.

Do not return merely because a registry, editor panel, test, or one initial beat
is complete.

## Stop conditions

Stop early only for:

- unsafe concurrent ownership/divergence that cannot be reconciled;
- a required external capability/auth boundary with no accepted fallback;
- a proven architecture conflict requiring user choice;
- completion of all P8 developer-side gates.

Do not stop merely for native user-owned PZ acceptance.

## Safety

- no new branch;
- no push without explicit authorization;
- no Workshop publication;
- no native PZ launch;
- no source-save mutation;
- no root `AGENTS.md` goal-state edits;
- no generated-file hand fixes.
