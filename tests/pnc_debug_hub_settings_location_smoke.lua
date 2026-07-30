local FILE =
    "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/"
    .. "Integrations/PNC_PsychopatzCoreDebug.lua"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual), 2)
    end
end

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
    Client = { CanUseDebug = function() return true end },
    Settings = { Toggle = function() end },
}

package.preload["PsychopatzCore/UI/PsychopatzDebugHubWindow"] =
    function() return PsychopatzCore.DebugHub end

dofile(FILE)

assert(tools["pnc.npcMonitor"], "NPC monitor debug tool missing")
assert(tools["pnc.relationships"],
    "relationship inspector debug tool missing")
assert(tools["pnc.factions"],
    "faction inspector debug tool missing")
assertEqual(tools["pnc.settings"], nil,
    "Project Hoomans settings remained in debug hub")

print("pnc_debug_hub_settings_location_smoke: ok")
