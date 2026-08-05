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
                    outcomes = {{
                        id = "answer",
                        weight = 100,
                        responseKey = "response.answer",
                        close = true,
                        effects = {{
                            type = "pnc:relationship",
                            familiarity = 1,
                        }},
                    }},
                },
            },
        },
    },
})
```

The corresponding JSON bundle is a flat string map:

```json
{
  "opening": "Anything you need, {npcName}?",
  "choice.ask": "Heard any local news?",
  "response.answer": "There was movement near the old warehouse.",
  "locked.unfamiliar": "You do not know each other well enough."
}
```

Use `GetVersion()` and `GetCapabilities()` before depending on optional
features. `GetCategory`, `GetBlock`, and list methods return copies; mutating
them never changes the canonical registry. `ValidateBlock` can validate content
before registration. Unregister and register again for a deliberate reload.

## Gates, effects, and repetition

Built-in gate IDs are `pnc:skill`, `pnc:trait`, `pnc:personality`,
`pnc:relationship`, `pnc:relationship_state`, `pnc:audience`, `pnc:time`, and
`pnc:history`. Composite gates use `all`, `any`, and `not`. Time gates use
`startHour` and `endHour`; a start later than the end wraps across midnight.
Choices default to hidden when gated; set `lockedMode = "disabled"` and provide
`lockedReasonKey` to display the translated reason.

Repeat policies accept `scope` (`pair`, `character`, `npc`, or `world`),
`cooldownHours`, and `maxUses`. They may be placed on blocks or choices.

Built-in effects are `pnc:none`, `pnc:relationship`, `pnc:memory`,
`pnc:knowledge_disclosure`, and `pnc:ceasefire`.
Relationship effects route through the existing authoritative relationship and
social-event service. Addon effects must provide separate `validate`, `apply`,
and `simulate` callbacks:

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
and simulate effects without networking, persistence, or live-state mutation.

The server revalidates the lease token, distance/danger state, registry
fingerprint, category, selected block, current node, choice, gates, history, and
outcome. Replayed request IDs are rejected and never apply an effect twice.
