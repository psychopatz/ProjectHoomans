# Progress — Semantic Social Conversation Director

**Status:** DEVELOPER COMPLETE — D0-D8 accepted; READY FOR USER LIVE TEST.
**Branch:** existing `main` only.
**Planning anchor:** `56b77cf4eeae680cffac277fc416fe6591f95a82`.
**Goal-doc baseline:** `cc8898f30e9d0a054a87f315fadada4ab191e07c`.
**Current phase:** developer acceptance complete.
**Next authority:** user-owned native Project Zomboid SP/MP timing, readability, chatter-frequency and perceived-naturalness verification only. Reopen the smallest owning D-phase if native evidence contradicts an accepted invariant.

## Final developer outcome

The complete D0-D8 developer objective is implemented:

- the existing `projecthoomans.generated_affordances` provider remains the canonical semantic response vocabulary;
- player-facing generated choices retain their existing provider/candidate identity while the underlying responder projection is actor-neutral;
- autonomous NPCs consume semantic affordances directly through `collectForResponder`; they never simulate UI button clicks or reparse labels/rendered prose;
- recurrence/cooldown policy is responder-aware rather than hard-coded to player turns;
- one generic Semantic Social Director owns grounded social-opportunity admission, motives, opening speaker/recipient selection and chatter budgets above the existing Scene Runtime;
- one bounded NPC choice policy ranks valid affordances from motive, personality/disposition, directed relationship, capabilities and relevance, with silence as a first-class result;
- one bounded turn policy gives the explicit recipient ordinary reply priority, permits explicit interjection, selects at most one ordinary next speaker and prevents chorus/pairwise-scene explosion;
- player observer/participant/addressee roles remain distinct; addressed players resume the same Scene through the existing player semantic-response path and NPC group conversation may continue afterward;
- production post-combat, task/work, grounded WorldKnowledge, community-excursion and hostile/raider cases all use the same generic Social Director + Scene Runtime;
- ordinary autonomous chatter is transient and non-mutating, while mapped consequential NPC hostility is handed exactly once to the existing SocialEvent/Conduct/Relationship authority through NPC-specific event types;
- the Scene/Social Observatory exposes bounded read-only motive/admission/participant/speaker/affordance/choice/budget/continuation diagnostics without transcript text;
- stress/extensibility acceptance proves repeated low-value suppression, urgent-event serviceability, the existing global Scene cap, four participants in one Scene, and a synthetic fourth social domain through public seams;
- generic Social Director code introduces no per-NPC tick, full registry/faction scan, global zombie scan, routine LLM path, transcript persistence or rendered-text reparsing.

## D0-D1 — Actor-neutral affordance foundation

Implemented:
- `PNC_SemanticAffordanceResponder.lua`;
- actor-neutral responder name/traits/speaker/recipient/visibility projection;
- responder-aware recurrence;
- `GeneratedAffordanceProvider.collectForResponder(context, responder)`;
- legacy player provider ID, candidate IDs, visibility and player-trait provenance preserved;
- identity disclosure uses responder identity;
- NPC and player responders consume the same bounded semantic frontier.

Focused actor-neutral/continuation tests are included in the final full suite.

## D2-D5 — Social Director, NPC choice, group turns and chatter budgets

Implemented under `shared/PNC/Semantics/SemanticSocial/`:
- `PNC_SemanticSocialDirector.lua`;
- `PNC_SemanticSocialChoicePolicy.lua`;
- `PNC_SemanticSocialTurnPolicy.lua`;
- `PNC_SemanticSocialBudget.lua`;
- `PNC_SemanticSocialConversation.lua`.

Accepted behavior:
- motives include INFORM/WARN/REQUEST/CHECK/ACKNOWLEDGE/REACT/SOCIALIZE/DISPUTE/REPAIR/COORDINATE/SILENCE;
- low relevance can intentionally produce no scene/no response;
- actor, pair, topic and local-area budgets suppress repetitive chatter;
- urgent semantic opportunities can bypass ambient chatter throttles but never the existing global Scene Runtime capacity;
- personality/relationship-sensitive ranking and explicit silence are deterministic and inspectable;
- 2-, 3- and 4-actor group turns remain one Scene with at most one ordinary next speaker.

## D6 — Production adopters

Accepted production paths:
- post-combat decompression from authoritative horde/encounter transitions;
- task assignment/completion from existing Tasking events;
- grounded WorldKnowledge disclosure/follow-up, with unknown facts rejected;
- community excursion phase updates through existing excursion listeners;
- same-faction raider/hostile-role NPCs converse with no participating or observing player required.

These adopters submit grounded opportunities; they do not own a second conversation scheduler or mutate their source gameplay domains.

## D7 — Player interop and social consequences

Accepted:
- observer-only players receive no response authority merely by overhearing;
- NPC -> player Scene turns enter the existing `wait_player` contract;
- player semantic input resumes the exact Scene;
- eligible third NPCs can explicitly rejoin after player response without duplicating Scene state;
- shared SocialConversation exposes an optional consequence sink only after a semantic act successfully enters the Scene;
- server `PNC_SemanticSocialConsequenceService.lua` maps only supported hostile NPC acts to NPC-specific SocialEvent types;
- `npc_dialogue_hostile_remark`, `npc_dialogue_insult` and `npc_dialogue_threat` are owned by existing SocialEvent/Conduct/Relationship services;
- a real SocialEvent transaction proves an autonomous NPC insult changes the target NPC's directed relationship, records exactly one NPC-specific relationship memory and conduct evidence, and deduplicates replay;
- ordinary acts such as ACKNOWLEDGE do not fabricate relationship mutations.

The generic conversation layer never writes relationship/faction/task values directly.

## D8 — Extensibility, Observatory, scale and final acceptance

### Lua

Final isolated repository suite:
- **956/956 PASS**.

Focused Social/affordance suite after consequence integration:
- **12/12 PASS**.

Production adopter / SocialEvent / Conduct / interaction-registry matrix after NPC consequence integration:
- **7/7 PASS**.

### Real Semantic Harness worker

`test_semantic_scene_observatory` + `test_coherent_conversation_c8`:
- **11/11 PASS**.

Changed harness Python:
- `py_compile`: **PASS**.

### CodeBuilder / content

Two consecutive manifest-backed Conversation generations:
- **192 generated files**;
- **500 phrase families**;
- **54 patterns**;
- **10 UI definitions**;
- byte-identical aggregate hash both runs:
  `11aec932b55f67ea742c2fb084e1393172c3e8544c708fbda3572be14e5a7d6d`.

Generated EN/TL Social Conversation content remains CodeBuilder-owned rather than hand-patched downstream.

### Installed Project Zomboid Kahlua compiler

Using the installed Build 42 compiler under:
`/home/psychopatz/.steam/debian-installation/steamapps/common/ProjectZomboid/projectzomboid`

Result:
- **132 semantic Lua files checked**;
- **PASS / 0 failures**;
- game launched: **false**;
- Lua executed: **false**;
- source writes: **0**.

### Static/performance/persistence

- `git diff --check`: PASS;
- no `Events.OnTick` social polling;
- no `Registry.ForEachLive` social scan;
- no global zombie scan;
- no rendered-text semantic reparsing;
- no Social Director ModData/transcript persistence;
- no routine autonomous LLM opt-in.

### Stress/extensibility evidence

- 20 repeated low-value opportunities -> 1 admitted, 19 chatter-budget suppressed;
- 20 explicit high-priority/budget-bypassed opportunities -> 16 accepted, 4 rejected by the existing global Scene ceiling;
- four participants remain one Scene;
- urgent grounded opportunity remains serviceable despite ambient chatter saturation;
- a synthetic future FACTION_EVENT/REPAIR social domain adopts through public Social Director/Scene/affordance seams without generic algorithm special-casing;
- Observatory remains read-only and stores no transcript.

## Known pre-existing unrelated harness failure

The C10 mutation-matrix case `unsafe_item_typo` for `give me waterr` currently expects transport count 0 but observes 1 while still producing the safe `ASK_CLARIFICATION` / `unresolved_action_reference` result.

This exact failure was reproduced from a clean archive of the pre-implementation goal-doc commit `cc8898f3`; it is not caused by the Social Conversation Director implementation and was not broadened into this goal.

## Native handoff

No native Project Zomboid interaction was driven for developer acceptance.

User-owned SP/MP verification should focus on:
- whether ambient NPC conversations occur at a believable frequency rather than feeling noisy;
- whether multi-NPC turn-taking is readable and never becomes a chorus;
- companions, settlement NPCs, neutral groups and hostile/raider teams sounding distinct because of their real personality/relationship/context rather than separate engines;
- player overhearing without unwanted buttons;
- addressed-player handoff and NPC group resumption after the player responds;
- post-combat, task, knowledge and excursion conversations referring only to grounded events;
- hostile NPC dialogue consequences feeling proportionate and not being applied twice;
- no noticeable hitching, scene spam or abnormal save growth.

If native evidence fails, use the Social/Scene Observatory to reopen only the smallest owning layer: affordance frontier, choice policy, turn policy, chatter budget, adopter, player handoff, consequence bridge or presentation.

## Safety

No new Git branch, Workshop publication, destructive Git operation, native-game automation, routine LLM chatter path, autonomous transcript store, feature-specific parallel conversation engine or global NPC polling loop was used for developer acceptance.
