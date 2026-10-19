> **Current evidence update (2026-10-19):** C0–C6 were subsequently recorded developer-accepted in the previous PROGRESS at commit `71162cb4f78cc4cd408a4a145486d5ebadc943c1` (archived in `HISTORY_C0_C6_20261019.md`). Any "PLANNED" status or "start after G3C" text below is **historical design language**, not the current Next Chunk. The active new workstream is Semantic Studio consolidation S0A in `PROGRESS.md`.

# Contextual Conversational Intelligence — stable design contract

**Status:** PLANNED; no new source or tests implemented by this documentation update. Start only after the current G3C quest gate has been accepted or explicitly reclassified with evidence. This subsystem extends existing Hoomans context and flow modules; it is NOT a second chatbot or replacement semantic engine.

## Product behavior

NPCs should support:
- **Follow-up meaning:** "What happened?" refers to a just-discussed injury/event, "How many?" asks for the focused quantity, "And him?" changes person, "What about tomorrow?" changes temporal constraint.
- **Dialogue acts:** INFORM, ANSWER, ASK_CLARIFICATION, ACKNOWLEDGE, OFFER, ACCEPT, REFUSE, EXPLAIN, CORRECT, REMIND, SUSPEND/RESUME; these are *planned typed communicative acts*, not necessarily new existing Core intents.
- **Agenda management:** open question, proposal, clarification or commitment; bounded topic stack; interruptions do not silently resolve an unrelated obligation; "never mind" cancels only a sufficiently resolved pending act.
- **Grounded knowledge and episodic continuity:** known injury, needs, game time/weather, relationship, quest status, actual inventory, observed event, and user/NPC promises persist ONLY when verified by the correct owner. The NPC states uncertainty otherwise.
- **Speaker/target isolation:** different player, NPC, conversation, faction and group participants cannot share a pending action or memory accidentally.
- **Response composition:** choice of dialogue act + grounded fact slots + relationship/personality tone + response pool/translation; optionally PBrainZ realizes words using the SAME authorized plan.
- **Safety:** wording can never bypass locks, resolve uncertain targets into commands, or create authoritative medical/item/quest/social effects.

## Audited reusable modules (remote branch b06533f9)

- `PNC_SemanticDialogueContextState.lua`: bounded 12 recent turns, 32 mentions, 8 focus entries, 8 flow sessions and 4 stack entries; currentTopic/previousTopic and one identity-specific pending exchange.
- `PNC_SemanticDialogueContextState_{Turns,Mentions,Snapshot}.lua`: recent-turn event records, entity mention provenance and bounded read-only snapshots.
- `PNC_SemanticContextResolver.lua`: salience/capability-aware pronoun scoring, reference ambiguity/threshold diagnostics.
- `PNC_SemanticDialogueReferenceResolver.lua`: existing reference-to-entity contextual resolution layer.
- `PNC_SemanticDialogueFlowKernel.lua`: session-local active/suspended flow tracking, Preview/Commit separation.
- `PNC_SemanticDialogueResponsePlan.lua`: bounded structured response plan (4 turns, 6 segments per turn at observed revision).
- `PNC_SemanticDialogueLocalResponse_Questions.lua`: specific wellbeing/relationship follow-up logic, showing the present system is mostly targeted rather than generalized.
- Existing Social/Relationship/Knowledge/Cognition/Gossip/Quest services already own respective canonical state.

**Gaps are in generalized conversational semantics, NOT a lack of any context:** no source-verified all-topic agenda of pending questions/proposals/corrections; generic causal/reason/quantity follow-up resolution; scoped durable user commitments linked to domain owners; flexible dialogue-act planning with evidence-backed slots; complete dataset-to-conversation-state compiler and UI trace. Those remain unaccepted.

## Proposed bounded conversation frame (schema design, not implemented API)

```text
Frame = {
  schemaVersion, worldOrSaveID, characterUUID, npcID, speakerID, addresseeID,
  conversationID, topic, focusRefs[], priorTopics[], lastDialogueAct,
  agenda: [
    {kind:"QUESTION|PROPOSAL|CLARIFICATION|COMMITMENT",
     id, owner, targetID, requiredSlots[], sourceFactRefs[],
     openedTurn, expiresAtOrTurn, status}
  ],
  pendingActionRef?, memoryRefs[], revision
}
```

- Keep *one* authoritative ContextState instance per existing owner/scope, not a parallel cache; extend it with a **bounded** agenda and referents. Keep its existing limits or justify measured alternatives; never copy full transcript into NPC ModData.
- Agenda entries have explicit origin, required slots, speaker/addressee, pending-quest ID and expiry. Resolve yes/no/it/there only against the compatible live entry; ambiguous or expired entry -> clarify or acknowledge inability, NEVER commit an action.
- A conversation-bound promise records a proposed dialogue intention. Durable promise/quest obligation requires actual acknowledgement/accepted authoritative domain event. Link IDs to sparse Knowledge/Quest/Cognition owner records; avoid an independent player-claim truth database.
- Reference/ellipsis resolver consumes actual Core candidate IR plus bounded context: classify utterance act → identify compatible agenda/focus → find evidence → validate thresholds and scope → output **resolution plus trace**; unresolved ambiguous cases are normal, not invented success.
- **Topic management:** push previous active topic only on meaningful interruption, prevent repeated duplicate pushes, cap stack and decay entries. Explicit resumption goes back only to an available, same-participants topic; abandonment and return preserve invariants. Reuse FlowKernel's existing suspended transitions.
- **Observed vs believed:** source provenance, freshness, subject and uncertainty matter. An NPC can describe rain it reasonably observes but must not know a distant unobserved zombie attack; player assertions are not authoritative world/quest truth.
- **Result planner:** produce bounded DialogueActPlan {act, topic, groundedFactRefs, uncertainty, responsePool, args, pendingUpdate?, authorizedActionRequest?}; rendering uses EN/TL ResponseCatalog/ResponsePlan; authorizedActionRequest is handed to existing dispatcher only after commit-side revalidation.
- **No fabricated story:** ungrounded "I fell near the gas station" is prohibited unless actual memory/evidence supports it. Ask clarifying question or say unknown when evidence absent.

## C0 first context vertical slice

Build a scripted but **real-worker** multi-turn scenario with verified NPC state: player asks wellbeing; NPC answers from real health/need mock; player asks "What happened?" (cause unknown => says unknown), "Do you need anything?", "How many?" (quantity only if defined), "I'll get some" (resolve item but don't autostart quest), switch to weather, return to earlier medical topic. Run variants with no cause/quantity, ambiguous multiple items, second NPC, second player, EN/TL and PBrainZ off. Record IR and actual context before/after, selected act/flow, evidence ref, response and effects. Use this baseline to pick one general-purpose implementation chunk, not a fresh series of manual sentence cases.

## Modularity + performance

Each concern lives in a small reusable Lua module on existing Hoomans boundary: conversational agenda/referents on ContextState spokes, pure dialogue-act/ellipsis resolver, plan selection, response realization, sparse event/commitment adapter, worker projection. One turn/event drives lookups; no per-tick scan or all-NPC corpus lookups. Build-time dataset compiler assists rule/slot/dialogue-state authoring; Lua runtime uses compact indexed deterministic definitions.

## Optional PBrainZ parity

PBrainZ receives a compact, nonauthoritative grounded plan, authorized fact references (not whole ModData or raw private history), current topic, relevant memory, pending act, and allowed actions. Its reply may rephrase but not create facts, invent quest status or override action authority. If provider is disabled/fails, deterministic planned response is complete and functional. Compare same scenario outcome for PBrainZ off/on, no double dispatch.
