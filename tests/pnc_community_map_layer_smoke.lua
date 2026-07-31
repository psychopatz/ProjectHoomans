local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected="
            .. tostring(expected) .. " actual="
            .. tostring(actual))
    end
end

local function assertTrue(value, label)
    assertEqual(value == true, true, label)
end

local lastContext
local originalCalls = 0

ISWorldMap = {
    onRightMouseUp = function()
        originalCalls = originalCalls + 1
        return "original"
    end,
}
ISContextMenu = {}
function ISContextMenu.get()
    local menu = { options = {} }
    function menu:addOption(name, target, callback)
        local option = {
            name = name,
            target = target,
            callback = callback,
        }
        self.options[#self.options + 1] = option
        return option
    end
    lastContext = menu
    return menu
end

package.preload["ISUI/Maps/ISWorldMap"] =
    function() return ISWorldMap end
package.preload["ISUI/ISContextMenu"] =
    function() return ISContextMenu end

local registered
local sent
PNC = {
    MapLayers = {
        Register = function(id, definition)
            registered = {
                id = id,
                definition = definition,
            }
            return true
        end,
    },
    MapCommands = { Active = false },
    MapDisplay = {
        AreBasesVisible = function() return true end,
    },
    CommunityDebugOverlay = {
        IsVisible = function() return true end,
        Update = function() return true end,
    },
    Network = {
        ClientState = {
            communityDebugAuthorized = true,
            communityDebug = {
                communities = {
                    {
                        id = "community_old",
                        name = "Old Mill Gang",
                        siteID = "community_site_radius_1",
                        status = "destroyed",
                        destroyedAt = 10,
                    },
                },
                sites = {
                    {
                        id = "community_site_radius_1",
                        kind = "radius",
                        status = "vacant",
                        home = {
                            x = 10,
                            y = 10,
                            z = 0,
                            radius = 5,
                        },
                        bounds = {
                            minX = 5,
                            minY = 5,
                            maxX = 15,
                            maxY = 15,
                        },
                    },
                },
            },
        },
    },
    Client = {
        SendDebug = function(action, payload)
            sent = { action = action, payload = payload }
            return true
        end,
    },
}

UIFont = { Small = "small" }
function getText(key)
    local values = {
        UI_PNC_CommunityClaimSite =
            "Claim Abandoned Hideout",
        UI_PNC_CommunityMapClaimed = "claimed",
        UI_PNC_CommunityMapUnoccupied =
            "Unoccupied hideout",
        UI_PNC_CommunityMapVacant = "vacant",
    }
    return values[key] or key
end

dofile(
    "Contents/mods/ProjectHoomans/42.20/media/lua/client/"
        .. "PNC/UI/Map/Layers/PNC_MapLayer_Communities.lua"
)

assertEqual(registered.id, "pnc_community_sites",
    "community layer registered")

local lineCount = 0
local label
local map = {
    width = 500,
    height = 500,
    playerNum = 0,
    mapAPI = {
        worldToUIX = function(_, x) return x end,
        worldToUIY = function(_, _, y) return y end,
        uiToWorldX = function(_, x) return x end,
        uiToWorldY = function(_, _, y) return y end,
    },
    javaObject = {
        DrawLine = function()
            lineCount = lineCount + 1
        end,
    },
    getMouseX = function() return 10 end,
    getMouseY = function() return 10 end,
    drawRect = function() end,
    drawTextCentre = function(_, value)
        label = value
    end,
    getAbsoluteX = function() return 0 end,
    getAbsoluteY = function() return 0 end,
}
setmetatable(map, { __index = ISWorldMap })

registered.definition.render(map)
assertEqual(lineCount, 32, "radius rendered")
assertEqual(label, "Old Mill Gang [vacant]",
    "community label rendered")

assertTrue(map:onRightMouseUp(10, 10),
    "vacant site consumes right click")
assertEqual(#lastContext.options, 1,
    "claim option created")
local option = lastContext.options[1]
option.callback(option.target)
assertEqual(sent.action, "community_debug_action",
    "claim uses guarded debug route")
assertEqual(sent.payload.communityAction, "claim_site",
    "claim action")
assertEqual(sent.payload.siteID,
    "community_site_radius_1", "claim site ID")

assertEqual(map:onRightMouseUp(100, 100), "original",
    "outside click delegates")
assertEqual(originalCalls, 1, "original called once")

print("pnc_community_map_layer_smoke: PASS")
