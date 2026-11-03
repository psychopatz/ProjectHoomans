# Core Semantic & Relationship Foundation

**Parent goal:** make PsychopatzCore the reusable semantic/conversation and canonical shared relationship foundation so Dynamic Trading can provide rich standalone dialogue without Project Hoomans, while Project Hoomans remains an additive adopter for deeper NPC-specific dialogue/actions.

This is one cross-repository implementation goal spanning:

- `/home/psychopatz/Zomboid/Workshop/psychopatzCore`
- `/home/psychopatz/Zomboid/Workshop/DynamicTrading`
- `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`

The completion boundary is the full cross-mod outcome, not one extraction or one repository.

## Product outcome

A save using Core + Dynamic Trading must support persistent actor identity, relationships, memories, relationship-aware story/trader dialogue, semantic parsing/flow handling, and Dynamic Trading actions without enabling Project Hoomans.

Adding Project Hoomans later must enrich the same actors and relationships rather than duplicate or reset them. Removing Project Hoomans later must leave Dynamic Trading and Core state healthy; Hoomans-owned extensions become dormant/preserved rather than destructive migration targets.

Project Hoomans may register richer social/content/action packs, but Core must never import Hoomans gameplay policy. Dynamic Trading may register trader/commercial/story content and actions, but must not import Hoomans semantic registries for ordinary standalone operation.

## Accepted foundation — do not rebuild

The existing Core NPC Foundation is accepted developer-side foundation:

- canonical Core actors, stable identity and provider leases;
- Core personal/social persistence and migration machinery;
- directional Core Social state with approval/respect/familiarity/memories;
- DTAbstract/DTHoomans provider switching and actor projection;
- Core semantic parser/IR/registry/router/dialogue-turn foundation;
- Core conversation capability and translation capability;
- Project Hoomans domain/refactor work that already exposes semantic subdomains and guards private ownership.

This job extends and consolidates those accepted seams. It does not reopen their completed roadmaps absent a concrete regression.

## Read order

1. ProjectHoomans root `AGENTS.md`.
2. This `AGENT_RUNBOOK.md`.
3. `AUDIT.md`.
4. `ARCHITECTURE.md`.
5. `ROADMAP.md`.
6. `ACCEPTANCE.md`.
7. `PROGRESS.md` last.

Also inspect the accepted Core foundation docs under `psychopatzCore/Docs/npc_foundation/` and current repository source before changing authority.

## Completion state

**Current state: IN PROGRESS.** A fifth independent production-path audit after the P18-P19 closeout accepted P18 and the main P19 happy-path travel/presentation work, but reproduced one remaining live lifecycle defect and found that the trader-record reload proof is still synthetic.

Retain all accepted work. In particular:

- P18 mirror-to-authority bootstrap protection is independently verified;
- legitimate DT-first and Hoomans-first identity convergence remains accepted;
- P14 production capability isolation remains accepted;
- P19 PREPARING/OUTBOUND/VISITING/RETURNING_HOME/AT_HOME travel projection works;
- canonical machine settlement IDs resolve to human-facing names without leaking raw IDs;
- route/news WorldKnowledge grounding and bounded uncertainty remain accepted.

Mandatory P20 work remains for:

- correcting FAILED excursion semantics when normalized numeric timestamps use `0` for "not completed";
- adding failure-state regressions for before-departure and after-departure cases;
- strengthening factual trader-record persistence acceptance so reload reconstructs state from a persisted snapshot rather than retaining the same Lua table/object;
- reconciling Git-history documentation: the formerly preserved `DTHoomans_Conversation.lua` local edit is now committed in Dynamic Trading commit `be9e8e10`, and all three worktrees are currently clean.

Developer-side completion now requires P20 and its acceptance matrix. Native Project Zomboid SP/MP validation remains user-owned after developer acceptance. Steam Workshop publication is never implied by Git completion.
