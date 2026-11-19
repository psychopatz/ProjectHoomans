# Progress — Project Hoomans Portable Social State Adoption

**Status:** IN PROGRESS participant work.
**Parent:** PsychopatzCore Docs/portable_social_state/.
**Current participant phase:** H0 accepted; awaiting parent P1-P3 before H1-H4.
**Participant completion:** 1/7 phases accepted (H0).

## Verified H0 facts

- Full H0 inventory recorded in `AUDIT.md` with exact file/line evidence for `RelationshipService` (11 submodules), `SocialEvent` (25 event types), `ConductService` (7 dimensions), `NPCKnowledgeService`, `ConversationMemory` (`raw.m`), `EntityRef`, `FactionIntent`, `UnifiedSemanticEvidence`, and `SocialConversationDirector`.
- Verified convergence hazards: `PNC_EntityRef.Parse` rejects `actor:*`, colon-containing `npc:*`, and 2-segment `player:*` keys; `PNC_RelationshipMath.RecalculateRelationship` can overwrite foreign Core deltas; `PNC_Persistence_CoreSocial.lua` puts generic fields in `rel.extensions.ProjectHoomans`.
- Baseline Hoomans smoke suites verified passing (`pnc_core_social_convergence_smoke`, `pnc_non_destructive_social_mutation_smoke`, `pnc_social_events_smoke`, `pnc_semantic_evidence_provider_smoke`).

## Immediate Next Chunk

Support parent P3 (`PNC/SocialPolicy` CodeBuilder package) and proceed to **H1-H4** (`P4`) once Core P1-P3 contracts are accepted.

## Acceptance

Hoomans H0-H6 is participant completion only. Parent completion requires Core P0-P9 including DynamicTrading/DTAbstract adoption.
