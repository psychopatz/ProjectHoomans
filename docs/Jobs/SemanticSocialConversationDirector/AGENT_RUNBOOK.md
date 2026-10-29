# Agent Runbook — Semantic Social Conversation Director

## Read order

Read root `AGENTS.md`, then:
1. `README.md`;
2. `ARCHITECTURE.md`;
3. this `AGENT_RUNBOOK.md`;
4. `ROADMAP.md`;
5. `HARNESS_ACCEPTANCE.md` while implementing/testing;
6. `PROGRESS.md` last.

Use `AUDIT.md` for revision-specific starting evidence.

Consult predecessor job docs only for an inherited/disputed contract. Do not reread completed histories wholesale.

## Parent objective

Implement the complete D0-D8 Social Conversation Director objective. The parent objective, not the current phase, is the completion boundary.

After each accepted chunk:
1. update `PROGRESS.md`;
2. select the next documented mandatory chunk;
3. continue automatically.

Do not ask for another `/goal` merely because a phase passed.

## Preserve accepted semantic architecture

Do not replace:
- PsychopatzCore NLU;
- InteractionStimulus/Providers/Context;
- PragmaticResolver;
- InteractionDirector;
- InteractionCatalog/InteractionPlan;
- SemanticInteractionSceneRuntime/Scheduler;
- InteractionPresentation;
- existing player conversation lifecycle/UI;
- generated semantic response concepts;
- domain gameplay authorities.

Generalize through existing seams.

## No parallel dialogue systems

Forbidden:
- companion conversation engine;
- neutral conversation engine;
- raider/hostile conversation engine;
- separate gossip follow-up engine;
- task conversation scheduler;
- second autonomous Scene Runtime;
- fake NPC button-click implementation.

NPCs consume semantic affordances, not UI labels.

## Grounding and authority

The Social Director may:
- propose/open social scenes;
- rank social motives;
- select bounded speakers/recipients;
- rank semantic response affordances;
- emit semantic/social events.

It may not invent authoritative gameplay facts or directly own:
- combat outcomes;
- movement;
- tasks;
- inventory;
- faction state;
- relationship values;
- knowledge truth;
- settlement/excursion state.

## Silence rule

Silence/no-scene/no-response is first-class and should be common for low-value opportunities.

Do not tune the system to maximize chatter.

## Group-turn rule

At most one ordinary semantic speaker is selected per continuation step. Never independently trigger every participant to reply.

Urgent domain events may interrupt only through explicit bounded policy.

## Player interop rule

Player observer != participant != recipient.

Overhearing alone must never expose player response buttons.

When the player is the addressee, reuse the existing semantic response surfaces and typed-input path.

## Performance rule

No per-NPC conversation tick.

Prefer event-supplied/local candidate sets. Do not scan all NPCs/faction members for speakers.

Respect existing Scene Runtime hard limits and add bounded social budgets rather than raising global caps to create more chatter.

No routine LLM calls.

## Persistence rule

Do not persist routine social Scene transcripts, generated choices, InteractionPlans, reasoning traces or NPC choice traces.

Meaningful consequences may be recorded only by existing durable owning authorities.

## Validation cadence

After each coherent chunk:
- focused Lua;
- focused semantic/player regressions when shared affordance code changes;
- real Semantic Harness worker where applicable;
- Scene/Social Observatory assertions;
- static performance/authority guards;
- deterministic CodeBuilder/translation checks when authored content changes;
- installed-PZ Kahlua verification for changed Lua;
- Python `py_compile` for changed harness Python;
- `git diff --check`;
- update `PROGRESS.md`;
- continue automatically.

## Git/runtime

Use existing `main` only.

Before edits/commit, check actual branch/HEAD/status and preserve unrelated work. Never reset/rebase/stash/discard uncertain changes.

Do not launch native Project Zomboid unless explicitly assigned.

Do not publish or republish Workshop content without explicit authorization.

## Stop conditions

Once implementation begins, stop only for:
- complete D0-D8 developer acceptance;
- genuine unsafe concurrent worktree/ownership conflict;
- unavailable required tool/runtime/auth with no accepted fallback;
- architecture/scope conflict requiring user choice;
- final user-owned native SP/MP acceptance after all developer-side work is complete.
