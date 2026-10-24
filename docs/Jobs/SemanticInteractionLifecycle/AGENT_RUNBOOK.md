# Semantic Interaction Lifecycle — Agent Runbook

## Parent objective

Treat the entire ROADMAP as one autonomous implementation assignment.

A phase is not the goal.

Do not report the parent complete after an audit, one migration family, one passing stress test or one harness improvement.

P0–P9 are retained implementation foundation, but developer acceptance was reopened by user native/harness evidence. Continue through mandatory P10 and any later user-approved corrective phases before handing back READY FOR USER LIVE TEST, unless a genuine blocker prevents safe progress.

## Required read order

1. root AGENTS.md
2. README.md
3. this file
4. AUDIT.md
5. ARCHITECTURE.md
6. MIGRATION_MATRIX.md
7. PERSISTENCE_AND_SCALING.md
8. NATIVE_CONVERSATION_PARITY_CORRECTION.md
9. ROADMAP.md
10. HARNESS_ACCEPTANCE.md
11. PROGRESS.md last

Also inspect current source and relevant predecessor job docs rather than treating these documents as proof of implementation.

## Foundation to preserve

Contextual Dialogue Persona & Choices P14 is accepted. Do not replay or replace its production save rehydration architecture.

Preserve:

- real save-backed isolated working world;
- production Lua persistence/deserialization;
- layered personal/faction/tactical/conversation social context;
- existing ActorConversationContext and SpeechStyleContext;
- existing parser/router/flow/response-plan/choice architecture;
- existing server-authoritative gameplay domains;
- existing ConversationBlocks authority;
- current EN/TL translation system.

## Git and repository safety

- Work on the existing checked-out main only.
- Never create a new branch.
- No force push, destructive reset/rebase/stash or ambiguous plain git pull.
- Check current HEAD/upstream/worktree before edits and preserve concurrent user/agent changes.
- Do not create or update GOAL_PROMPT.md. The executable /goal is chat-only.
- Git commit/push is not Steam Workshop publication.
- Never perform Workshop upload/republish.
- Never launch/restart/poll native Project Zomboid as an agent-owned acceptance loop.
- Never mutate the user's source save.

## Implementation rules

### One semantic lifecycle, no duplicate chatbot

Reuse the current parser, flow registry/kernel, ResponseCatalog, ResponsePlan, semantic suggestions/providers, presentation and authoritative domain adapters.

Do not build a second parser, response engine, memory chatbot, Python semantic simulator or competing harness.

### Known facts bypass NLU

Typed/headless freeform input uses NLU.

Emotes, lifecycle events and grounded game events emit typed semantic acts directly.

Never fabricate text only to parse it back into a known meaning.

### Persist meaning selectively

Do not persist normal rendered transcripts.

Persist only bounded unresolved state, meaningful residue, compact memory/event refs, commitments or structural facts through the correct owner.

### Sparse pair state

No theoretical Player × NPC materialization.

Create pair state only after meaningful durable delta. Remove it when compaction leaves nothing.

### Event-driven only

No per-NPC per-tick semantic work, thread expiry, emotion decay, memory scoring or suggestion refresh.

Use timestamps, lazy access and bounded maintenance.

### Multiplayer authority

Server owns durable lifecycle state and authoritative mutations.

Client UI/history is presentation-only.

Do not replicate one player's private relationship/Knowledge/thread context to unrelated clients.

### ConversationBlocks

Keep authored graph/gates/effects/repetition authoritative.

Only speech realization may converge where safe.

### Native Conversation parity

The Semantic Lab primary Conversation surface must mirror the production Conversation session.

- Production Lua owns opening/lifecycle state and presented choices.
- Render the exact production-selected choice group/rows in the main response surface.
- Keep full/global candidate projections in diagnostics only.
- Do not infer click validity from worker response type.
- Loading an NPC is not the same as opening a Conversation.
- Do not create Python/Tk replacements for \`buildCoreChoices\`, session choice authority, relationship presentation semantics or lifecycle policy.
- Treat user native screenshots/runtime observations as acceptance evidence that can reopen a falsely-complete developer gate.

### Harness UX correctness

The harness is an agent development tool, so usability is part of acceptance.

- Conversation gets primary visual space.
- Context/debug controls belong in a sidecar/dock where practical.
- Hiding controls must reclaim space.
- Ordinary worker operations must not overwrite user splitter/dock positions.
- Tests must exercise workflows, not merely assert that widgets have non-zero dimensions.
- World Browser role and affiliation projections must remain discoverable.

### Legacy retirement

Do not delete legacy flavor content before semantic parity exists.

Migrate useful lines as seed variants.

Retire duplicate authority after the new production path is proven.

## Development loop

For each phase:

1. verify current source and predecessor behavior;
2. choose the current bounded Next Chunk from PROGRESS;
3. make a real production-Lua change;
4. exercise it through the existing Semantic Lab real worker;
5. run focused tests and relevant stress/performance checks;
6. update this job's PROGRESS with exact evidence and next chunk;
7. continue automatically into the next unfinished chunk/phase.

Do not turn normal phase completion into a user checkpoint.

## True blockers

Valid blockers include:

- unsafe overlapping local changes with unclear ownership;
- required source/toolchain capability proven unavailable with no safe fallback;
- missing required Git authorization;
- unsafe repository divergence.

Not blockers:

- native PZ is closed;
- Workshop is not published;
- a phase passed;
- GUI display is unavailable when worker/Xvfb evidence is still possible;
- a later user live test remains pending.

