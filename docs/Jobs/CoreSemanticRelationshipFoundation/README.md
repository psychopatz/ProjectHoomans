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

**Current state: IN PROGRESS.** A fourth independent production-path audit after the P16-P17 closeout found that the new Core issuance registry and DT factual policy APIs are useful foundations, but two completion claims remain false.

Retain all accepted work, especially P8B social integrity, semantic-pack lifecycle, P14 production capability isolation, complete DT parser coverage, bounded uncertainty, real WorldKnowledge road-news/route grounding, the P16 issuance registry itself, and the P17 policy/TalkService integration.

Mandatory P18-P19 work remains for:

- preventing Core identity lookup from auto-authorizing an unknown `PNC_CharacterUUID` before Hoomans validates it;
- importing Hoomans-first identities into Core only from the authoritative Hoomans player-character registry/service, never from player mirror modData alone;
- wiring real excursion/travel lifecycle into canonical DT origin/destination state;
- resolving canonical settlement/community IDs to human-facing names before factual dialogue realization;
- proving destination/origin/current-settlement/news state survives a real DT storage save/reload path;
- upgrading the final matrix around the exact vulnerable call order and live travel lifecycle.

Developer-side completion now requires the full P0-P19 roadmap and current acceptance matrix. Native Project Zomboid SP/MP validation remains user-owned unless explicitly reassigned. Steam Workshop publication is never implied by Git completion.
