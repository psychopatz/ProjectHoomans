# Compact Social Memory & Relationship Authority — Project Hoomans Adoption

**Status:** PLANNED participant work.
**Canonical parent job:** /home/psychopatz/Zomboid/Workshop/psychopatzCore/Docs/portable_social_state/
**Parent completion boundary:** PsychopatzCore Portable Social State P0-P9.
**Role of this directory:** Project Hoomans adopter architecture, migration evidence and acceptance only.

## Hoomans objective

Adopt the shared PsychopatzCore social-state authority so Project Hoomans can preserve rich memories, directed relationships, hostility/grievance context, knowledge and social history without owning a second generic relationship/memory engine.

Project Hoomans remains responsible for its game-specific social rules: physical NPC context, conduct, faction policy, witness/world context, Hoomans-specific relationship semantics, knowledge adapters, and authoritative gameplay consequences.

Generic portable state useful to DynamicTrading, DTAbstract or future projects belongs in Core.

## Parent architecture

The portable system is:

    PsychopatzCore Actors / PsychopatzSocial
          |
          +-- stable actor identity
          +-- sparse directed relationship
          +-- bounded social memory
          +-- retention / consolidation
          +-- provenance / revisions
          +-- portable social projections
          +-- CodeBuilder Social Policy IR/runtime plans
          |
          +-------------+----------------+
          |                              |
          v                              v
    Project Hoomans               DynamicTrading / DTAbstract
    rich gameplay adopter         trader/abstract adopter

This avoids the split where Hoomans owns one social history and abstract traders own another.

## Hoomans outcomes

When adoption is complete:

- Hoomans SocialEvents can project generic portable social consequences exactly once into Core;
- Hoomans-specific Conduct, faction, Knowledge, romance/companion or physical-world policy remains Hoomans-owned where genuinely product-specific;
- generic directed relationship/history is not written independently in both Core and Hoomans;
- Hoomans Unified Semantic Evidence and Social Conversation Director consume bounded social projections;
- scene/short/long/anchor retention and consolidation are available through Core;
- NPC-to-player and NPC-to-NPC history survives actor representation changes;
- future Event/Opportunity Director and advertisement-based autonomy can consume bounded Hoomans/Core social context without raw-store access;
- no LLM is required for social state or behavior authority.

## Existing authorities to preserve

This participant must reuse rather than replace:

- Core Actors/PsychopatzSocial as portable generic authority;
- existing Hoomans SocialEvent, RelationshipService, Conduct and Knowledge behavior until migration ownership is proven;
- UnifiedSemanticEvidenceArchitecture as bounded semantic evidence projection;
- SemanticSocialConversationDirector as conversation consumer;
- canonical CodeBuilder-owned semantic source and generated artifacts.

P0/H0 must determine exact overlap before any writer is removed.

## Relationship to future emergent autonomy

The future loop remains:

    world/domain state
      -> World Signals
      -> Event / Opportunity Director
      -> Advertisement / Affordance providers
      -> NPC Autonomy Resolver
      -> Task / Action authority
      -> authoritative events
      -> Core social state + Hoomans domain consequences
      -> future decisions

The Event Director creates pressure/opportunity, not scripted NPC behavior. Memory creates motives/features, not commands.

## Non-goals

- no Hoomans-owned replacement for PsychopatzSocial;
- no second semantic evidence database;
- no transcript persistence;
- no dense actor relationship matrix;
- no per-memory OnTick decay;
- no Event Director implementation in this participant job;
- no advertisement/utility brain implementation here;
- no LLM dependency;
- no native Project Zomboid launch or Workshop publication for developer acceptance.

## Read order

1. root AGENTS.md;
2. Core parent README/ARCHITECTURE/ROADMAP;
3. this README;
4. ARCHITECTURE.md;
5. AGENT_RUNBOOK.md;
6. ROADMAP.md;
7. HARNESS_ACCEPTANCE.md;
8. PROGRESS.md.
