# Agent Runbook — Semantic NPC Group Conversation

Use this runbook for the active NPC-group-conversation job only.

## Read order

Read root `AGENTS.md`, then:
1. `README.md`;
2. `AUDIT.md`;
3. `ARCHITECTURE.md`;
4. `ROADMAP.md`;
5. `HARNESS_ACCEPTANCE.md`;
6. `PROGRESS.md` last.

Read predecessor job details only when a current contract requires them:
- `docs/Jobs/SemanticCombatBanterTacticalIntent/ARCHITECTURE.md`;
- `docs/Jobs/SemanticCombatBanterTacticalIntent/PROGRESS.md`;
- `docs/Jobs/PragmaticDialogueBeatDirector/ARCHITECTURE.md`;
- `docs/Jobs/SemanticInteractionLifecycle/ARCHITECTURE.md`.

Do not reload completed-job history wholesale.

## Parent objective

Generalize the accepted semantic combat architecture so companions, neutral NPCs, hostile NPCs and faction squads can form short coherent NPC-to-NPC and NPC-to-player encounter conversations while remaining event-driven, performant, transient and grounded in real gameplay state.

The full G0-G8 roadmap is the completion boundary.

## Hard architecture rules

Do not create a second:
- parser/NLU stack;
- combat resolver;
- faction/group membership database;
- world/zombie scanner;
- speech renderer;
- translation system;
- combat banter arbiter;
- interaction lifecycle;
- persistent transcript/memory store;
- neutral/hostile/companion dialogue engine.

Generalize existing authorities instead.

## Cohort rule

Owner team is one cohort kind, not the universal team identity.

Resolve cohort from existing authority:
- owner/follower team;
- explicit authoritative group if production exposes one;
- faction;
- solo.

Nearby strangers are not automatically teammates.

Faction-wide membership is never the local conversation candidate list.

## Performance rule

No NPC conversation polling loop.

Admission is event-driven:
- gameplay/perception/combat event occurs;
- reuse its local candidate set where possible;
- otherwise one bounded spatial query;
- filter/cap candidates;
- arbiter admits at most bounded speaker/respondent turns.

Never perform a spatial query once per exchange turn.

## Semantic-turn rule

NPCs respond to semantic frames, never rendered prose.

Do not feed NPC A's realized English/TL back through NLU for NPC B.

## Audience rule

Speaker, recipient and observer are distinct.

A nearby player overhearing NPC-to-NPC speech is not automatically a participant and receives no semantic buttons.

Player offers appear only when the player is actually addressed/eligible.

## Gameplay-authority rule

Dialogue may express, propose or react to an encounter decision.

It may not invent an engage/retreat/cover/flank result that gameplay authority did not establish.

For autonomous cohorts, hook existing AI/faction/combat policy. If no authoritative fact exists, omit/defer that dialogue mechanic.

## Runtime-state rule

Combat cohort/exchange state is bounded and transient.

No ModData transcript. No rendered-text history. No routine LLM.

## Arbiter rule

Every exchange turn competes through the accepted Combat Banter Arbiter. Urgent warnings/tactical coordination outrank ordinary jokes/boasts. Silence is a first-class result.

## Content/compiler rule

All new player-facing dialogue content is authored in canonical CodeBuilder source with EN/TL ownership and deterministic regeneration.

Generated Conversation Lua is downstream output, never hand-authored source.

## Validation discipline

After every accepted chunk:
- focused Lua tests;
- real-worker semantic cases;
- performance/query/fanout assertions where relevant;
- no-ModData/no-LLM guards;
- CodeBuilder deterministic generation if content changed;
- Kahlua verification;
- `git diff --check`;
- update `PROGRESS.md`;
- continue automatically to the next mandatory phase.

Native Project Zomboid SP/MP remains user-owned unless explicitly reassigned.

## Git/publication

Use existing `main` only.

Preserve unrelated work. Do not stash/reset/rebase/discard uncertain changes. Do not publish/republish Workshop content without explicit user authorization.

## Stop conditions

Continue through G0-G8 automatically once implementation starts.

Stop only for:
- complete developer-side parent acceptance;
- a genuine repository/runtime/auth blocker;
- an authority/scope conflict;
- or the explicitly user-owned native live gate after all developer work is complete.
