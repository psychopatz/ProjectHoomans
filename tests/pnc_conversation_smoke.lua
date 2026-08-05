local SHARED = "Contents/mods/ProjectHoomans/42.20/media/lua/shared/"
local CLIENT = "Contents/mods/ProjectHoomans/42.20/media/lua/client/"
local COMMON_SHARED = "Contents/mods/ProjectHoomans/common/media/lua/shared/"
local COMMON_CLIENT = "Contents/mods/ProjectHoomans/common/media/lua/client/"
local CORE_TEXT = "../psychopatzCore/Contents/mods/PsychopatzCore/common/media/lua/client/"
    .. "PsychopatzCore/UI/Conversation/PsychopatzConversationText.lua"

package.path = SHARED .. "?.lua;" .. CLIENT .. "?.lua;"
    .. COMMON_SHARED .. "?.lua;" .. COMMON_CLIENT .. "?.lua;"
    .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual), 2)
    end
end

local function truth(value, label)
    if not value then error(label or "truth", 2) end
end

local opened
local registeredProvider
PNC = {
    ContextHub = {
        RegisterProvider = function(provider) registeredProvider = provider end,
    },
}
PsychopatzCore = {
    Conversation = {
        History = { GetDay = function() return 7 end },
        Open = function(spec) opened = spec return spec end,
    },
}
getText = function(key) return key end
getTexture = function(path) return path end
getModFileReader = function(modID, path)
    local candidates = {
        "Contents/mods/" .. tostring(modID) .. "/common/" .. path,
        "Contents/mods/" .. tostring(modID) .. "/42.20/" .. path,
    }
    local file
    for _, candidate in ipairs(candidates) do
        file = io.open(candidate, "r")
        if file then break end
    end
    if not file then return nil end
    return {
        readLine = function() return file:read("*l") end,
        close = function() file:close() end,
    }
end
getGameTime = function()
    return {
        getTimeOfDay = function() return 21.5 end,
        getWorldAgeHours = function() return 189.5 end,
    }
end

dofile(CORE_TEXT)
dofile(SHARED .. "PNC/Conversation/Blocks/PNC_ConversationRegistry.lua")
dofile(SHARED .. "PNC/Conversation/Blocks/PNC_ConversationRules.lua")
dofile(SHARED .. "PNC/Conversation/Blocks/PNC_ConversationSelector.lua")
dofile(COMMON_SHARED
    .. "PNC/Conversation/Definitions/00_PNC_ConversationDefinitions.lua")
dofile(SHARED .. "PNC/Conversation/Blocks/PNC_ConversationTextLoader.lua")
dofile(CLIENT .. "PNC/Knowledge/PNC_NPCIdentityPresentation.lua")
dofile(CLIENT .. "PNC/Conversation/PNC_ConversationTime.lua")
dofile(CLIENT .. "PNC/Conversation/PNC_ConversationBackgrounds.lua")
dofile(CLIENT .. "PNC/Conversation/PNC_ConversationRelationship.lua")
dofile(CLIENT .. "PNC/UI/PNC_NPCTypePalette.lua")
PNC.Conversation.Lifecycle = {
    Create = function() return { kind = "conversation_lifecycle" } end,
    RequestCeasefire = function() return true end,
}
for _, value in ipairs({ "Dawn", "Sunrise", "Sunset", "Dusk", "Twilight" }) do
    dofile(COMMON_CLIENT .. "PNC/Conversation/PortraitBackgrounds/PNC_Background"
        .. value .. ".lua")
end
dofile(CLIENT .. "PNC/Conversation/Blocks/PNC_ConversationComposer.lua")
dofile(CLIENT .. "PNC/Conversation/PNC_ConversationDefinition.lua")
dofile(CLIENT .. "PNC/Conversation/Debug/PNC_ConversationDebugModel.lua")
dofile(CLIENT .. "PNC/UI/Context/Providers/PNC_ContextProvider_Conversation.lua")

local Registry = PNC.Conversation.Registry
local Rules = PNC.Conversation.Rules
local Selector = PNC.Conversation.Selector
local Loader = PNC.Conversation.TextLoader

equal(#Registry.ListCategories(), 11, "built-in category count")
equal(#Registry.ListBlocks(), 42, "built-in block count")
equal(Registry.GetFingerprint(), Registry.GetFingerprint(),
    "registry fingerprint stable")
equal(#Registry.ListBlocks({ includeInvalid = true }), 42,
    "built-ins all validate")

for _, block in ipairs(Registry.ListBlocks()) do
    local ok, errors = Loader.EnsureSource(
        block.textSource,
        Registry.CollectTextKeys(block)
    )
    truth(ok, block.id .. " translation: "
        .. tostring(errors and errors[1]))
end
for _, category in ipairs(Registry.ListCategories()) do
    truth(Loader.EnsureSource(category.textSource, { category.labelKey }),
        category.id .. " category translation")
end

local decoded = assert(Loader.Decode(
    '{"plain":"value","escape":"line\\nnext","unicode":"\\u263a"}'
))
equal(decoded.escape, "line\nnext", "JSON escape")
truth(decoded.unicode ~= "", "JSON unicode")
equal(Loader.Decode('{"duplicate":"a","duplicate":"b"}'), nil,
    "duplicate JSON key rejected")
equal(Loader.Decode('{"notFlat":true}'), nil,
    "non-string JSON value rejected")

local Time = PNC.Conversation.Time
equal(Time.Resolve(4.9), "twilight", "twilight band")
equal(Time.Resolve(5), "dawn", "dawn band")
equal(Time.Resolve(6.5), "sunrise", "sunrise band")
equal(Time.Resolve(12), "sunset", "sunset band")
equal(Time.Resolve(18), "dusk", "dusk band")
equal(Time.Resolve(21), "twilight", "night band")

local selectionContext = {
    worldID = "world-a",
    characterUUID = "character-a",
    npcID = "npc-a",
    worldAgeHours = 5.5,
    hour = 5.5,
    relationshipState = "FirstMeet",
    relationship = {},
    audiences = { neutral = true, shared = true },
}
local first = Selector.SelectBlock("projecthoomans:greetings", selectionContext)
local reopened = Selector.SelectBlock("projecthoomans:greetings", selectionContext)
equal(first.id, "projecthoomans:greeting_firstmeet_dawn",
    "relationship/time-gated greeting")
equal(reopened.id, first.id, "reopen does not reroll")
selectionContext.worldAgeHours = selectionContext.worldAgeHours + 24
local nextDay = Selector.SelectBlock("projecthoomans:greetings", selectionContext)
equal(nextDay.id, first.id, "only eligible authored block remains stable")

truth(Rules.EvaluateGate({
    type = "pnc:skill", actor = "player", skill = "Aiming",
    operator = ">=", value = 3,
}, { playerSkills = { Aiming = 4 } }), "skill gate")
truth(Rules.EvaluateGate({
    type = "pnc:personality", actor = "npc", dimension = "bravery",
    operator = ">", value = 0.5,
}, { npcPersonality = { bravery = 0.8 } }), "personality gate")
truth(Rules.EvaluateGate({
    type = "pnc:time", startHour = 21, endHour = 5,
}, { hour = 23 }), "midnight wrap gate")
truth(Rules.EvaluateGate({
    type = "all",
    gates = {
        { type = "pnc:audience", value = "member" },
        { type = "not", gate = { type = "pnc:audience", value = "hostile" } },
    },
}, { audiences = { member = true } }), "composite gate")

local duplicateOK = Registry.RegisterCategory(
    "projecthoomans:whats_up",
    Registry.GetCategory("projecthoomans:whats_up")
)
equal(duplicateOK, false, "duplicate category rejected")
local unsafeOK = Registry.RegisterBlock("testmod:unsafe", {
    schemaVersion = 1,
    ownerModID = "testmod",
    category = "projecthoomans:whats_up",
    audiences = { "neutral" },
    textSource = {
        modID = "ProjectHoomans",
        pathPattern = "media/conversation/whats_up/neutral/{language}/basic.json",
        domain = "test.unsafe",
    },
    entryNode = "opening",
    callback = function() end,
    nodes = { opening = {} },
})
equal(unsafeOK, false, "inline callback quarantined")
truth(Registry.ListBlocks({ includeInvalid = true })[#Registry.ListBlocks({
    includeInvalid = true,
})].errors ~= nil, "invalid block visible to debugger")

local entry = {
    id = "npc-12",
    name = "Morgan",
    zombie = { live = true },
    snapshot = {
        identitySeed = 42,
        isFemale = true,
        faction = "neutral",
        relationshipCategory = "Acquaintance",
        organizationalFaction = {
            id = "crossroads", name = "Crossroads Exchange",
            role = "lead_scavenger",
            emblem = { backgroundColorID = "black", layers = {} },
        },
    },
}
local definition = PNC.Conversation.BuildDefinition(entry, {}, "dawn")
equal(definition.namespace, "ProjectHoomans", "history namespace")
equal(definition.npcID, "npc-12", "NPC id")
equal(definition.backgroundID, "dawn", "background definition")
equal(definition.context.relationshipID, "Crossroads Exchange",
    "faction subtitle")
equal(definition.context.timeID, "Lead Scavenger", "role subtitle")
equal(definition.context.conversationRelationshipID, "Acquaintance",
    "semantic relationship")
equal(definition.lifecycle.kind, "conversation_lifecycle", "lifecycle")
truth(#definition.nodes.greeting.choices >= 8,
    "registered category menu composed")
local greeting = PsychopatzCore.Conversation.Text.Resolve(
    definition.nodes.greeting.npc
)
truth(string.find(greeting, "dawn", 1, true)
    or string.find(greeting, "light", 1, true)
    or string.find(greeting, "early", 1, true),
    "modular greeting resolves")

local hostile = PNC.Conversation.BuildDefinition({
    id = "hostile", name = "Hostile",
    snapshot = { faction = "hostile", hostility = { attackPlayers = true } },
}, {}, "twilight")
equal(hostile.context.allowHostileParley, true, "hostile parley context")
equal(hostile.nodes.greeting.choices[1].id, "ceasefire",
    "hostile block exposes ceasefire")

local debugContext = PNC.ConversationDebugModel.DefaultContext()
local before = debugContext.relationship.familiarity
local sandbox = assert(PNC.ConversationDebugModel.ExecuteSandbox(
    "projecthoomans:whats_up_basic_neutral",
    "opening", "situation", debugContext
))
equal(sandbox.persisted, false, "sandbox does not persist")
equal(sandbox.networked, false, "sandbox does not network")
equal(debugContext.relationship.familiarity, before,
    "sandbox does not mutate input")
equal(sandbox.after.relationship.familiarity, before + 1,
    "sandbox previews relationship delta")

truth(registeredProvider and registeredProvider.id == "conversation",
    "Talk context provider registered")
local option
registeredProvider.addOptions({
    addOption = function(_, label, target, callback)
        option = { label = label, callback = callback }
        return option
    end,
}, entry, {})
truth(option, "Talk option created")
option.callback()
equal(opened.npcID, "npc-12", "Talk opens selected NPC")

local ui = assert(io.open(
    "Contents/mods/ProjectHoomans/common/media/lua/shared/Translate/EN/UI.json",
    "r"
)):read("*a")
equal(string.find(ui, "UI_PNC_Conversation_", 1, true), nil,
    "conversation strings removed from UI.json")
equal(string.find(ui, "UI_PNC_Greeting_", 1, true), nil,
    "greeting strings removed from UI.json")

print("pnc_conversation_smoke: ok")
