# Conversation Block Extension API

Project Hoomans conversations separate reusable content from the Project
Zomboid Build 42.20 implementation:

- `common/media/lua/shared/PNC/Conversation/Definitions/` contains data-only
  registration modules shared by client and server.
- `common/media/conversation/<type>/<audience>/<language>/<bundle>.json`
  contains flat, modular text maps.
- `42.20/media/lua/` contains the registry, validation, selection, authority,
  persistence, UI, networking, text loader, and debugger implementations.

`EN` is mandatory. Other languages fall back to the matching English bundle.
Paths are explicit: the runtime does not recursively scan folders or generate a
Project Zomboid `Translate/EN/UI.json` file.

## Built-in module layout

Built-in conversation families are intentionally separate modules:

```text
common/media/lua/shared/PNC/Conversation/Definitions/
├── 00_PNC_ConversationDefinitions.lua       # require-only manifest
├── 01_PNC_ConversationDefinitionHelpers.lua # internal constructors
├── 10_PNC_ConversationCategories.lua
├── 20_PNC_ConversationGreetings.lua
├── 30_PNC_ConversationWhatsUp.lua
├── 40_PNC_ConversationWellbeing.lua
├── 50_PNC_ConversationSmallTalk.lua
├── 60_PNC_ConversationAskAbout.lua
├── 70_PNC_ConversationNeeds.lua
├── 80_PNC_ConversationTrade.lua
├── 90_PNC_ConversationWorkOrders.lua
├── 91_PNC_ConversationPersonal.lua
└── 92_PNC_ConversationRelationship.lua
```

Do not put a new family back into the manifest. Create one registration module
for that family and add one `require` line to the manifest. The special
`What's your name?` action is isolated in the Build 42.20
`PNC_ConversationIdentityChoice.lua` adapter because it calls the authoritative
knowledge service; it is not serializable block data.

The built-in `What's up?` family demonstrates the intended scalable pattern.
Its module declares a weighted topic pool, while each topic/audience pair owns
one JSON bundle such as
`common/media/conversation/whats_up/neutral/EN/local_activity.json`. The chosen
topic and its weighted outcomes are stable for the current world day. The
category has `oncePerDay = true`, so the same player-character/NPC pair can
commit only one `What's up?` conversation per world day.

## Add a conversation from another mod

1. Add Project Hoomans as a required mod dependency.
2. Create a shared bootstrap Lua file in your mod, for example
   `media/lua/shared/ExampleMod/Conversation/00_ExampleConversations.lua`.
3. Require the Project Hoomans shared initialization, register the category if
   it is yours, and then register each block.
4. Put English strings in an explicit modular JSON bundle. Never place these
   strings in `Translate/EN/UI.json`.
5. Add other languages at the identical path with a different language folder.
6. Open **PsychopatzCore DebugHub → PNC Conversation Blocks**, inspect the
   block, then run it in the sandbox GUI before testing against a live NPC.

Suggested addon layout:

```text
Contents/mods/ExampleMod/common/media/
├── lua/shared/ExampleMod/Conversation/
│   ├── 00_ExampleConversations.lua
│   └── ExampleConversation_LocalNews.lua
└── conversation/news/neutral/EN/local_news.json
```

Bootstrap manifest:

```lua
require "PNC/00_PNC_Init"
require "PNC/00_PNC_Conversation_Init"
require "ExampleMod/Conversation/ExampleConversation_LocalNews"
```

Register on both client and server from `shared`. Never register a block only
from `client` or only from `server`, because the registry fingerprints must
match for multiplayer authority checks.

## Registering content

Load the API from a shared Lua file and register categories before their blocks.
IDs must be stable and namespaced. Registrations reject duplicates, inline
functions, cycles, unknown handlers, and dangling node references.

```lua
local Conversations = PNC.API.Conversations

Conversations.RegisterCategory("examplemod:news", {
    ownerModID = "ExampleMod",
    labelKey = "category.news",
    order = 350,
    ["repeat"] = { scope = "pair", oncePerDay = true },
    textSource = {
        modID = "ExampleMod",
        pathPattern =
            "media/conversation/system/shared/{language}/categories.json",
        domain = "examplemod.system.categories",
    },
})

Conversations.RegisterBlock("examplemod:local_news", {
    schemaVersion = 1,
    ownerModID = "ExampleMod",
    category = "examplemod:news",
    audiences = { "neutral", "member" },
    priority = 0,
    weight = 100,
    textSource = {
        modID = "ExampleMod",
        pathPattern =
            "media/conversation/news/neutral/{language}/local_news.json",
        domain = "examplemod.news.neutral.local_news",
    },
    entryNode = "opening",
    ["repeat"] = { scope = "pair", cooldownHours = 12 },
    nodes = {
        opening = {
            textKey = "opening",
            choices = {
                {
                    id = "ask",
                    textKey = "choice.ask",
                    lockedMode = "disabled",
                    lockedReasonKey = "locked.unfamiliar",
                    gates = {{
                        type = "pnc:relationship",
                        axis = "familiarity",
                        operator = ">=",
                        value = 10,
                    }},
                    outcomes = {
                        {
                            id = "helpful_answer",
                            weight = 3,
                            responseKey = "response.answer.helpful",
                            next = "followup",
                            effects = {{
                                type = "pnc:relationship",
                                approval = 1,
                                familiarity = 1,
                            }},
                        },
                        {
                            id = "guarded_answer",
                            weight = 1,
                            responseKey = "response.answer.guarded",
                            next = "followup",
                            effects = {{
                                type = "pnc:relationship",
                                familiarity = 1,
                            }},
                        },
                    },
                },
            },
        },
        followup = {
            textKey = "followup",
            choices = {{
                id = "volunteer",
                textKey = "choice.volunteer",
                outcomes = {{
                    id = "accepted",
                    weight = 1,
                    responseKey = "response.volunteer",
                    next = "$root",
                    effects = {{
                        type = "pnc:relationship",
                        approval = 2,
                        respect = 1,
                    }},
                }},
            }},
        },
    },
})
```

The corresponding JSON bundle is a flat string map:

```json
{
  "opening": "Anything you need, {npcName}?",
  "choice.ask": "Heard any local news?",
  "response.answer.helpful": "There was movement near the old warehouse.",
  "response.answer.guarded": "I heard something, but I cannot confirm it.",
  "followup": "That's all I know. What will you do with it?",
  "choice.volunteer": "I'll check it carefully.",
  "response.volunteer": "Good. Come back before dark.",
  "locked.unfamiliar": "You do not know each other well enough."
}
```

Dialogue text may use `{playerName}`, `{playerFullName}`, `{playerFirstName}`,
`{playerLastName}`, `{npcName}`, `{npcFullName}`, `{npcFirstName}`, and
`{npcLastName}`. Name values resolve from the authoritative character and NPC
identity records. Until the observer knows that identity, every name form
resolves to the translated `identity.stranger` string instead of leaking the
hidden name. Learned NPC names are persisted by player-character UUID and are
rehydrated into both the knowledge and conversation-presentation caches during
bootstrap, so asking for a name is not repeated after restarting the save.

Use `GetVersion()` and `GetCapabilities()` before depending on optional
features. `GetCategory`, `GetBlock`, and list methods return copies; mutating
them never changes the canonical registry. `ValidateBlock` can validate content
before registration. Unregister and register again for a deliberate reload.

Outcomes normally use `next = "node_id"` for an authored node or `close = true`
for a terminal exchange. Project Hoomans also reserves `next = "$root"` to
return to the ordered category menu after the NPC response. Built-in subtopics
use this route, so choosing one does not end the whole conversation. `Goodbye`
and explicitly terminal outcomes still close it.

## Gates, effects, and repetition

Built-in gate IDs are `pnc:skill`, `pnc:trait`, `pnc:personality`,
`pnc:relationship`, `pnc:relationship_state`, `pnc:audience`, `pnc:time`, and
`pnc:history`. Composite gates use `all`, `any`, and `not`. Time gates use
`startHour` and `endHour`; a start later than the end wraps across midnight.
Choices default to hidden when gated; set `lockedMode = "disabled"` and provide
`lockedReasonKey` to display the translated reason.

Repeat policies accept `scope` (`pair`, `character`, `npc`, or `world`),
`cooldownHours`, `maxUses`, and `oncePerDay`. They may be placed on categories,
blocks, or choices. `oncePerDay` compares in-game world-day numbers, so it resets
at midnight instead of requiring 24 elapsed hours. Category policies are the
correct choice when a weighted topic pool must be usable only once as a whole;
putting the policy on each block would allow another block from the pool.

## Branching and deterministic randomization

Every outcome must specify exactly one of:

- `next = "node_id"` to continue deeper into the same block;
- `next = "$root"` to return to the category menu; or
- `close = true` for a genuinely terminal exchange.

Multiple outcomes on one choice form a weighted random table. `weight = 3`
versus `weight = 1` produces a 75/25 split. The roll does not touch Project
Zomboid's global RNG. It hashes world identity, character UUID, NPC ID, world
day, registry schema, block/node/choice IDs, and the committed history slot.
Reopening or aborting therefore cannot reroll the same encounter.

Branches may converge, diverge, or form intentional loops. Every `next` node is
validated during registration, so a misspelled destination quarantines only
that block. Prefer small named nodes (`opening`, `details`, `followup`,
`closing`) and keep all prose in JSON. Lua should describe graph structure,
weights, gates, and effects—not contain dialogue strings.

`priority` is evaluated before `weight`: only eligible blocks at the highest
priority participate in the category roll. Use equal priority for a randomized
topic pool and use weight to control frequency. Use a higher priority only when
one block must override the normal pool when its gates pass.

Built-in effects are `pnc:none`, `pnc:relationship`, `pnc:memory`,
`pnc:knowledge_disclosure`, and `pnc:ceasefire`.
Relationship effects route through the existing authoritative relationship and
social-event service. Conversation relationship effects may change only the
persistent directed `approval`, `respect`, and `familiarity` axes. They cannot
award morale or `ADMIRE`, `PITY`, `FEAR`, or `DESPISE` directly. The relationship
system derives those attitudes from the resulting Approval/Respect coordinates;
recruitment remains a separate authoritative evaluation. Addon effects must
provide separate `validate`, `apply`, and `simulate` callbacks:

```lua
Conversations.RegisterConditionHandler("examplemod:has_radio", {
    evaluate = function(context, gate)
        return ExampleMod.HasRadio(context.player), "radio_required"
    end,
})

Conversations.RegisterEffectHandler("examplemod:mark_report", {
    validate = function(context, effect)
        return type(effect.reportID) == "string", "report_id_required"
    end,
    apply = function(context, effect)
        return ExampleMod.MarkReport(context.characterUUID, effect.reportID)
    end,
    simulate = function(context, effect)
        return { reports = { [effect.reportID] = true } }
    end,
})
```

These callbacks run on both sides for prediction/inspection, but only the server
authoritatively applies effects. Third-party callbacks are the sole protected
failure boundary; blocks themselves remain serialization-safe data.

## Debugging and authority

Open PsychopatzCore DebugHub and select **PNC Conversation Blocks**. The tool can
search and filter blocks, browse node/choice/outcome trees, show schema and text
diagnostics, explain gates, inspect deterministic rolls, edit a cloned context,
and open the selected block's category in the real conversation GUI. The
sandbox is a navigable registry browser: it lists every valid registered block,
provides category/block/back navigation that is omitted from the dialogue log,
and reveals gated authored choices as disabled rows with their reasons. Terminal
outcomes loop back to the block browser so multiple graphs can be tested in one
session. It uses the normal portrait, translated dialogue, authored choices,
relationship quadrant, gate evaluation, deterministic outcomes, and cloned
Approval/Respect/Familiarity state. Its conversation history is memory-only and
its effects never use networking, persistence, an NPC lease, or live-state
mutation.

Every real conversation shutdown reaches the lifecycle with a reason such as
`goodbye`, `escape`, `missing_node:<id>`, a safety interruption, or an
`authored_outcome:<block>:<node>:<choice>:<outcome>` identifier. Build 42.20
writes that reason with the NPC and lease token to the PNC log. Authoritative
outcome routing is logged separately, including its block, choice, outcome,
next node, terminal flag, and close reason.

The server revalidates the lease token, distance/danger state, registry
fingerprint, category, selected block, current node, choice, gates, history, and
outcome. Replayed request IDs are rejected and never apply an effect twice.
