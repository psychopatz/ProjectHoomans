local ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/"

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local menu = { options = {} }
function menu:addOption(name, target, callback)
    local option = { name = name, target = target, callback = callback }
    self.options[#self.options + 1] = option
    return option
end

local originalCalls = 0
ISWorldMap = {
    onRightMouseUp = function()
        originalCalls = originalCalls + 1
        return "vanilla"
    end,
}
ISContextMenu = { get = function() return menu end }
package.preload["ISUI/Maps/ISWorldMap"] = function() return ISWorldMap end
package.preload["ISUI/ISContextMenu"] = function() return ISContextMenu end

local request
PNC = {
    Network = { ClientState = { communityDebug = {}, directorDebug = {} } },
    WorldDiscoveryTypes = {
        KIND_SETTLEMENT = "settlement",
        KIND_MOBILE_GROUP = "mobile_group",
    },
    Client = {
        CanUseDebug = function() return true end,
        RequestWorldDiscovery = function(action, args)
            request = { action = action, args = args }
            return true
        end,
        RequestCommunityDebug = function() return true end,
        RequestDirectorDebug = function() return true end,
    },
}
getText = function(key) return key end

dofile(ROOT .. "client/PNC/UI/Map/PNC_WorldDiscoveryDebugMap.lua")
local map = {
    playerNum = 0,
    mapAPI = {
        worldToUIX = function(_, x) return x end,
        worldToUIY = function(_, _, y) return y end,
    },
    getAbsoluteX = function() return 0 end,
    getAbsoluteY = function() return 0 end,
}
setmetatable(map, { __index = ISWorldMap })
equal(map:onRightMouseUp(10, 20), true,
    "PNC debug actions append to the vanilla map menu")
equal(originalCalls, 1, "vanilla map menu remains available")
equal(#menu.options, 4,
    "debug map offers settlement, group, all, and overlay actions")
equal(menu.options[3].name, "UI_PNC_DebugDiscoveryAllSignals",
    "discover-all action is visible anywhere on the map")
menu.options[3].callback(menu.options[3].target)
equal(request.action, "debug_discover_all",
    "discover-all uses the authoritative discovery command")
equal(request.args.scope, "all", "discover-all sends explicit scope")
equal(PNC.WorldDiscoveryDebugMap.ShowRawEntities, false,
    "undiscovered debug overlays start hidden")
menu.options[4].callback()
equal(PNC.WorldDiscoveryDebugMap.ShowRawEntities, true,
    "raw overlays require an explicit debug toggle")

print("pnc_world_discovery_debug_map_smoke: ok")
