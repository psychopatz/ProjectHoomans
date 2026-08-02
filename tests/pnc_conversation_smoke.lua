local ROOT = "Contents/mods/ProjectHoomans/common/media/lua/client/"
local TRANSLATE_JSON =
    "Contents/mods/ProjectHoomans/common/media/lua/shared/Translate/EN/UI.json"
local CORE_TEXT =
    "../psychopatzCore/Contents/mods/PsychopatzCore/common/media/lua/client/"
    .. "PsychopatzCore/UI/Conversation/PsychopatzConversationText.lua"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual), 2)
    end
end

local registeredProvider
local opened
local translations = {}
local translationFile = assert(io.open(TRANSLATE_JSON, "r"))
local translationJSON = translationFile:read("*a")
translationFile:close()
for key, value in string.gmatch(
    translationJSON,
    '"([^"]+)"%s*:%s*"([^"]*)"'
) do
    translations[key] = value
end

PNC = {
    ContextHub = {
        RegisterProvider = function(provider) registeredProvider = provider end,
    },
}
PsychopatzCore = {
    Conversation = {
        History = {
            GetDay = function() return 7 end,
        },
        Open = function(spec)
            opened = spec
            return spec
        end,
    },
}
getText = function(key) return translations[key] or key end
getTexture = function(path) return path end
getGameTime = function()
    return {
        getTimeOfDay = function() return 21.5 end,
    }
end

dofile(CORE_TEXT)
dofile(ROOT .. "PNC/Conversation/PNC_ConversationTime.lua")
dofile(ROOT .. "PNC/Conversation/Content/PNC_ConversationRegistry.lua")
dofile(ROOT .. "PNC/Conversation/PNC_ConversationRelationship.lua")
dofile(ROOT .. "PNC/UI/PNC_NPCTypePalette.lua")
PNC.Conversation.Lifecycle = {
    Create = function()
        return { kind = "conversation_lifecycle" }
    end,
}

local relationships = { "FirstMeet", "Acquaintance", "Member", "Lover" }
local variants = { "Dawn", "Sunrise", "Sunset", "Dusk", "Twilight" }
local index
for index = 1, #variants do
    dofile(ROOT .. "PNC/Conversation/PortraitBackgrounds/PNC_Background"
        .. variants[index] .. ".lua")
end
local relationshipIndex
for relationshipIndex = 1, #relationships do
    local relationship = relationships[relationshipIndex]
    for index = 1, #variants do
        local variant = variants[index]
        dofile(ROOT .. "PNC/Conversation/Content/Greetings/" .. relationship
            .. "/greeting_" .. relationship .. variant .. ".lua")
    end
end
dofile(ROOT .. "PNC/Conversation/PNC_ConversationDefinition.lua")
dofile(ROOT .. "PNC/UI/Context/Providers/PNC_ContextProvider_Conversation.lua")

local originalStringLower = string.lower
local originalStringGsub = string.gsub
string.lower = nil
string.gsub = nil
assertEqual(
    PNC.Conversation.FormatRoleLabel("lead_scavenger"),
    "Lead Scavenger",
    "role label avoids unsupported Kahlua string callbacks"
)
string.lower = originalStringLower
string.gsub = originalStringGsub

local Time = PNC.Conversation.Time
assertEqual(Time.Resolve(4.9), "twilight", "twilight band")
assertEqual(Time.Resolve(5.0), "dawn", "dawn band")
assertEqual(Time.Resolve(6.5), "sunrise", "sunrise band")
assertEqual(Time.Resolve(12), "sunset", "sunset band")
assertEqual(Time.Resolve(18), "dusk", "dusk band")
assertEqual(Time.Resolve(21), "twilight", "night twilight band")
assertEqual(PNC.Conversation.Relationship.Resolve({}), "FirstMeet",
    "unknown NPC relationship")
assertEqual(PNC.Conversation.Relationship.Resolve({
    record = { recruited = true },
}), "Member", "recruited NPC relationship")
assertEqual(PNC.Conversation.Relationship.Resolve({
    record = {
        mapPresentation = {
            knownBy = { Tester = true },
        },
    },
}, {
    getUsername = function() return "Tester" end,
}), "Acquaintance", "known NPC relationship")

local entry = {
    id = "npc-12",
    name = "Morgan",
    zombie = { live = true },
    snapshot = {
        identitySeed = 42,
        isFemale = true,
        faction = "hostile",
        appearance = { hairModel = "Long" },
        equipmentSummary = { worn = { Hat = "Base.Hat" } },
        relationshipCategory = "Lover",
        organizationalFaction = {
            id = "faction_crossroads",
            name = "Crossroads Exchange",
            role = "trader",
            rank = "member",
            emblem = {
                backgroundColorID = "black",
                layers = {
                    {
                        symbolID = "map_star",
                        colorID = "white",
                    },
                },
            },
        },
    },
}
local definition = PNC.Conversation.BuildDefinition(entry, {}, "twilight")
assertEqual(definition.namespace, "ProjectHoomans", "history namespace")
assertEqual(definition.npcID, "npc-12", "history NPC id")
assertEqual(definition.character, entry.zombie, "live portrait target")
assertEqual(definition.backgroundID, "twilight", "portrait background")
assertEqual(definition.context.relationshipID,
    "Crossroads Exchange", "portrait faction name")
assertEqual(definition.context.timeID, "Trader",
    "portrait faction role")
assertEqual(
    definition.context.factionEmblem.backgroundColorID,
    "black",
    "portrait faction emblem"
)
assertEqual(definition.context.conversationRelationshipID,
    "Lover", "semantic relationship category")
assertEqual(definition.context.conversationTimeID,
    "twilight", "semantic conversation time")
assertEqual(definition.context.npcType, "hostile", "conversation NPC type")
assertEqual(definition.theme.accent.r, 1, "hostile conversation red")
assertEqual(definition.theme.accent.g, 0.25, "hostile palette matches map")
assertEqual(definition.lifecycle.kind, "conversation_lifecycle",
    "conversation safety lifecycle attached")
assertEqual(#definition.nodes.greeting.choices, 3,
    "hostile conversation includes dossier access")
assert(definition.nodes.greeting.npc.key:find("Lover_Twilight", 1, true),
    "time greeting selected")
assertEqual(
    PsychopatzCore.Conversation.Text.Resolve(definition.nodes.greeting.npc)
        ~= definition.nodes.greeting.npc.key,
    true,
    "greeting domain resolves instead of exposing its key"
)
local firstChoice = definition.nodes.greeting.choices[1]
assertEqual(
    PsychopatzCore.Conversation.Text.Resolve({ key = firstChoice.textKey }),
    "Ceasefire. Stand down for now.",
    "Build 42 UI.json ceasefire translation"
)
assertEqual(firstChoice.textDomain, nil, "no custom translation domain")

local hostileEntry = {
    id = "npc-hostile",
    name = "Aggressive NPC",
    snapshot = {
        faction = "hostile",
        hostility = { attackPlayers = true },
    },
}
local hostileDefinition = PNC.Conversation.BuildDefinition(
    hostileEntry, {}, "twilight"
)
assertEqual(hostileDefinition.context.allowHostileParley, true,
    "hostile conversation exposes parley context")
assertEqual(hostileDefinition.nodes.greeting.choices[1].id,
    "ceasefire", "hostile greeting starts with ceasefire choice")

local neutralDefinition = PNC.Conversation.BuildDefinition({
    id = "npc-neutral",
    name = "Neutral NPC",
    snapshot = { faction = "neutral" },
}, {}, "twilight")
assertEqual(#neutralDefinition.nodes.greeting.choices, 4,
    "neutral conversation includes dossier access")

local debugActions = {}
local openedLaboratoryFor
PNC.Client = {
    CanUseDebug = function() return true end,
    SendDebug = function(action, args)
        debugActions[#debugActions + 1] = {
            action = action,
            args = args,
        }
        return true
    end,
}
PNC.RelationshipPresentation = {
    GetDebugStandingPreset = function(standingID)
        return { label = standingID }
    end,
}
PNC.RelationshipDebugUI = {
    Open = function(npcID)
        openedLaboratoryFor = npcID
    end,
}
local debugDefinition = PNC.Conversation.BuildDefinition({
    id = "npc-debug",
    name = "Debug NPC",
    snapshot = { faction = "neutral" },
}, {}, "twilight")
assertEqual(#debugDefinition.nodes.greeting.choices, 5,
    "debug conversation exposes relationship tools")
assertEqual(#debugDefinition.nodes.debug_relationship.choices, 5,
    "debug relationship hub exposes every tool")
assertEqual(#debugDefinition.nodes.debug_synthetic_baseline.choices, 6,
    "debug synthetic baseline menu exposes every preset")
assertEqual(#debugDefinition.nodes.debug_social_events.choices, 6,
    "debug social event menu exposes every event")
debugDefinition.nodes.debug_relationship.choices[1].action()
assertEqual(openedLaboratoryFor, "npc-debug",
    "conversation debug opens selected NPC laboratory")
debugDefinition.nodes.debug_synthetic_baseline.choices[1].action()
assertEqual(debugActions[1].action, "relationship_debug_baseline",
    "conversation debug uses authoritative baseline action")
assertEqual(debugActions[1].args.observerNPCID, "npc-debug",
    "conversation debug baseline targets speaking NPC")
assertEqual(debugActions[1].args.targetKind, "current_player",
    "conversation debug baseline targets current player")
debugDefinition.nodes.debug_social_events.choices[1].action()
assertEqual(debugActions[2].action, "social_trigger_event",
    "conversation debug uses social event pipeline")
assertEqual(debugActions[2].args.eventType, "treated_wound",
    "conversation debug selects requested social event")

local totalGreetings = 0
for relationshipIndex = 1, #relationships do
    local relationship = relationships[relationshipIndex]
    for index = 1, #variants do
        local timeID = string.lower(variants[index])
        local bucket = PNC.Conversation.Content.greetings[relationship][timeID]
        assertEqual(#bucket.values, 5, relationship .. " " .. timeID .. " pool")
        totalGreetings = totalGreetings + #bucket.values
    end
end
assertEqual(totalGreetings, 100, "organized greeting bootstrap count")

assertEqual(registeredProvider.id, "conversation", "Talk provider registered")
local option
local menu = {
    addOption = function(_, label, target, callback)
        option = { label = label, callback = callback }
        return option
    end,
}
registeredProvider.addOptions(menu, entry, {})
assertEqual(option.label, "Talk", "Talk translation fallback")
option.callback()
assertEqual(opened.npcID, "npc-12", "Talk opens selected NPC")

print("pnc_conversation_smoke: ok")
