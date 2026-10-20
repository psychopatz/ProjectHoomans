# Hoomans Adoption — Core Portable NPC Conversation (C1–C6)

**2026-10-21: new cross-repo product goal; documentation-only, NOT implemented or tested in this update.** Authoritative Core goal: `psychopatzCore/Docs/portable_npc_conversation/` at initial docs commit `b6cb206f42e7e8a754fcca47a8908442c3fa27e1`. Read Core `ARCHITECTURE.md`, `MIGRATION_AND_HOTSWAP.md`, `HARNESS_ACCEPTANCE.md`, `ROADMAP.md`, `AGENT_RUNBOOK.md`, and `PROGRESS.md` LAST. Hoomans prior B0–B6/H0–H4/F1–F4/V1–V5 code and Semantic Lab harness remain the accepted developer foundation, not work to replace.

## Actual inspected adoption seams

- Current ProjectHoomans main prior docs: `be0bf4c4680b988c1890295fa496995c36f2d358`. `PNC_SemanticDialogueFlow_Greeting.lua` currently opens a node `await_thanks` accepting THANK only, even though its NPC can ask `How have you been?`; `PNC_SemanticDialogueFlow_Wellbeing.lua` separately recognizes INFORM self-wellbeing and QUESTION wellbeing. The screenshot failed to bind `im fine, how about you` and `why is it so?` to pending conversational context.
- Existing `PNC_SemanticDialogueContextState` already supports bounded turns, topic history, pending follow-ups and flow sessions; `PNC_SemanticDialogueLocalResponse_Questions.lua` contains truthful `npc.residence` known/unknown answers; `PNC_ConversationMemory_Backstories.lua` reconstructs seed-selected facts with stable pinned IDs and an LRU cache.
- `PNC_NPCKnowledgeService` and player-character UUID evidence/Dossier already exist. The `PNC.Persistence.CoreProvider` adapter maps Core actor projections into Hoomans records and a Core provider lease. Migrate reusable generic source truth into Core **without** wholesale copying Hoomans saved data into another persistent store.

## Hoomans responsibilities after Core extraction

1. Register Hoomans-specific semantic patterns/response pools/CodeBuilder interaction catalog as **adopter extensions** over Core generic conversation. Keep colony, companion orders, quest/offer, medical/needs, world state, gossip and gameplay/transaction command authority in Hoomans.
2. Adapt existing `PNC.Conversation.Memory` backstory stable seed IDs to the portable Core persona service; preserve existing authored extensions, unknown fields and original save data until idempotent versioned migration parity verified. Never reroll appearance/voice/history or store full biography.
3. Adapt Hoomans player-scoped Knowledge, relationship, Dossier and PBrainZ to the shared Core player-evidence policy, while preserving Hoomans-specific fact descriptors and server-only evidence mutation. No client/backstory truth leakage, no double writers. Hoomans Dossier reads authorized projections for each character rather than overwriting Core canonical facts.
4. Live shell/animation/combat/physical body lifecycle stays Hoomans-owned. Use existing Core body lease under `PNC.Persistence.CoreProvider`, preserving actorID across materialization/dematerialization. Physical `NEARBY` channel demands server proximity/capability authorization, not just a Core actor ID.
5. Keep the existing Semantic Lab Tk Studio, CodeBuilder/InteractionSpec, production Lua worker and actual generated EN/TL assets as THE authoring and testing surface for Core generic + Hoomans-specific interaction. Extend worker optional-module matrices; never build a Core replacement GUI or prove functionality solely via JSON/unit tests.
6. Verify screenshot exact transcript via the worker BEFORE behavior patches, then compound answer+reciprocal question and `why` antecedent regression; preserve genuine inventory, compliment, STAY, gift/quest authority, social, EN/TL and PBrainZ opt-in behavior.

## Boundaries and acceptance

Core-only must function WITHOUT Hoomans installed; Hoomans must add richer provider facts without becoming necessary for shared personal conversation. Native Project Zomboid SP/MP testing, Workshop publication and installing mods remain user-owned. No new Git branches or writing checked-in `GOAL_PROMPT.md`; existing `main` only, safe parallel-agent checks. Hoomans former V1–V5 ledger is historical developer acceptance only: new C1–C6 cross-mod goal is not yet accepted.
