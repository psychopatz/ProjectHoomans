# Semantic Interaction Lifecycle — Current Progress

**Updated:** 2026-10-24  
**Parent status:** ACTIVE — planning approved; no production migration has been claimed yet.  
**Accepted predecessor foundation:** Contextual Dialogue Persona & Choices P14 complete.  
**Current mandatory phase:** P0 — Migration inventory + performance/persistence baseline.  
**Audit baseline:** ProjectHoomans main at 6aa9493aa6df0a48b2dd148a247a742d8fb38e5d before this documentation commit.  
**Native Project Zomboid:** not required for developer execution; final user-owned acceptance only.

## Verified foundation

Current source already provides:

- semantic greeting flow and conditioned greeting response plans;
- typed/headless semantic input path;
- semantic shortcut/button re-entry through the existing Input.Submit route;
- response-plan branch offers;
- ActorConversationContext / SpeechStyleContext;
- production ResponseCatalog;
- save-backed real-Lua Semantic Lab;
- P14 production rehydration and layered social context.

Current source also still contains legacy separate speech authority including:

- PNC_ConversationFarewell + FarewellContext;
- SocialFlavor definitions for farewell and event reactions;
- VanillaEmote flavor translations;
- CompanionCommand flavor definitions;
- FlavorTextResolver and related spontaneous-social paths.

## Actual product gap

Project Hoomans does not yet have one lifecycle that:

- receives typed/button/emote/lifecycle/event semantic acts;
- preserves NPC-output semantic provenance;
- resolves replies against active beats/threads;
- suspends/compacts/resumes meaningful conversations across in-game time;
- promotes only important facts/commitments/memories;
- keeps pair persistence sparse and bounded in multiplayer;
- exposes lifecycle/memory budgets through the existing Semantic Lab.

## Exact Next Chunk — P0A

Perform the source-level migration and state-ownership inventory before changing runtime behavior.

Required deliverables:

1. enumerate all production flavor/spontaneous-speech families and their trigger/presentation/TTS/authority paths;
2. fill MIGRATION_MATRIX with the actual files and IDs, including duplicate greeting/emote paths;
3. map every persistent/read dependency to its authoritative owner;
4. record which paths currently create ModData/network state versus presentation-only output;
5. establish representative Semantic Lab baseline scenarios for:
   - greeting;
   - farewell;
   - one social emote;
   - one combat/event reaction;
   - typed contextual reply;
6. establish initial state-size/pair-count diagnostics available today, without inventing Python gameplay semantics;
7. add characterization tests only where required to make later migration safe.

**Do not implement the new thread/persistence model in P0A.**

## P0A completion gate

P0A is complete only when the migration inventory and baseline evidence are precise enough to answer for every first-wave family:

- what triggers it;
- who owns the underlying truth;
- how speech is currently selected;
- how it is presented;
- what state/effects it commits;
- what semantic target will replace it;
- how parity will be tested;
- when its legacy authority can be retired.

After P0A, continue directly to the next P0/P1 chunk without asking the user for another goal prompt.

