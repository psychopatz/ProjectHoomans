# Agent Runbook — Contextual Dialogue Persona & Choices

## Parent objective

The assignment is the **complete developer-side goal**, not whichever phase is currently being worked on. Work one bounded coherent chunk at a time, validate it, record evidence, and continue automatically through all mandatory roadmap phases.

A phase passing does not complete the parent goal.

Only hand back **READY FOR USER LIVE TEST** when every developer-implementable requirement in this job is complete and verified. Native Project Zomboid SP/MP gameplay validation remains user-owned.

## Repository and Git rules

Root `AGENTS.md` is authoritative.

- Existing `main` only; **never create a new branch**.
- Inspect local branch, HEAD, upstream, remote, and user/concurrent work before edits.
- No blind `git pull`, destructive reset, rebase, stash, force push, or worktree/branch workaround.
- Preserve unrelated user/agent changes.
- Commit coherent implementation + documentation slices when safe.
- Do not install, upload, republish, or request authorization for Steam Workshop content.
- Do not launch or operate native Project Zomboid as an agent acceptance workaround.
- **Do not create or update a checked-in `GOAL_PROMPT.md`.**

## Ownership rules

### Existing authoritative state remains authoritative

Do not create duplicate persistent personality, relationship, role, identity, knowledge, trader, or dialogue-state databases.

- Identity owns identity/gender data.
- NPC Traits owns discrete traits.
- Social Profile owns persistent personality dimensions.
- Relationships owns directed approval/respect/familiarity/state/memories.
- Existing actor/capability owners determine companion/owned/hostile/task/action eligibility.
- Dynamic Trading owns trader-specific domain state.
- Conversation/Semantics owns dialogue context and typed semantic routing.
- Gameplay/server handlers remain the only side-effect owners.

The new actor/speech context is a **bounded read-only projection/compiler**, not a state owner.

### Meaning and wording are separate

The semantic response plan or semantic click frame owns **what the utterance means**. Persona/style may change **how that meaning is realized**, never the underlying fact, authorization, action, target, or gameplay result.

Gender must not be used as a personality stereotype. Use it only where identity, grammatical realization, pronouns, compatibility, or explicit authored rules require it.

### One choice path

Preserve the existing path:

`typed/NPC result -> candidate providers -> constraints/privacy -> rank/dedupe -> localized presentation -> Core choicesPart -> semantic_click_frame -> existing DialogueInput -> existing authority/action owner`.

Do not add a second parser, second response generator, second choice widget, second translation backend, second action dispatcher, or button-specific gameplay lane.

## Performance and persistence

- No per-frame NLP/choice generation.
- No per-tick all-NPC persona compilation.
- Recompute bounded actor/speech context on conversation/actor/relationship/profile revisions or turn-driven demand.
- Do not persist derived speech dials or candidate catalogs in ModData.
- Keep candidate/source/trace bounds explicit.
- Reuse translation caches and existing Core/Hoomans localization infrastructure.

## Validation discipline

The existing Semantic Lab and real Lua worker are mandatory acceptance tools. Python-only previews or scratch JSON do not prove runtime behavior.

For every implementation slice:

1. run focused unit/contract tests;
2. run affected Lua/Python regressions;
3. exercise the real production Lua worker for changed semantic behavior;
4. use the existing Tk Semantic Lab under Xvfb when UI behavior changes;
5. verify EN/TL and fallback diagnostics when text changes;
6. verify stale/replay/privacy/authority behavior when candidate or click policy changes;
7. run Kahlua/`luac5.3`, doctor, and bounded performance checks at final gates;
8. record skipped/unavailable evidence honestly.

## Stop conditions

Stop only for a genuine safety/authorization blocker, unsafe repository divergence/concurrent ownership conflict, missing required external capability with no valid fallback, or full developer-side completion.

Do not stop because an individual phase passed, documentation was updated, unit tests passed, or native PZ is unavailable.
