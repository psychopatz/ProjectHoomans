-- Hoomans-only map debug adapter.  Core owns discovery actions; Hoomans
-- contributes the raw undiscovered overlay toggle that depends on PNC layers.

PNC = PNC or {}
PNC.MapRawEntityDebug = PNC.MapRawEntityDebug or {}

local DebugMap = PNC.MapRawEntityDebug
local Menu = require "PsychopatzCore/UI/Map/PsychopatzMapToolsMenu"

DebugMap.ShowRawEntities = DebugMap.ShowRawEntities == true

local function text(key, fallback)
    local translation = PNC.Translation
    local value = translation and type(translation.GetKey) == "function"
        and translation.GetKey(key) or nil
    if value and value ~= "" and value ~= key then return value end
    return fallback or key
end

local function canDebug()
    return PNC.Client
        and type(PNC.Client.CanUseDebug) == "function"
        and PNC.Client.CanUseDebug() == true
end

function DebugMap.ToggleRawEntities()
    if not canDebug() then return false, "not_authorized" end
    DebugMap.ShowRawEntities = not DebugMap.ShowRawEntities
    if DebugMap.ShowRawEntities and PNC.Client then
        if type(PNC.Client.RequestCommunityDebug) == "function" then
            PNC.Client.RequestCommunityDebug()
        end
        if type(PNC.Client.RequestDirectorDebug) == "function" then
            PNC.Client.RequestDirectorDebug()
        end
    end
    if PNC.MapTravelLayer
        and type(PNC.MapTravelLayer.InvalidateEntryCache) == "function" then
        PNC.MapTravelLayer.InvalidateEntryCache()
    end
    if Menu.instance and type(Menu.instance.syncButtons) == "function" then
        Menu.instance:syncButtons()
    end
    return DebugMap.ShowRawEntities
end

if Menu and type(Menu.Register) == "function" then
    Menu.Register("ProjectHoomans:raw_entities", {
        order = 40,
        visible = canDebug,
        title = function()
            return text(
                DebugMap.ShowRawEntities
                    and "UI_PNC_DebugDiscoveryHideRaw"
                    or "UI_PNC_DebugDiscoveryShowRaw",
                DebugMap.ShowRawEntities
                    and "Hide raw Hoomans overlays"
                    or "Show raw Hoomans overlays"
            )
        end,
        tooltip = function()
            return text("UI_PNC_DebugDiscoveryRawHelp",
                "Toggle undiscovered Hoomans entity overlays.")
        end,
        onActivate = function()
            return DebugMap.ToggleRawEntities()
        end,
    })
end

return DebugMap
