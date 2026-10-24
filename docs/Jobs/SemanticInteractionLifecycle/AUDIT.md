# Source Audit — Semantic Interaction Lifecycle

**Audit date:** 2026-10-24  
**Remote baseline:** ProjectHoomans main at 6aa9493aa6df0a48b2dd148a247a742d8fb38e5d.  
**Evidence scope:** current GitHub source/docs plus the accepted P14 ledger. No native Project Zomboid run is claimed.

## Executive verdict

The requested architecture is feasible without replacing the current semantic stack.

Project Hoomans already has the difficult foundations:

- production typed semantic input and candidate routing;
- registered semantic dialogue flows with suspend/resume behavior;
- conditioned ResponseCatalog selection;
- response plans with contextual branch offers;
- semantic buttons that can re-enter the same raw semantic route as typed input;
- ActorConversationContext / SpeechStyleContext;
- real-Lua Semantic Lab execution;
- P14 save-backed production rehydration and layered personal/faction/tactical/conversation context.

The primary gap is lifecycle unification. Legacy spontaneous speech still bypasses that semantic architecture, and there is no compact multi-day thread/memory lifecycle designed for sparse multiplayer persistence.

## Verified current paths

### Semantic greeting foundation already exists

PNC_SemanticDialogueFlow_Greeting.lua owns a modular GREET flow with:

- a registered trigger;
- contextual constraints;
- bounded follow-up state;
- semantic branch offers;
- unrelated-turn suspension;
- response-pool ownership.

PNC_SemanticDialogueResponseCatalog_FlowGreeting.lua already shows the desired realization direction: semantic response pools choose context-conditioned wording and can emit a multi-turn response plan with follow-up offers.

This is the pilot to extend, not a system to replace.

### Farewell still has separate legacy intelligence

PNC_ConversationFarewell.lua currently owns its own:

- close-reason eligibility;
- chance roll;
- cooldown;
- timer/pending queue;
- manual farewell context construction;
- direct player SocialFlavor resolution;
- delayed NPC SocialFlavor enqueue.

PNC_SocialFlavorDefinitions_GroupA.lua owns social.conversation_farewell wording and separate relationship-role variants.

Target: preserve useful close eligibility/cooldown behavior, but move speech meaning and realization behind the semantic lifecycle.

### Event-trigger reactions still use flavor pools

PNC_SocialFlavorDefinitions_GroupA.lua contains spontaneous reactions such as witnessed player kill and teammate hurt.

These events already originate from grounded game facts. Re-parsing invented text would be wrong. They should enter the semantic lifecycle as typed event/reaction acts after NLU.

### Emote and command reaction wording is duplicated

The current tree includes:

- Conversation/Flavor/VanillaEmote translations;
- PNC_CompanionCommandFlavorDefinitions_Typed*.lua;
- social flavor definitions and presentation adapters.

Examples include insult, thumbs-down, wave-hi, clap, salute, thanks and thumbs-up.

Target: one semantic gesture/action meaning with realization variants and contextual reaction planning. Existing authored lines are migration seed content, not disposable work.

### Typed input and semantic shortcuts already share an important seam

PNC_SemanticDialogueInput.lua currently routes semantic shortcut frames back through the ordinary Input.Submit path. This is the right invariant for buttons: presentation may differ, but semantic handling/authority stays shared.

The new lifecycle should generalize the same principle across typed input, emotes, headless input and known events.

### Response selection already supports bounded contextual fields

The ResponseCatalog already evaluates a bounded condition context including topic, previous action, relationship state, time/weather, activity, needs, health, social style and other semantic/situation state.

The new lifecycle should feed it better thread/beat/event context rather than creating a second response engine.

### P14 is the correct persistence/runtime foundation

Contextual Dialogue Persona & Choices PROGRESS records P14 accepted:

- production persistence deserialization/normalization happens in Lua;
- save-backed actor inventory/faction/social state is rehydrated through real owners;
- hostile tactical/faction context stays distinct from absent personal relationship;
- Semantic Lab can operate on an isolated mutable world while keeping source saves immutable.

This job must keep the rule: **fixture the engine, never fixture the mod**.

## Missing architecture

The current system does not yet provide one production contract for:

- semantic interaction envelopes from typed text, buttons, emotes, lifecycle events and world events;
- NPC-generated speech carrying its original semantic act/beat metadata for later player replies;
- active/suspended/archived pair threads;
- bounded semantic-turn compaction;
- open questions/commitments that survive UI close or time passage;
- explicit memory promotion and forgetting;
- lazy emotional residue/expiry;
- sparse player/NPC pair state;
- shared world-event references;
- bounded multiplayer replication;
- memory/persistence budget diagnostics and stress acceptance.

## Product risks if implemented naively

### Pair-state explosion

With multiple players and hundreds of NPCs, pre-allocating state for every possible pair creates Player × NPC scaling even when most pairs never interact.

Required fix: absence is the default. Pair state is materialized only after a meaningful durable delta.

### Transcript persistence

Saving rendered text creates large, language-dependent, duplicate state.

Required fix: render text ephemerally; persist compact semantic state only when meaningful.

### Per-tick decay / cleanup

Updating emotions, expiry and conversation memory continuously across all NPCs would make inactive characters expensive.

Required fix: timestamps + lazy decay/expiry on access, with bounded maintenance cleanup only.

### Duplicated shared events

Saving a faction death/helicopter/chopper/major incident independently on many NPCs multiplies world truth.

Required fix: canonical shared event record + per-NPC/player knowledge/memory reference.

### Harness-owned gameplay logic

Python reconstruction would invalidate production-parity evidence and repeat the problem P14 just fixed.

Required fix: Python discovers/transports/presents; production Lua owns semantic lifecycle, compaction, memory promotion and persistence.

## Conclusion

The next correct roadmap is not “add more flavor variants.” It is:

**unify spontaneous speech behind semantic acts → add bounded thread/beat continuity → compact/persist only meaningful deltas → prove sparse multiplayer scaling → retire duplicate flavor authority after parity.**

