# Pragmatic Dialogue Beat Director

**Status:** READY TO IMPLEMENT.

This job adds a production-owned pragmatic conversation layer and first-class
dialogue beats to Project Hoomans, with live authoring/debugging in the existing
Semantic Lab and compiler-owned first-party strings.

## Parent objective

Make offline Project Hoomans conversation feel less like intent → canned reply
and more like an emergent social interaction:

```text
player utterance
    ↓
Core semantic candidates
    ↓
pragmatic/context resolution
    ↓
dialogue state + active/suspended flows
    ↓
beat arbitration
    ↓
behavior arbitration
    ↓
grounded ResponsePlan
    ↓
Dialogue Content realization
    ↓
speech and separately-authorized gameplay effects
```

The full goal includes both runtime intelligence and the developer workflow
needed to iterate on it safely.

## Required product results

- A validated production `DialogueBeatRegistry` for data-defined social/dramatic
  situations.
- A production `DialogueDirector` that explains beat eligibility, entry/exit,
  active beat state, candidate behaviors, modifiers, and the winner.
- Clear separation between **Flow**, **Beat**, **Behavior**, **ResponsePlan**, and
  authoritative gameplay effects.
- A Semantic Lab **Beat Studio** that can browse production beats, edit drafts,
  validate, preview, worker-register, disable/force for diagnostics, run
  scenario matrices, and inspect real multi-turn behavior without restarting
  Project Zomboid.
- Simulation/Inspector views that show beat transitions and why candidates won
  or lost, including a turn timeline.
- Canonical beat/behavior/content authoring in the existing modular Conversation
  CodeBuilder source model.
- Compiler-generated first-party beat/dialogue strings, translation keys,
  locale bundles, generated registries/manifests, and runtime artifacts.
- Data-driven locales with EN fallback; no new hardcoded TL branch.
- Regression capture and headless replay over the same production Lua worker.
- Optional PBrainZ may realize the same validated plan, but never becomes beat,
  fact, relationship, task, inventory, or gameplay authority.

## Existing foundation to reuse

At source checkpoint `6fa471dec0fc1caec2d3b4871f56d4b102ae0e6f`:

- `DialogueFlowRegistry` already validates and stores data-only flows.
- the worker `FlowEditor` already exposes live production catalogs and
  worker-local draft validation/registration;
- Semantic Lab already has a Flow Editor and Interaction Explorer;
- `ResponsePlan` already represents bounded dialogue-act plans;
- the modular Conversation CodeBuilder source tree is the canonical first-party
  wording/flow/pattern/UI authoring source;
- CodeBuilder already generates deterministic runtime shards and locale bundles.

This job extends those seams. It must not create a second parser, second
conversation engine, second compiler, or Python-owned decision engine.

## Compiler/string rule

All beat-related **first-party Conversation content** must be authored through
canonical compiler inputs and generated downstream. This includes NPC wording,
player-facing suggestions/utterances, behavior/beat labels or descriptions
shown by the mod, and localized response variants.

Beat-specific phrases must not be hardcoded into production Lua or Python.
Harness-only generic developer chrome such as “Validate draft” may remain UI
code; semantic/domain content belongs to the Conversation compiler.

## Scope relationship to Unified Semantic Dialogue Authority

The accepted modular Conversation/compiler foundation is a dependency, not a
reason to resume unrelated paused P11 domain migrations. Implement only the
compiler extensions and content migrations required by this job. Do not hand
edit generated artifacts.

## Read order

1. root `AGENTS.md`;
2. this `README.md`;
3. `AUDIT.md`;
4. `ARCHITECTURE.md`;
5. `AGENT_RUNBOOK.md`;
6. `ROADMAP.md`;
7. `HARNESS_ACCEPTANCE.md`;
8. `PROGRESS.md` **last**.

The executable `/goal` remains chat-only per repository policy.
