# P11M — Production Relationship Proposal Integration

**Status:** ACTIVE / mandatory developer-side completion phase  
**Opened:** 2026-10-23  
**Implementation baseline audited:** ProjectHoomans remote `main` at `c9385c4f2b1b86feb09ed24144896e473bd6fec8`.  
**Native Project Zomboid SP/MP:** remains user-owned and untested.

## Why P11M exists

P11A-P11H and the later P11I-P11L follow-ups implemented substantial real infrastructure:

- actor-centric Player/NPC/Relationship/World workbench;
- first-class Player/NPC needs and production trait/profile projection;
- durable automatic friend promotion;
- server-authoritative romance proposal policy and `friend -> lover` transition;
- relationship preview and Compare;
- semantic Flow / Hub / ConversationBlock runtime graphs;
- modular speech realization;
- deterministic identity/backstory/flavour projection work;
- native Talk parity harness surfaces;
- Core deterministic content bridge audit.

However, the 2026-10-23 source audit found one remaining relationship-product gap:

> `PNC.Relationships.Propose(...)` exists as a real server service and the Semantic Lab worker can call it, but normal gameplay does not yet expose a production semantic/dialogue action that lets the player actually propose to an eligible NPC.

The current harness path is therefore stronger than the normal player path.

P11M closes that gap without creating a second romance system.

## Existing foundation to reuse

Do not replace or duplicate:

- `PNC.RelationshipProposalPolicy`;
- `PNC.Relationships.EvaluateProposal`;
- `PNC.Relationships.Propose`;
- durable bond persistence on the existing directed relationship record;
- existing gender/orientation/social-profile compatibility;
- Player traits such as Gay/Bisexual and NPC romance/social profile;
- existing DialogueChoiceRegistry/provider normalization;
- `semantic_click_frame` execution;
- DialogueInput routing;
- existing server request/authority conventions;
- EN/TL translation manager;
- existing SpeechRealization families.

The missing work is the **production proposal entry route**, not the policy.

---

# 1. Product behavior

When and only when the current actor pair is eligible to propose, normal conversation should expose one canonical semantic avenue such as:

```text
Tell them how you feel
```

or another reviewed localized phrase.

The semantic action remains canonical and language-independent:

```text
RELATIONSHIP_PROPOSAL
```

Do not create male/female/gay/straight-specific action IDs.

Conceptual production flow:

```text
current conversation context
    ↓
relationship proposal provider
    ↓
Relationships.EvaluateProposal(...)
    ↓
eligible candidate
    ↓
localized label / utterance
    ↓
semantic_click_frame
    ↓
DialogueInput / normal client request seam
    ↓
server authority
    ↓
Relationships.Propose(...)
    ↓
accept / reject
    ↓
normal semantic response + relationship revision
```

The proposal must be available through normal gameplay conversation, not only through Semantic Lab's dedicated `relationship_proposal()` worker command.

---

# 2. Eligibility ownership

The provider/presentation layer may display a proposal choice only from the result of the existing proposal policy.

Do not reimplement thresholds in the provider.

The authoritative policy already owns:

- durable friend bond requirement;
- approval threshold;
- respect threshold;
- familiarity threshold;
- standing restriction;
- family exclusion;
- gender/orientation compatibility;
- actor availability;
- proposal cooldown.

The provider should consume a bounded evaluation/projection and fail closed when evaluation is unavailable.

## Click-time/server revalidation

Eligibility at menu-build time is not sufficient.

When the player clicks the proposal candidate, the server path must re-evaluate the authoritative relationship and compatibility state before mutation.

This protects against:

- stale approval/respect/familiarity;
- changed standing;
- changed cooldown;
- changed actor availability;
- changed relationship bond;
- stale identity/target binding.

A stale visible proposal must fail safely rather than promote lover.

---

# 3. Provider ownership

Prefer a dedicated relationship/social choice provider registered through the existing DialogueChoiceRegistry.

Conceptual candidate:

```lua
{
    id = "relationship.proposal",
    provider = "projecthoomans.relationship",
    rankClass = "CONTEXTUAL_SOCIAL",
    semanticFrame = {
        action = "RELATIONSHIP_PROPOSAL",
        ...
    },
}
```

Exact schema must match current canonical candidate/frame contracts.

Do not add one-off proposal logic directly into the Tk harness or a central suggestion switch if the provider boundary already supports it.

The proposal may participate in appropriate normal conversation/root/contextual surfaces and the What's Up hub only when that hub/provider membership is semantically appropriate. Do not force it into every hub invocation.

---

# 4. Production client/server route

Audit the existing normal client-to-server action conventions before implementation.

The selected proposal semantic frame should enter the existing DialogueInput / semantic action route and then reach a production-owned request/command boundary.

The server handler must invoke the same real relationship service:

```text
PNC.Relationships.Propose(...)
```

that the harness currently proves.

Do not let the client:

- calculate the final acceptance roll;
- assign lover bond;
- bypass proposal cooldown;
- mutate relationship ModData directly.

The server result should return enough bounded outcome information for normal dialogue presentation:

- accepted/rejected;
- reason;
- resulting durable bond class;
- cooldown state where appropriate;
- relationship revision/receipt as already supported by current action patterns.

Do not expose private internal random/seed data to ordinary player UI unless existing diagnostics policy allows it.

---

# 5. Semantic response behavior

The proposal should produce a natural NPC response through existing semantic response/realization infrastructure.

At minimum distinguish:

```text
accepted
rejected
no longer eligible / stale
```

Use EN/TL whole-phrase translation keys.

Do not build responses through concatenated translated fragments.

Acceptance response must not invent facts beyond the real result.

Rejection should not imply relationship destruction unless the service actually changed relationship values.

Where SpeechStyleContext is appropriate, the same semantic outcome may realize differently for:

- flirty;
- reserved;
- friendly;
- withdrawn;
- relationship tone;

while preserving the authoritative accept/reject result.

---

# 6. Normal UI and Semantic Lab parity

Semantic Lab must test the same production candidate/action route.

The existing dedicated `Propose relationship` harness button may remain as a low-level diagnostic shortcut, but it must not be the only proof.

Add/adjust harness coverage so an eligible scenario can:

```text
open normal semantic suggestions
 -> find relationship.proposal
 -> click normal semantic frame
 -> reach the same server proposal service
 -> observe accept/reject result
```

Compare the normal semantic-click route with the dedicated harness command and prove they converge on the same service/policy outcome.

---

# 7. Acceptance matrix

P11M must prove at least:

### Eligibility

- eligible high-standing friend exposes proposal candidate;
- below approval threshold hides/blocks it;
- below respect threshold hides/blocks it;
- below familiarity threshold hides/blocks it;
- rival/enemy standing hides/blocks it;
- family bond hides/blocks it;
- already lover hides/blocks it;
- proposal cooldown hides/blocks it;
- unavailable/dead actor hides/blocks it.

### Orientation compatibility

- straight-compatible pair;
- same-gender incompatible pair;
- Gay-trait compatible pair;
- Bisexual-trait compatible pair;
- NPC orientation incompatibility;
- no duplicate orientation-specific semantic IDs.

### Server authority

- normal semantic click reaches real server relationship service;
- server revalidates eligibility;
- accepted proposal persists lover bond;
- rejected proposal remains friend and creates cooldown;
- stale/replayed click cannot bypass state;
- duplicate click cannot create duplicate relationship events.

### Presentation

- EN proposal choice;
- TL proposal choice;
- accepted EN/TL responses;
- rejected EN/TL responses;
- stale/ineligible response is safe and understandable;
- no private profile/roll leakage in normal choice labels.

### Harness parity

- normal candidate click and direct diagnostic command use the same underlying proposal policy/service;
- relationship preview remains non-persisted;
- graph/trace shows the semantic action/result without introducing a second action path.

---

# 8. Tests and validation

Focused developer validation should include:

- dedicated Lua relationship-proposal service tests;
- semantic choice/provider tests;
- client/action request routing tests;
- server authority/revalidation tests;
- Semantic Lab real Lua worker candidate-click tests;
- Tk/Xvfb visible candidate/click/result test;
- EN/TL translation/catalog validation;
- stale/replay/duplicate-click regression;
- relationship persistence/migration regression;
- friend promotion regression;
- family exclusion regression;
- What's Up hub regression;
- Dynamic Trading provider regression where relevant;
- changed Lua `luac5.3 -p`;
- targeted/full Kahlua checks according to current repository policy;
- Python compilation;
- `git diff --check`.

Do not claim native Project Zomboid acceptance from harness tests.

---

# 9. After P11M

When P11M passes, developer-side P11 relationship work is complete.

The next gate is explicitly separate:

## User-owned native Project Zomboid validation

Native validation should cover, at minimum:

1. Project Zomboid starts with the matched ProjectHoomans/PsychopatzCore versions;
2. Core `WorldGenParams` / `SurvivorFactory` deterministic content bridge does not fail during real startup/runtime;
3. Talk parity surface behaves against actual live NPC targets;
4. high relationship values promote a real NPC to durable friend through normal gameplay;
5. eligible player sees the real proposal conversation choice;
6. proposal routes through normal gameplay and results in accept/reject correctly;
7. accepted proposal creates durable lover relationship;
8. rejection/cooldown behaves correctly;
9. no duplicate/ghost relationship state appears after save/reload;
10. normal dialogue/semantic UI remains usable.

This native validation is **user-owned evidence**, not another developer implementation phase.

Do not call it P11H. P11H is already recorded as the developer-side regression gate.

---

# Completion rule

P11M is complete only when the normal production conversation path can invoke the same authoritative proposal service already proven by the harness.

A server API plus a harness-only button is not sufficient.

After P11M passes:

```text
Developer-side P11: COMPLETE
Native Project Zomboid validation: UNTESTED / user-owned
```

Do not reopen unrelated P11A-L work unless a P11M regression proves it is necessary.
