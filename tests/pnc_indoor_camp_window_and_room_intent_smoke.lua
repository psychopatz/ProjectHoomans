local T = require "tests/support/test"

local SHARED = T.path("ProjectHoomans", "shared", "PNC/Core/Pathing/")
local SERVER = T.path("ProjectHoomans", "server", "PNC/World/")

function isClient() return false end
function isServer() return true end

PNC = {
    Const = {},
    Core = {
        Now = function() return 10000 end,
        LogInfo = function() end,
        LogWarn = function() end,
    },
}

T.load(SHARED .. "PNC_TraversalQuery.lua")

-- 1. Indoor NPC moving to an indoor goal MUST NOT climb out an exterior window
local extWindow = { id = "ext_win", smashWindow = function() end, isGlassRemoved = function() return false end }
local function mkSq(x, y, z, outside, winTo)
    return {
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return z end,
        isOutside = function() return outside == true end,
        isSolid = function() return false end,
        isSolidTrans = function() return false end,
        isFree = function() return true end,
        getDoorTo = function() return nil end,
        getWindowTo = function(_, other) return winTo and winTo(other) or nil end,
    }
end

local sqIndoorFrom = mkSq(10, 10, 0, false, function(o) return o:getX() == 11 and extWindow or nil end)
local sqOutsideLawn = mkSq(11, 10, 0, true)
local sqIndoorGoal = mkSq(14, 10, 0, false)
local sqOutsideGoal = mkSq(14, 12, 0, true)

local cell = {
    getGridSquare = function(_, x, y)
        if x == 10 and y == 10 then return sqIndoorFrom end
        if x == 11 and y == 10 then return sqOutsideLawn end
        if x == 14 and y == 10 then return sqIndoorGoal end
        if x == 14 and y == 12 then return sqOutsideGoal end
        return nil
    end,
}
local actor = { getX = function() return 10.5 end, getY = function() return 10.5 end, getZ = function() return 0 end }

local blockedExit = PNC.TraversalQuery.FindPassageToward(actor, 14.5, 10.5, 0, cell)
T.equal(blockedExit, nil, "indoor actor with indoor goal never climbs out an exterior window")

local allowedExit = PNC.TraversalQuery.FindPassageToward(actor, 14.5, 12.5, 0, cell)
T.truthy(allowedExit and allowedExit.object.id == "ext_win", "indoor actor with outdoor goal can still exit through window")

-- 2. Unified CampZoneService.ResolveActivityRoom (eat->kitchen, sleep->bedroom, chitchat->living, drink->water)
PNC.CampZoneService = {
    Internal = {
        number = function(v, fb) return tonumber(v) or fb end,
        siteDistanceSq = function(a, b)
            local dx = (a.x or 0) - (b.x or 0)
            local dy = (a.y or 0) - (b.y or 0)
            return dx * dx + dy * dy
        end,
    },
}
T.load(SERVER .. "PNC_CampZoneService_Assignment.lua")

local buildingDir = {
    rootSite = { siteID = "hall", x = 10, y = 10, z = 0 },
    zones = {
        { siteID = "room_kitchen", roomType = "KITCHEN", x = 12, y = 10, z = 0, capabilities = { food = true, water = true, social = true } },
        { siteID = "room_bedroom", roomType = "BEDROOM", x = 14, y = 10, z = 0, capabilities = { sleep = true } },
        { siteID = "room_living", roomType = "LIVING_ROOM", x = 11, y = 12, z = 0, capabilities = { social = true, seating = true } },
    },
}

-- Preserves one-by-one camp entry loop: does not trigger while queued/moving
local queuedNpc = { id = "c1", orderSpec = { placementState = "queued" } }
local qRoom, qReason = PNC.CampZoneService.ResolveActivityRoom(queuedNpc, "eat", { directory = buildingDir })
T.equal(qRoom, nil, "does not interrupt queued camp room entry")
T.equal(qReason, "camp_entry_in_progress", "reports camp_entry_in_progress")

-- Settled neutral or camping colonist routes by activity intent inside the same building
local settledNpc = { id = "n1", orderSpec = { placementState = "arrived" } }
local eatRoom = PNC.CampZoneService.ResolveActivityRoom(settledNpc, "eat", { directory = buildingDir })
local sleepRoom = PNC.CampZoneService.ResolveActivityRoom(settledNpc, "sleep", { directory = buildingDir })
local chatRoom = PNC.CampZoneService.ResolveActivityRoom(settledNpc, "chitchat", { directory = buildingDir })
local drinkRoom = PNC.CampZoneService.ResolveActivityRoom(settledNpc, "drink", { directory = buildingDir })

T.equal(eatRoom.siteID, "room_kitchen", "eating routes to kitchen")
T.equal(sleepRoom.siteID, "room_bedroom", "sleeping routes to bedroom")
T.equal(chatRoom.siteID, "room_living", "chitchat/relax routes to living room")
T.equal(drinkRoom.siteID, "room_kitchen", "drinking routes to room with live clean water faucet")

-- After water shutoff (no room has capabilities.water == true), drinking cleanly returns nil
buildingDir.zones[1].capabilities.water = false
local dryRoom, dryReason = PNC.CampZoneService.ResolveActivityRoom(settledNpc, "drink", { directory = buildingDir })
T.equal(dryRoom, nil, "does not send NPC to dry faucet when building has no water")
T.equal(dryReason, "no_water_in_building", "reports no_water_in_building")

T.finish("pnc_indoor_camp_window_and_room_intent_smoke")
