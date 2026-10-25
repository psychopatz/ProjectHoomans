# P11 — Legacy Semantic Authority Consolidation

**Opened:** 2026-10-25  
**Status:** MANDATORY — approved no-split-system correction.  
**Audit baseline:** ProjectHoomans main at `08fd989422fb79a0d068e6aab23bee5a2d116308`.  
**Product rule:** the finished system has one conversational intelligence pipeline.

## Why P11 exists

A source audit after P10 was opened found that P0–P9 successfully added semantic envelopes, thread/beat continuity, sparse persistence and provenance around many existing speech paths, but several old Flavor/SocialFlavor modules still decide conversational meaning before semantic metadata is attached.

Current hybrid pattern:

~~~text
legacy classifier / reply selector
    -> legacy flavor ID / wording family
    -> semantic envelope/provenance attached afterward
    -> presentation
~~~

Required pattern:

~~~text
authoritative game fact / player input
    -> semantic act + grounded context
    -> semantic response plan / realization selection
    -> exact realization payload
    -> localization / delivery / TTS / nameplate
~~~

P11 removes the remaining split.

## No-split-system invariant

> **There is exactly one conversational intelligence authority: the semantic system.**

### Above the authority line — semantics owns

- semantic act/topic;
- active beat/thread interpretation;
- reply meaning;
- response-family selection;
- relationship/persona/social-context interpretation for dialogue;
- audience/stance/need/grief conversational classification;
- semantic eligibility;
- response-plan selection;
- realization family and realization ID;
- contextual continuation offers;
- anti-repetition policy where it changes semantic realization selection.

### Gameplay domains still own truth

Semantics does not replace Relationships, Knowledge/disclosure, Faction/diplomacy, Health, Inventory, Tasks/orders, Quest/ConversationBlock effects, social-event transaction authority, or external provider truth. Those domains expose facts; semantics decides how facts are conversationally interpreted and realized.

### Below the authority line — retained Flavor/SocialFlavor may only

- load authored EN/TL realization content;
- format already-approved tokens;
- choose among meaning-equivalent wording variants inside an already-selected semantic realization family;
- enqueue bounded speech;
- deliver nameplate/conversation/TTS presentation;
- perform transport dedupe/TTL/priority that does not change meaning;
- provide narrow documented compatibility translation adapters.

It must not independently infer or choose semantic meaning.

## Verified remnants requiring migration

### Greeting

`PNC_SocialGreetingService_TryGreet.lua` still resolves NPC type, relationship tier, greeting state and `GreetingReplyFlavorID(...)` before creating/recording the semantic NPC-speech envelope. The lifecycle records the greeting, but legacy logic still chooses the realization family.

### Emotes

`PNC_VanillaEmoteInteractions.lua` still owns `ResolveNPCType`, `ResolveRelationshipTier`, `GreetingState`, `GreetingReplyFlavorID`, `ReplyFlavorID` and role/tier reply tables. Semantic Emote/NPCSpeech envelopes are created afterward.

### Farewell

`PNC_ConversationFarewell.lua` still resolves legacy social role/context and feeds `social.conversation_farewell` into role-conditioned SocialFlavor definitions. Timing/cooldown/close eligibility may remain as lifecycle/presentation policy, but response-family selection must move above the authority line.

### Combat / medical / leader-loss

`PNC_FlavorTextResolver.lua` still derives threat, audience, need, mercy/faint and grief/succession flavor classifications. Useful derivations should move/refactor into neutral semantic/context providers with authoritative inputs rather than remain Flavor-only response intelligence.

### Companion/social replies

Production presentation still contains direct `PNC.CompanionCommandFlavor.Resolve(...)` / SocialFlavor resolution after command outcomes. Command outcome remains gameplay authority, but conversational reply meaning and realization must be selected semantically first.

## Target boundary

~~~text
GAME / WORLD TRUTH
        |
        v
SEMANTIC ACT + CONTEXT
        |
        v
RESPONSE PLAN / FLOW
        |
        v
REALIZATION FAMILY + REALIZATION ID
        |
======== SEMANTIC AUTHORITY LINE ========
        |
        v
AUTHORED LOCALIZED CONTENT
        |
        v
DELIVERY / NAMEPLATE / UI / TTS
~~~

If replacing the speech renderer changes which conversational reaction is selected, the renderer still owns semantic intelligence and migration is incomplete.

## Migration policy

For each remaining legacy family:

1. identify authoritative game facts;
2. identify the legacy semantic decision;
3. expose the facts through existing ActorConversationContext/event context or a narrow semantic provider;
4. define/reuse semantic response plan and realization family;
5. migrate existing authored strings as realization content;
6. route callers through semantic selection first;
7. retain only rendering/transport below the boundary;
8. prove parity and contextual improvement;
9. retire/deprecate the old semantic decision API.

Do not delete authored content merely because its current file/API name says Flavor.

## P11 ordered chunks

### P11A — Remaining authority inventory

Audit every production use of `Flavor.Resolve`, SocialFlavor conditional selection, `ReplyFlavorID`, `GreetingReplyFlavorID`, `PNC.FlavorText`, direct role/audience/need/grief response selection and compatibility Flavor adapters.

Classify each as CONTENT_ONLY, PRESENTATION_ONLY, TRANSPORT_ONLY, COMPATIBILITY_ONLY, GAMEPLAY_DOMAIN_AUTHORITY, SEMANTIC_DECISION_AUTHORITY_MUST_MIGRATE, or DEAD_OBSOLETE.

**Gate:** no ambiguous Flavor/SocialFlavor production path remains unclassified.

### P11B — Canonical semantic realization boundary

Standardize/reuse the existing ResponseCatalog/ResponsePlan/ActorConversationContext path so a production caller receives the selected response plan plus realization family/ID before presentation.

No second semantic catalog. Deterministic offline path remains default. PBrainZ may realize/rephrase only after an approved semantic plan.

### P11C — Greeting + farewell

Move greeting and farewell response-family/realization selection to semantic flows/context. Preserve legitimate lifecycle timing/cooldown policy. Legacy greeting/farewell IDs may remain content aliases only.

### P11D — Emote + companion/social reply

Emote meaning enters directly as a semantic act. Active beat/thread context has first priority. Command outcomes remain gameplay-owned. Retire `ReplyFlavorID`/role-tier reply tables/direct command Flavor resolution as conversational decision authority.

### P11E — Combat / medical / distress / leader-loss

Move useful threat/audience/need/grief derivations into neutral semantic/context providers. Event reaction semantics are then selected by semantic response plans, not Flavor-only classifiers.

### P11F — Reduce SocialFlavor to backend

For migrated families, SocialFlavor definitions/queues may render exact selected realizations and handle localization, tokens, priority, TTL, dedupe and TTS/nameplate delivery. They may not choose stance, role, need, grief, response plan or realization family.

### P11G — Remove misleading/dead remnants + execution-doc hygiene

After dependency verification:

- remove/relocate unused duplicate harness modules;
- retire old semantic-decision APIs;
- root `AGENTS.md` must contain durable repository-wide policy only and must not carry the current goal, phase, Next Chunk, implementation progress, or superseded goal history;
- active execution state belongs in this job's `ROADMAP.md`/`PROGRESS.md` and the conversational ChatGPT `/goal` bootstrap;
- old READY/goal docs must be clearly historical/non-executable when they remain useful as job-local archaeology;
- historical checked-in `GOAL_PROMPT.md` files must remain renamed/moved so they cannot be mistaken for current marching orders.

### P11H — No-split-system acceptance

Prove semantic-first realization for greeting, farewell, emote replies, command acknowledgements, combat/medical/distress/leader-loss reactions; preserve EN/TL authored content; prove renderer substitution does not change semantic plan; preserve P10 native/harness parity; add guards against reintroducing legacy semantic decision authority.

## Relationship to P10

Both P10 and P11 are mandatory.

Recommended order:

~~~text
P10B–P10E production/native presentation seam
    -> P11A–P11F semantic-authority consolidation
    -> P10F–P10G UI/browser work as dependencies allow
    -> P11G repository hygiene
    -> P10H + P11H combined final acceptance
~~~

The project cannot return to READY FOR USER LIVE TEST until both pass.

## Completion rule

P0–P9 lifecycle/persistence work remains useful foundation, but prior claims that legacy flavor authority was fully retired are superseded.

Migration is complete only when semantic meaning and response selection have one owner and Flavor/SocialFlavor is strictly content/presentation/compatibility below that boundary.
