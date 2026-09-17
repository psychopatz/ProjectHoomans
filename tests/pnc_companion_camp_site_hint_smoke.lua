local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
})

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local roomDefinition = {
    getIDString = function() return "test-room" end,
    getName = function() return "bedroom" end,
    getX = function() return 10 end,
    getY = function() return 10 end,
    getX2 = function() return 12 end,
    getY2 = function() return 12 end,
    getZ = function() return 0 end,
}
local room = {}
local building = {
    getID = function() return "test-building-runtime" end,
    getDef = function()
        return { getIDString = function() return "test-building" end }
    end,
    rooms = { room },
    isToxic = function() return false end,
    isResidential = function() return true end,
}
local roomSquare = {
    getX = function() return 10 end,
    getY = function() return 10 end,
    getZ = function() return 0 end,
    getRoom = function() return room end,
    isInARoom = function() return true end,
    isFree = function() return true end,
    getObjects = function() return {} end,
}
room.getRoomDef = function() return roomDefinition end
room.getBuilding = function() return building end
room.getSquares = function() return { roomSquare } end
room.getFreeTile = function() return roomSquare end

local campfire = {
    getID = function() return 77 end,
    getX = function() return 14 end,
    getY = function() return 10 end,
    getZ = function() return 0 end,
}
local campfireSquare = {
    getX = function() return 14 end,
    getY = function() return 10 end,
    getZ = function() return 0 end,
    getCampfire = function() return campfire end,
    getObjects = function() return {} end,
}
local squares = {
    ["10:10:0"] = roomSquare,
    ["14:10:0"] = campfireSquare,
}
local cell = {
    getBuildingList = function() return { building } end,
    getGridSquare = function(_, x, y, z)
        return squares[tostring(x) .. ":" .. tostring(y) .. ":"
            .. tostring(z)]
    end,
}
local locatorCalls = 0

PNC = {
    NearbyResourceLocator = {
        FindObject = function()
            locatorCalls = locatorCalls + 1
            return nil
        end,
    },
    FacilityInteractionTargets = {},
    Semantics = {},
}
getCell = function() return cell end

T.load("ProjectHoomans", "shared", "PNC/Semantics/PNC_SemanticCampSite.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticCampSiteGeometry.lua")
T.load("ProjectHoomans", "server",
    "PNC/Semantics/PNC_SemanticWorldTargetResolver.lua")
T.load("ProjectHoomans", "server",
    "PNC/Semantics/PNC_SemanticCampSiteResolver.lua")

local Resolver = PNC.Semantics.CampSiteResolver
local CampSite = PNC.Semantics.CampSite
local player = {
    getX = function() return 10.5 end,
    getY = function() return 10.5 end,
    getZ = function() return 0 end,
}
local roomHint = {
    version = 1,
    kind = "camp_site",
    scope = "room",
    siteScope = "room",
    siteID = "room:test-building:test-room",
    roomID = "test-room",
    buildingID = "test-building",
    x = 10.5,
    y = 10.5,
    z = 0,
    radius = 32,
    score = 1,
}

local roomSite, roomReason = Resolver.ValidateClientSite({
    kind = CampSite.KIND,
    scope = CampSite.SCOPES.HERE,
    clientHint = roomHint,
}, {
    selectionOrigin = player,
    player = player,
    cell = cell,
})
T.truthy(roomSite, "authoritative room validation accepts the exact hint")
T.equal(roomReason, nil, "room hint validation has no failure reason")
T.equal(roomSite.scope, "room", "room hint validation keeps room scope")
T.equal(roomSite.siteID, roomHint.siteID,
    "room hint validation derives the stable room identity")
T.truthy(roomSite.roomBounds,
    "room hint validation uses server-owned room bounds")
T.equal(locatorCalls, 0,
    "room hint validation does not invoke the broad world locator")

local campfireSite, campfireReason = Resolver.ValidateClientSite({
    kind = CampSite.KIND,
    scope = CampSite.SCOPES.HERE,
    clientHint = {
        version = 1,
        kind = "campfire",
        scope = "campfire",
        siteScope = "campfire",
        campfireID = "campfire@14:10:0",
        x = 14.5,
        y = 10.5,
        z = 0,
        radius = 32,
        score = 1,
    },
}, {
    selectionOrigin = player,
    player = player,
    cell = cell,
})
T.truthy(campfireSite,
    "authoritative campfire validation accepts the exact loaded square")
T.equal(campfireReason, nil, "campfire hint validation has no failure reason")
T.equal(campfireSite.scope, "campfire",
    "campfire hint validation keeps campfire scope")
T.equal(campfireSite.campfireID, "campfire@14:10:0",
    "campfire hint validation keeps the server-owned fire identity")
T.equal(locatorCalls, 0,
    "campfire hint validation does not invoke the broad world locator")

local staleRoomHint = {}
for key, value in pairs(roomHint) do staleRoomHint[key] = value end
staleRoomHint.siteID = "room:other-building:other-room"
local staleSite, staleReason = Resolver.ValidateClientSite({
    kind = CampSite.KIND,
    scope = "here",
    clientHint = staleRoomHint,
}, {
    selectionOrigin = player,
    cell = cell,
})
T.falsy(staleSite, "stale room identity is rejected")
T.equal(staleReason, "camp_room_hint_stale",
    "stale room identity reports a bounded validation reason")

local notLoadedSite, notLoadedReason = Resolver.ValidateClientSite({
    kind = CampSite.KIND,
    scope = "here",
    clientHint = {
        version = 1,
        kind = "camp_site",
        scope = "room",
        siteScope = "room",
        x = 30.5,
        y = 30.5,
        z = 0,
        radius = 32,
    },
}, {
    selectionOrigin = player,
    cell = cell,
})
T.falsy(notLoadedSite, "an unloaded hinted square is rejected")
T.equal(notLoadedReason, "camp_room_hint_not_loaded",
    "unloaded hinted square reports a bounded validation reason")

T.finish("pnc_companion_camp_site_hint_smoke")
