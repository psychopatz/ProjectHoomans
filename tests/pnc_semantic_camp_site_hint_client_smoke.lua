local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = {
    RuntimeRole = { AllowsClientCode = function() return true end },
}

local roomLookups = 0
local campfireLookups = 0
local roomSite = {
    distance = 4,
    siteID = "site:bedroom",
    roomID = "room:bedroom",
    buildingID = "building:1",
    roomType = "bedroom",
    roomName = "Bedroom",
    label = "the bedroom",
    labelKey = "room.bedroom",
    risk = "low",
    x = 10,
    y = 11,
    z = 0,
    roomBounds = { minX = 9, minY = 10, maxX = 12, maxY = 13 },
}
local worldHint = {
    kind = "campfire",
    targetID = "campfire@14:10:0",
    x = 14,
    y = 10,
    z = 0,
    radius = 16,
    score = 0.9,
}
local lastRoomQuery
local lastRoomOptions
local lastCampfireTarget
local origin = { x = 10, y = 10, z = 0 }
local cell = {}

PNC = {
    Semantics = {
        CampSite = {
            KIND = "camp_site",
            MAX_QUERY = 96,
            MAX_LABEL = 80,
            SCOPES = {
                HERE = "here",
                ROOM = "room",
                CAMPFIRE = "campfire",
            },
            NormalizeTarget = function(target) return target end,
            NormalizeScope = function(scope) return scope end,
        },
        CampSiteGeometry = {
            _Internal = {
                Position = function(value)
                    if type(value) ~= "table" then return nil end
                    return value.x, value.y, value.z
                end,
            },
            FindNearestRoom = function(_, _, query, options)
                roomLookups = roomLookups + 1
                lastRoomQuery = query
                lastRoomOptions = options
                if roomSite then return roomSite end
                return nil, "room_not_found"
            end,
        },
        ClientWorldTargetHints = {
            Resolve = function(target)
                campfireLookups = campfireLookups + 1
                lastCampfireTarget = target
                return worldHint
            end,
        },
        SemanticDiagnostics = {
            IsEnabled = function() return false end,
        },
    },
}

getTimeInMillis = function() return 100 end

local Hints = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticCampSiteHints.lua"
)

local roomHint, roomReason = Hints.Resolve({
    kind = "camp_site",
    scope = "room",
    roomQuery = "bedroom",
    roomType = "bedroom",
}, { selectionOrigin = origin, cell = cell })
T.truthy(roomHint, "room lookup produces a camp-site hint")
T.equal(roomReason, nil, "a found room has no fallback reason")
T.equal(roomHint.kind, "camp_site", "room hint keeps the primitive kind")
T.equal(roomHint.scope, "room", "room hint keeps the resolved scope")
T.equal(roomHint.siteID, "site:bedroom", "room hint keeps stable site identity")
T.equal(roomHint.x, 10, "room projection keeps the selected coordinate")
T.equal(roomHint.minX, 9, "room projection keeps bounded room geometry")
T.equal(roomHint.score, 0.875, "room confidence keeps distance scoring")
T.falsy(roomHint.object, "room projection does not retain world objects")
T.equal(lastRoomQuery.text, "bedroom", "room search receives the bounded query")
T.equal(lastRoomOptions.radius, 32, "room search keeps the local radius")

local cachedRoom = Hints.Resolve({
    kind = "camp_site",
    scope = "room",
    roomQuery = "bedroom",
    roomType = "bedroom",
}, { selectionOrigin = origin, cell = cell })
T.equal(cachedRoom.siteID, "site:bedroom", "repeated room query returns cache")
T.equal(roomLookups, 1, "repeated room query does not rescan geometry")

local campfireHint, campfireReason = Hints.Resolve({
    kind = "camp_site",
    scope = "campfire",
}, { selectionOrigin = origin, cell = cell })
T.truthy(campfireHint, "campfire lookup projects a world-target hint")
T.equal(campfireReason, nil, "direct campfire lookup has no failure reason")
T.equal(campfireHint.kind, "campfire", "campfire projection keeps its kind")
T.equal(campfireHint.campfireID, "campfire@14:10:0",
    "campfire projection keeps the shared stable identity")
T.equal(campfireHint.x, 14, "campfire projection keeps the primitive position")
T.equal(lastCampfireTarget.concept, "CAMPFIRE",
    "campfire lookup delegates to the world-target resolver")

roomSite = nil
local fallbackHint, fallbackReason = Hints.Resolve({
    kind = "camp_site",
    scope = "room",
    roomID = "room:explicit",
    siteID = "site:explicit",
}, { selectionOrigin = origin, cell = cell })
T.truthy(fallbackHint, "explicit room may fall back to a nearby campfire")
T.equal(fallbackReason, "campfire_fallback",
    "campfire fallback remains visible in the reason")
T.equal(campfireLookups, 2, "explicit room fallback resolves one campfire")

Hints.ClearCache()
local missingOrigin, missingReason = Hints.Resolve({
    kind = "camp_site",
    scope = "room",
}, { cell = cell })
T.falsy(missingOrigin, "missing origin does not produce a world hint")
T.equal(missingReason, "world_origin_unavailable",
    "missing origin keeps its failure reason")

T.finish("pnc_semantic_camp_site_hint_client_smoke")
