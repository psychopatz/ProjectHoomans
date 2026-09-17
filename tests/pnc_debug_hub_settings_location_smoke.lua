local T = require "tests/support/test"

local FILE =
    T.path("ProjectHoomans", "client", "PNC/")
    .. "Integrations/PNC_PsychopatzCoreDebug.lua"

local tools = {
    ["pnc.settings"] = { id = "pnc.settings" },
    ["pnc.communityOverlay"] = { id = "pnc.communityOverlay" },
    ["pnc.factionOverlay"] = { id = "pnc.factionOverlay" },
}
local translationRequests = {}

PsychopatzCore = {
    DebugHub = {
        RegisterTool = function(definition)
            tools[definition.id] = definition
            return definition
        end,
        UnregisterTool = function(id)
            tools[id] = nil
        end,
    },
}
PNC = {
    ConversationDebugUI = { Toggle = function() end },
    AudioDebugUI = { Toggle = function() end },
    NPCMonitor = { Toggle = function() end },
    UniqueNPCDebugUI = { Toggle = function() end },
    UniqueNPCEditorUI = { Toggle = function() end },
    CommunityDebugUI = { Toggle = function() end },
    ColonistUI = { OpenDebug = function() end },
    DirectorDebugUI = { Toggle = function() end },
    WorldEffectDebugUI = { Toggle = function() end },
    RelationshipDebugUI = { Toggle = function() end },
    KnowledgeDebugUI = { Open = function() end },
    NPCTraitDebugUI = { Toggle = function() end },
    FactionDebugUI = { Toggle = function() end },
    FactionDebugOverlay = { Toggle = function() end },
    Client = { CanUseDebug = function() return true end },
    Translation = {
        GetKey = function(key, fallback)
            translationRequests[key] = fallback
            return "[TL] " .. key
        end,
    },
    Settings = { Toggle = function() end },
}

package.preload["PsychopatzCore/UI/PsychopatzDebugHubWindow"] =
    function() return PsychopatzCore.DebugHub end

T.load(FILE)

local metadata = {
    { id = "pnc.conversations", name = "ConversationBlocks" },
    { id = "pnc.audio", name = "Audio" },
    { id = "pnc.playerAnimation", name = "PlayerAnimation" },
    { id = "pnc.npcMonitor", name = "NPCMonitor" },
    { id = "pnc.uniqueNPCs", name = "UniqueNPCRegistry" },
    { id = "pnc.uniqueNPCEditor", name = "UniqueNPCCreator" },
    { id = "pnc.communities", name = "CommunityInspector" },
    { id = "pnc.needs", name = "ColonistDebug" },
    { id = "pnc.abstractDirector", name = "WorldDirector" },
    { id = "pnc.worldEffects", name = "WorldEffects" },
    { id = "pnc.relationships", name = "RelationshipInspector" },
    { id = "pnc.knowledge", name = "KnowledgeLab" },
    { id = "pnc.npcTraits", name = "NPCTraitRegistry" },
    { id = "pnc.factions", name = "FactionInspector" },
}

for _, entry in ipairs(metadata) do
    local definition = T.truthy(tools[entry.id], entry.id .. " debug tool missing")
    local titleKey = "UI_PNC_DebugHub_" .. entry.name .. "_Title"
    local descriptionKey = "UI_PNC_DebugHub_" .. entry.name .. "_Description"
    T.equal(definition.title, "[TL] " .. titleKey,
        entry.id .. " title did not use the translation facade")
    T.equal(definition.description, "[TL] " .. descriptionKey,
        entry.id .. " subtitle did not use the translation facade")
    T.truthy(translationRequests[titleKey], titleKey .. " was not requested")
    T.truthy(translationRequests[descriptionKey],
        descriptionKey .. " was not requested")
end

T.truthy(tools["pnc.npcMonitor"], "NPC monitor debug tool missing")
T.truthy(tools["pnc.uniqueNPCs"], "unique NPC debug tool missing")
T.truthy(tools["pnc.relationships"],
    "relationship inspector debug tool missing")
T.truthy(tools["pnc.factions"],
    "faction inspector debug tool missing")
T.equal(tools["pnc.settings"], nil,
    "Project Hoomans settings remained in debug hub")
T.equal(tools["pnc.communityOverlay"], nil,
    "community overlay remained in debug hub")
T.equal(tools["pnc.factionOverlay"], nil,
    "faction overlay remained in debug hub")
T.finish("pnc_debug_hub_settings_location_smoke")

T.finish("pnc_debug_hub_settings_location_smoke")
