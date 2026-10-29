# Agent Runbook — Semantic Interaction Scene Runtime

## Read order

Read root `AGENTS.md`, then:
1. `README.md`;
2. `ARCHITECTURE.md`;
3. `AGENT_RUNBOOK.md`;
4. `ROADMAP.md`;
5. `PROGRESS.md` last.

Read `AUDIT.md` while establishing revision-specific evidence and `HARNESS_ACCEPTANCE.md` while implementing/accepting gates.

Use predecessor docs only for a specific inherited contract:
- `SemanticCombatBanterTacticalIntent`;
- `UnifiedSemanticEvidenceArchitecture`;
- `PragmaticDialogueBeatDirector`;
- `SemanticInteractionLifecycle`.

Do not reread completed histories wholesale.

## Parent objective

Productionize the existing Interaction Scene foundation as the canonical event-driven autonomous/multi-actor semantic conversation subsystem and prove it across multiple unrelated domains.

S0-S8 is the completion boundary.

## Preserve the existing core

Do not replace:
- PsychopatzCore NLU;
- InteractionStimulus;
- InteractionProviders/Evidence;
- InteractionContext;
- PragmaticResolver;
- InteractionDirector;
- InteractionCatalog;
- InteractionPlan;
- InteractionPresentation;
- Dialogue Content/CodeBuilder;
- existing player conversation lifecycle/UI;
- domain gameplay authorities.

Extend/generalize through existing seams.

## No parallel conversation engines

Forbidden:
- combat exchange engine beside InteractionScene;
- neutral/hostile NPC dialogue engine;
- gossip conversation engine;
- settlement conversation engine;
- task conversation engine;
- feature-specific generic follow-up state.

Adopters provide opportunities/facts/content. SceneRuntime owns generic scene mechanics.

## Semantic continuation rule

Never reparse realized NPC prose.

Continuation comes from semantic plan/behavior metadata and grounded refs.

Rendered EN/TL is presentation only.

## Player lifecycle rule

Do not convert player-pair persistent lifecycle into a generic NPC transcript store.

Player session and SceneRuntime are separate bounded frontends over the shared semantic core.

Interop is required; storage unification is not.

## Event-driven/performance rule

No per-NPC conversation tick.

Prefer event-provided candidate sets. Otherwise at most one bounded spatial query at admission.

Never iterate full faction membership for local speakers.

Respect hard scene/participant/turn/history caps.

## Audience rule

Speaker, recipient, participant and observer are distinct.

Overhearing never grants player response affordances by itself.

## Authority rule

A scene may express/propose/react. It may not invent gameplay truth.

Movement, combat, faction, task, trading, excursion, relationship and other mutations remain with their owning services.

## Persistence rule

Autonomous scene state is transient by default.

No new ModData transcript, generated-dialogue persistence or routine LLM path.

## Adopter proof rule

S6 must contain at least:
- combat;
- grounded social knowledge;
- one real non-combat gameplay domain.

S8 requires a fourth synthetic future-domain fixture that works without generic runtime algorithm changes.

## Validation cadence

After each accepted chunk:
- focused Lua;
- real worker where applicable;
- performance/static guards;
- player conversation regression when shared semantic core changes;
- deterministic CodeBuilder if content changed;
- Kahlua verification;
- `git diff --check`;
- update `PROGRESS.md`;
- continue automatically to the next mandatory phase.

## Git/runtime

Existing `main` only.

Preserve unrelated work. No reset/rebase/stash/discard of uncertain changes.

Do not launch native Project Zomboid unless explicitly assigned. Native SP/MP remains user-owned after developer acceptance.

Do not publish/republish Workshop content without explicit authorization.

## Stop conditions

Once implementation is authorized, continue S0-S8 automatically.

Stop only for:
- developer-side parent completion;
- genuine unsafe concurrent worktree/ownership conflict;
- unavailable required tool/runtime/auth with no safe fallback;
- architecture authority conflict requiring user choice;
- final user-owned native gate.
