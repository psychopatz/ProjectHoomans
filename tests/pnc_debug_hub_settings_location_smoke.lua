local T = require "tests/support/test"

local FILE =
    T.path("ProjectHoomans", "client", "PNC/")
    .. "Integrations/PNC_PsychopatzCoreDebug.lua"

local tools = {
    ["pnc.settings"] = { id = "pnc.settings" },
}

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
    NPCMonitor = { Toggle = function() end },
    RelationshipDebugUI = { Toggle = function() end },
    FactionDebugUI = { Toggle = function() end },
    FactionDebugOverlay = { Toggle = function() end },
    Client = { CanUseDebug = function() return true end },
    Settings = { Toggle = function() end },
}

package.preload["PsychopatzCore/UI/PsychopatzDebugHubWindow"] =
    function() return PsychopatzCore.DebugHub end

T.load(FILE)

T.truthy(tools["pnc.npcMonitor"], "NPC monitor debug tool missing")
T.truthy(tools["pnc.relationships"],
    "relationship inspector debug tool missing")
T.truthy(tools["pnc.factions"],
    "faction inspector debug tool missing")
T.truthy(tools["pnc.factionOverlay"],
    "faction diplomacy overlay debug tool missing")
T.equal(tools["pnc.settings"], nil,
    "Project Hoomans settings remained in debug hub")
T.finish("pnc_debug_hub_settings_location_smoke")

T.finish("pnc_debug_hub_settings_location_smoke")
