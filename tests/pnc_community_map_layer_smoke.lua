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
package.preload["PNC/UI/PNC_NPCTypePalette"] =
    function() return true end
package.preload["PNC/UI/Factions/PNC_FactionEmblemRenderer"] =
    function() return true end

local registered
local sent
local markerBlocksBase = false
local emblemDraw
PNC = {
    WorldDiscoveryDebugMap = { ShowRawEntities = true },
    FactionEmblemRenderer = {
        Draw = function(target, emblem, x, y, size, options)
            emblemDraw = {
                target = target,
                emblem = emblem,
                x = x,
                y = y,
                size = size,
                options = options,
            }
            return true
        end,
    },
    NPCTypePalette = {
        Get = function(typeID)
            local colors = {
                dead = { r = 0.55, g = 0.55, b = 0.55 },
                neutral = { r = 0.95, g = 0.75, b = 0.20 },
                hostile = { r = 1.00, g = 0.25, b = 0.20 },
                colonist = { r = 0.08, g = 0.42, b = 0.16 },
                follower = { r = 0.15, g = 0.90, b = 0.25 },
            }
            return colors[typeID] or colors.neutral
        end,
    },
    MapTravelLayer = {
        FindMarkerAt = function()
            return markerBlocksBase and { id = "npc_hover" }
                or nil
        end,
    },
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
        UI_PNC_CommunityMapAtWar =
            "At war with your faction",
        UI_PNC_CommunityMapPopulation = "Population",
        UI_PNC_CommunityMapLeader = "Leader",
        UI_PNC_CommunityMapCollapsed =
            "Collapsed / unoccupied",
        UI_PNC_CommunityMapRelation = "Relation",
    }
    return values[key] or key
end
function getTextManager()
    return {
        MeasureStringX = function(_, _, value)
            return #tostring(value) * 7
        end,
        getFontHeight = function() return 14 end,
    }
end

dofile(
    "Contents/mods/ProjectHoomans/42.20/media/lua/client/"
        .. "PNC/UI/Map/Layers/PNC_MapLayer_Communities.lua"
)

assertEqual(registered.id, "pnc_community_sites",
    "community layer registered")
assertEqual(registered.definition.order, 90,
    "community layer remains below NPC dots")

local lineCount = 0
local label
local popupLines = {}
local rectangles = {}
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
    drawRect = function(_, ...)
        rectangles[#rectangles + 1] = { ... }
    end,
    drawRectBorder = function() end,
    drawText = function(_, value)
        popupLines[#popupLines + 1] = value
    end,
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
local vacantMarker = rectangles[1]
assertEqual(vacantMarker[6], 0.55,
    "collapsed site uses dead gray palette")

-- Active enemy communities use the same hostile red as NPC map markers.
local state = PNC.Network.ClientState.communityDebug
state.communities[1].status = "active"
state.communities[1].currentPopulation = 4
state.communities[1].populationCapacity = 12
state.communities[1].factionID = "faction_enemy"
state.sites[1].status = "occupied"
state.factionRelations = {
    faction_enemy = {
        state = "war",
        atWar = true,
        allied = false,
        emblem = {
            backgroundColorID = "red",
            layers = {},
        },
        leaderName = "Mara Vance",
    },
}
map.getMouseX = function() return 15 end
rectangles = {}
popupLines = {}
registered.definition.render(map)
assertEqual(rectangles[1][6], 1,
    "enemy base uses hostile red palette")
assertEqual(popupLines[2], "Leader: Mara Vance",
    "base hover identifies the faction leader")
assertEqual(popupLines[4], "At war with your faction",
    "base edge hover reports faction war status")
assertTrue(emblemDraw ~= nil,
    "base hover renders the faction emblem")
assertEqual(emblemDraw.target, map,
    "hover emblem renders on the map")
assertEqual(emblemDraw.size, 52,
    "hover emblem uses the enlarged left panel")

-- NPC marker hit-testing always wins over the base-outline hover card.
markerBlocksBase = true
popupLines = {}
registered.definition.render(map)
assertEqual(#popupLines, 0,
    "base hover card suppressed over NPC marker")
markerBlocksBase = false
state.sites[1].status = "vacant"

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
