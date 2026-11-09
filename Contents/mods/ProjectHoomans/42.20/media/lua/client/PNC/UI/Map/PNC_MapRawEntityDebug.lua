-- Hoomans-only map debug adapter.  Core owns discovery actions; Hoomans
-- contributes the raw undiscovered overlay toggle that depends on PNC layers.

PNC = PNC or {}
PNC.MapRawEntityDebug = PNC.MapRawEntityDebug or {}

local CoreMap = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldClient"
local ActorMap = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldActorMap"
local DebugMap = PNC.MapRawEntityDebug
local Hub = require "PsychopatzCore/UI/PsychopatzDebugHubRegistry"

DebugMap.ShowRawEntities = DebugMap.ShowRawEntities == true

local function text(key, fallback)
    local translation = PNC.Translation
    local value = translation and type(translation.GetKey) == "function"
        and translation.GetKey(key) or nil
    if value and value ~= "" and value ~= key then return value end
    return fallback or key
end

local function menuTitle()
    local label = text("UI_PNC_DebugDiscoveryRawLabel",
        "RAW HOOMANS OVERLAYS")
    return label .. (DebugMap.IsEnabled() and ": ON" or ": OFF")
end

local function canDebug()
    return PNC.Client
        and type(PNC.Client.CanUseDebug) == "function"
        and PNC.Client.CanUseDebug() == true
end

function DebugMap.IsEnabled()
    if CoreMap.IsDebugPresentationEnabled then
        return CoreMap.IsDebugPresentationEnabled()
    end
    return DebugMap.ShowRawEntities == true and canDebug()
end

function DebugMap.ToggleRawEntities()
    if not canDebug() then return false, "not_authorized" end
    local enabled = not DebugMap.IsEnabled()
    if CoreMap.SetDebugPresentationEnabled then
        local accepted, reason = CoreMap.SetDebugPresentationEnabled(enabled)
        if not accepted then return false, reason end
    end
    DebugMap.ShowRawEntities = enabled
    if DebugMap.ShowRawEntities and PNC.Client then
        if type(PNC.Client.RequestCommunityDebug) == "function" then
            PNC.Client.RequestCommunityDebug()
        end
        if type(PNC.Client.RequestDirectorDebug) == "function" then
            PNC.Client.RequestDirectorDebug()
        end
    end
    if ActorMap and type(ActorMap.InvalidateCache) == "function" then
        ActorMap.InvalidateCache()
    end
    return DebugMap.ShowRawEntities
end

if Hub and type(Hub.RegisterTool) == "function" then
    Hub.RegisterTool({
        id = "pnc.map.raw_entities",
        title = text("UI_PNC_DebugDiscoveryShowRaw",
            "Toggle raw Hoomans overlays"),
        description = text("UI_PNC_DebugDiscoveryRawHelp",
            "Toggle undiscovered Hoomans entity overlays."),
        source = "Project Hoomans",
        surface = "map",
        menuTitle = menuTitle,
        menuTooltip = function()
            return text("UI_PNC_DebugDiscoveryRawHelp",
                "Toggle undiscovered Hoomans entity overlays.")
        end,
        order = 80,
        available = canDebug,
        action = function() return DebugMap.ToggleRawEntities() end,
    })
end

return DebugMap
