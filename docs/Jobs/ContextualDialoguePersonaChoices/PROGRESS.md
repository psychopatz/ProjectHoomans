# Contextual Dialogue Persona & Choices — Current Progress

**Updated:** 2026-10-23  
**Parent status:** REOPENED — P9 mechanics are retained, but P10 product acceptance is mandatory.  
**Current mandatory phase:** P10A — Remove legacy What's Up category + establish semantic hub contract.  
**Implementation baseline audited:** ProjectHoomans remote `main` source at `86cbfb38bb7aa7d87608d9dd2963255c91244f87`.  
**Native Project Zomboid SP/MP:** UNTESTED / user-owned.

## Accepted foundation to preserve

P8/P9 delivered useful infrastructure that must not be discarded:

- production ActorConversationContext;
- friend/family/lover bond classes with detailed relationship kinds;
- production-derived relationship state in the Lab;
- persona-aware speech realization;
- generic DialogueChoiceRegistry/provider discovery;
- Dynamic Trading provider boundary;
- typed semantic click/stale/replay/privacy/authority paths;
- direct semantic-frame routing infrastructure;
- full ConversationBlock developer graph projection;
- shared Flow/Conversation graph canvas primitives;
- graph edge click parity with normal choice frames;
- EN/TL translation integration.

P10 changes the product composition above these foundations.

## 2026-10-23 live UI audit

User screenshots plus source inspection show the current P9 handoff is not product-complete.

### Simulation editing is still developer-internal

Current `tools/semantic_harness/ui/dialogs/settings.py`:

- renders hunger/thirst/fatigue/stress/boredom/panic/time/world age/zombie kills through generic text entries even where range/type is known;
- uses raw editable JSON as the default Player and NPC inventory UI;
- parses those editors with `json.loads()`;
- buries the real Persona sliders inside a modal;
- dynamically discovers only part of the UI schema;
- still has worker-side hard-coded option arrays such as roles.

Raw JSON must remain available, but normal state editing must become structured and catalog-driven.

### What's Up is still the wrong product model

P9 fixed the redundant second click, but current tests and code now intentionally require:

```text
input("whatsup")
 -> CONVERSATION_TOPIC
 -> projecthoomans:whats_up
 -> selected old authored ConversationBlock
 -> opening/detail/personal/followup/closing
```

The current test `test_specific_routes_remain_distinct_from_whats_up` explicitly keeps WELLBEING, ACTIVITY and GOSSIP separate from What's Up.

That conflicts with the approved product direction.

What's Up should be a contextual semantic **hub** exposing eligible avenues such as:

```text
Are you okay?
Do you need anything?
Are you hurt?
What have you been doing?
Heard any gossip?
What's happening nearby?
relationship-specific social avenues
Dynamic Trading-owned avenues
quest/commitment avenues
```

filtered/ranked for the actual character/context.

## Mandatory legacy removal decision

Do not preserve the old authored What's Up implementation as a hidden fallback.

P10 must remove live production use of:

```text
projecthoomans:whats_up
conversation.whats_up
projecthoomans:whats_up_*
```

Known references include category definitions, `30_PNC_ConversationWhatsUp.lua`, SemanticTopicCatalog, dataset/compiler patterns, generated patterns, static suggestion definitions, worker helpers, category translations and tests.

Useful old prose may be re-authored under the correct semantic provider/response owner with new IDs, but the old What's Up namespace and category must not survive as compatibility architecture.

## Current Exact Next Chunk — P10A

On the user's actual local checkout:

1. read root `AGENTS.md` and all current ContextualDialoguePersonaChoices docs in documented order, including `SEMANTIC_SIMULATION_UX_AND_CONTEXTUAL_HUB.md`;
2. inspect local branch/HEAD/upstream/divergence/dirty/concurrent work in ProjectHoomans and relevant sibling repos; existing `main` only;
3. inventory every live source/test/generated/content reference to:
   - `projecthoomans:whats_up`;
   - `conversation.whats_up`;
   - `projecthoomans:whats_up_*`;
   - `category.whats_up`;
   - legacy What's Up compiler/category routing;
4. define the smallest canonical semantic-hub activation contract using the existing parser/IR/click/provider infrastructure;
5. change reviewed What's Up aliases so they emit hub activation rather than `conversation_category`;
6. remove old authored category registration and old What's Up block registration;
7. remove the static `conversation.whats_up` definition and central category-specific suggestion logic;
8. remove worker hard-coded category/preflight fallback code;
9. remove/update compiler constraints and generated sources so regeneration cannot recreate the legacy category;
10. remove orphaned legacy category translations after exact reference audit;
11. replace tests that require the old category/block IDs with hub-contract tests;
12. preserve explicit direct semantics:
    - explicit wellbeing questions still parse as WELLBEING;
    - explicit gossip questions still parse as GOSSIP;
    - explicit activity/medical/needs questions remain their own semantics;
13. prove What's Up now activates a hub without selecting any ConversationBlock;
14. run focused source/reference absence checks, parser/compiler tests, worker tests, Lua syntax/Kahlua where affected, and `git diff --check`;
15. update this ledger with exact evidence and continue automatically to P10B if the gate passes.

## P10A acceptance

The real worker must prove:

```text
PLAYER: what's up?
 -> reviewed semantic recognition
 -> route = semantic_hub
 -> hubID = whats_up
 -> NO projecthoomans:whats_up category
 -> NO old ConversationBlock
 -> hub-ready suggestion/provider projection
```

Repository/source checks must prove there is no live production registration or runtime dependency on the removed legacy identifiers.

Historical docs may mention those identifiers as superseded evidence; production/codegen/runtime/test acceptance must not depend on them.

## Ordered remaining P10 milestones

After P10A continue autonomously:

- **P10B:** contextual provider-driven What's Up hub MVP;
- **P10C:** typed Simulation Control Catalog and dynamic world/persona controls;
- **P10D:** structured inventory editor with preserved Advanced JSON;
- **P10E:** inline Simulation workbench and Apply + Replay;
- **P10F:** hub diagnostics and completed graph history;
- **P10G:** final usability/regression gate.

See `SEMANTIC_SIMULATION_UX_AND_CONTEXTUAL_HUB.md` for the full contracts.

## Early user-test checkpoint

Do not wait until P10G to make the interface useful.

After P10C, the user should already be able to:

```text
launch Semantic Lab
 -> adjust common world/persona/relationship values with typed controls
 -> type "What's up?"
 -> see several character/context-appropriate hub choices
 -> change a relevant dial
 -> Apply + Replay / rerun
 -> observe candidate set/order changes
```

P10D then removes raw JSON from the ordinary inventory workflow while preserving Advanced JSON.

## Handoff condition

Do not report **READY FOR USER LIVE TEST** again until P10A-P10G pass.

Native Project Zomboid SP/MP remains user-owned and must remain UNTESTED unless the user provides evidence.
