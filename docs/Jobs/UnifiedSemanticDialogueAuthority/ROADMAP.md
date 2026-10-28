# Roadmap — Unified Semantic Dialogue Authority

**Parent status:** IN PROGRESS / PAUSED.
**Developer completion boundary:** P11I.

## Accepted foundation

P0–P10, P11A, and P11B0 are accepted.

Those phases established semantic-first dialogue authority, removed first-party
legacy Flavor/ToolReply wording authority, created modular manifest-backed
Conversation authoring, bounded generated runtime shards, deterministic
generation, and generated domain translation bundles.

Do not reread or recreate their phase-by-phase migration history during normal
work.

## P11B — one first-party wording authority

**Status:** IN PROGRESS.

Completed domains:

- Wellbeing;
- Needs;
- Health;
- Social Apology.

Next recommended domain: **Task Fetch**.

Continue by coherent Conversation domain, not by individual translation key.
Each domain must migrate real production callers directly into canonical
Dialogue Content, preserve EN and optional-locale placeholder behavior, and
remove superseded paths only after parity/caller-zero proof.

P11B is complete when Project Hoomans first-party conversational wording is
traceable to Dialogue Content or an explicit external provider boundary, with no
broad alias registry hiding unmigrated internal callers.

## P11C — modular source refinement

Refine P11B0's source/compiler model only where real migrated content exposes a
scaling problem.

Required steady state:

- one Conversation manifest/compiler;
- cohesive content/pattern/flow/UI shards;
- no giant canonical aggregate authoring file;
- stable IDs independent of physical shard paths;
- generated aggregate snapshots remain read-only audit artifacts.

## P11D — Conversation UI Registry

Move static landing/hub/child/order/presentation structure into one canonical
registry under the modular Conversation source model.

The registry may reference dynamic providers/predicates but must not own
relationship, gossip, recruitment, task, inventory, faction, world or other
gameplay authority.

Primary acceptance case: edit/reorder the children of **What's up?** without
editing production Lua.

## P11E — taxonomy and naming cleanup

Canonical IDs must describe meaning, not implementation provenance.

Remove or migrate names such as:

- `semantic.generated.*`;
- `parameterized_task` as visible taxonomy;
- unnecessarily repeated `semantic`/generator prefixes;
- implementation-history translation filenames.

Keep provenance such as generator/workflow/source-shard in metadata.

Target examples:

```text
task.fetch.failed
command.follow.queued
gift.pending
question.wellbeing.fatigue
social.apology.friendly
```

Translation keys should be derived mechanically and kept short enough for
inspection; humans/agents should normally author canonical Conversation IDs,
not translation-key boilerplate.

## P11F — Studio consolidation

Use one primary **Conversation** explorer.

Fold useful route/trigger/flow/conditions/follow-up/source information into the
selected Conversation item. Remove the redundant everyday
Responses/Interactions/Dialogue Content maze.

## P11G — contextual Developer Tools

Repurpose Developer Tools to edit the selected Conversation item.

Required normal operations:

- EN/other-locale wording;
- add/duplicate/delete/reorder phrase variants;
- style editing;
- Conversation hub membership/order;
- label/player utterance editing;
- preview;
- Review;
- explicit validated write/compile.

Gameplay/dynamic authority remains locked and visibly sourced.

## P11H — shared GUI/agent authoring service

GUI and agents use the same bounded canonical-ID APIs for inspect/edit/add/
remove/reorder/validate/preview/write/compile operations.

No direct generated-file authoring.

## P11I — final modular acceptance

Final developer acceptance must prove:

- one semantic meaning authority;
- one first-party wording authority;
- one Conversation UI/navigation authority;
- locale discovery is data-driven with EN fallback;
- generated artifacts are deterministic and bounded;
- canonical names describe domain meaning;
- Studio/Developer Tools follow the consolidated workflow;
- typed/clicked/event behavior remains;
- PBrainZ and compatibility adapters remain;
- no save mutation;
- full native Lua and relevant Python/Kahlua/CodeBuilder gates remain green.

Only then return to **READY FOR USER LIVE TEST**.

## Scope boundary

No P12 or new mandatory parent phase without explicit user approval.
