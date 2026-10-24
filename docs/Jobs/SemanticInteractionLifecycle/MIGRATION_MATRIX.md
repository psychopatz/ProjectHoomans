# Migration Matrix — Legacy Flavor to Semantic Lifecycle

This matrix is the required scope inventory. P0 must verify and expand it from current source before runtime migration.

| Family | Current verified/known owner | Target | Retirement rule |
| --- | --- | --- | --- |
| Conversation greeting | semantic greeting flow already exists; other greeting/social presentation paths also exist | conversation-open lifecycle act -> existing semantic greeting flow/response plan | remove duplicate text-generation owner only after parity |
| Conversation farewell | PNC_ConversationFarewell + SocialFlavor definitions/context | conversation-close lifecycle act -> semantic farewell flow/plan | preserve close eligibility/cooldown behavior; retire duplicate farewell prose authority after parity |
| Vanilla/player emote replies | Conversation/Flavor/VanillaEmote translations + command/social flavor adapters | typed semantic gesture act -> common response planning/realization | migrate authored lines as seed variants; no separate emote intelligence |
| Companion command/social emotes | PNC_CompanionCommandFlavorDefinitions_Typed* and related presentation | typed semantic act/capability result -> realization | keep gameplay command authority outside semantics |
| Combat reactions | SocialFlavor/event definitions such as witnessed player kill | grounded world/combat event -> semantic REACT act | event owner remains Combat; flavor prose owner retires after parity |
| Medical/hurt/downed reactions | SocialFlavor + FlavorTextResolver + medical/social adapters | grounded Health/Combat fact -> semantic reaction | Health/Combat remain authoritative |
| Gift/social reaction speech | existing gift/social event paths | authoritative result -> semantic reaction/realization | no duplicate gift/inventory state |
| World/faction/gossip reactions | mixed current event/gossip providers | canonical shared fact/event ref -> semantic reaction | integrate existing gossip/world-event ownership; no duplicate world history |
| Compatibility flavor | Bandits/Necroa/other compatibility adapters | adapter emits typed semantic event when safe | addon/provider remains owner of source fact |
| Contextual reply buttons | current semantic suggestion/provider/branch offer system | unchanged shared semantic-frame path | extend with active beat/thread context; do not add callback execution |
| Typed Talk/headless input | current NLU/router | unchanged NLU -> semantic act | preserve parser/candidate compatibility |
| ConversationBlocks | authored graph registry and server authority | preserve graph/effects; optional common realization later | never replace branching/effects with spontaneous flavor |
| TTS / nameplate / conversation presentation | existing presentation/audio queues | consume common realized output | presentation remains presentation; no semantic ownership |

## Migration rules

1. Do not delete existing flavor content before the corresponding semantic path demonstrates behavioral parity and regression coverage.
2. Existing authored lines are valuable content and should be migrated as realization variants where semantically valid.
3. Do not copy old role buckets mechanically if better authoritative ActorConversationContext already exists.
4. Semantic IDs describe meaning, not every wording variant.
5. Player and NPC realizations may differ, but they use the same semantic lifecycle and context owners.
6. Known events enter after NLU.
7. No migration may bypass server gameplay authority.
8. No phase is complete merely because source strings moved directories; actual production routing must use the new path.

## P0 required inventory fields

For every discovered legacy speech family, record:

- stable family/event ID;
- source files;
- trigger owner;
- speaker/target;
- current context inputs;
- current text pool/translation source;
- current presentation/TTS route;
- relationship/gameplay effects, if any;
- cooldown/chance/dedupe behavior;
- multiplayer authority;
- target semantic act/topic/event type;
- migration phase;
- parity tests/harness scenario;
- retirement status.

