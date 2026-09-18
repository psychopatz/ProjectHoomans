local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
    { "PsychopatzCore", "common" },
})

local worldAge = 10
local records = {}

local function copy(value)
    local output
    if type(value) ~= "table" then return value end
    output = {}
    for key, child in pairs(value) do output[key] = copy(child) end
    return output
end

local function body()
    return {
        isDead = function() return false end,
    }
end

function getGameTime()
    return {
        getWorldAgeHours = function() return worldAge end,
    }
end

PNC = {
    Const = {
        ORDER_ROAM = "roam",
        ORDER_CAMP = "camp",
        ORDER_GUARD = "guard",
        PRESENCE_LIVE = "live",
    },
    Core = {
        IsAuthority = function() return true end,
        Now = function() return 1000 end,
    },
    Registry = {
        Get = function(id) return records[tostring(id)] end,
        GetLiveZombie = function(id)
            local record = records[tostring(id)]
            return record and record.body or nil
        end,
        MarkDirty = function() end,
    },
    Factions = {
        GetPlayerFaction = function()
            return { id = "faction:player" }
        end,
    },
    Communities = {
        GetForFaction = function()
            return { { id = "colony:player", status = "active" } }
        end,
    },
    BaseService = {
        GetForColony = function()
            return { id = "base:player", baseZoneId = "zone:player" }
        end,
    },
    RelationshipStates = {
        ResolveState = function(relationship)
            return relationship and relationship.state or "unknown"
        end,
    },
    OrderSystem = {
        SetOrder = function(record, order)
            record.orderSpec = copy(order)
        end,
    },
}

local Service = T.load("ProjectHoomans", "server",
    "PNC/World/PNC_AmbientVisitService.lua")
local Zones = require "PsychopatzCore/World/PC_ZoneRegistry"
Zones.register({
    id = "zone:player",
    ownerType = "projecthoomans.base",
    ownerId = "base:player",
    type = "base",
    geometry = {
        levels = {
            [0] = {
                rows = {
                    [20] = { 10, 20 },
                    [21] = { 10, 20 },
                    [22] = { 10, 20 },
                    [23] = { 10, 20 },
                    [24] = { 10, 20 },
                },
            },
        },
    },
})

local function newRecord(id)
    local record = {
        id = id,
        alive = true,
        presenceState = "live",
        body = body(),
        hostility = { attackPlayers = false, attackNPCs = false },
        runtime = {},
        orderSpec = { kind = "roam", roamMode = "area", x = 10, y = 20, z = 0 },
    }
    records[id] = record
    return record
end

local site = {
    scope = "room",
    siteID = "room:living:1",
    roomID = "room:living:1",
    buildingID = "building:1",
    roomName = "living room",
    x = 12,
    y = 22,
    z = 0,
    roomBounds = { minX = 10, minY = 20, maxX = 14, maxY = 24, z = 0 },
}

local visitor = newRecord("visitor_one")
local started, reason, summary = Service.Begin(visitor, site, {
    authorized = true,
    accessClass = "player_visitor",
    purpose = "invited_visit",
    at = 10,
    durationHours = 2,
})

T.truthy(started, reason)
T.equal(summary.kind, "ambient_visit",
    "ambient visit did not return its lease kind")
T.equal(visitor.orderSpec.kind, "camp",
    "ambient visit did not install the camp movement boundary")
T.truthy(visitor.orderSpec.ambientVisit,
    "ambient visit marker was not preserved on the order")
T.truthy(visitor.orderSpec.ambientNoNeeds,
    "ambient visit did not mark itself as no-needs")
T.truthy(Service.IsActive(visitor, 11),
    "ambient visit was not active before expiry")
T.truthy(Service.IsOrderProtected(visitor, 11),
    "ambient visit order was not protected")
T.truthy(Service.CanUseAmbient(visitor, 11),
    "ambient visitor was not granted item-free ambient capability")
T.falsy(visitor.needs,
    "ambient visit created a needs container")

local released = Service.Release(visitor, "test_release", 11)
T.truthy(released, "ambient visit did not release")
T.equal(visitor.orderSpec.kind, "roam",
    "ambient visit did not restore the previous roam order")
T.falsy(Service.IsActive(visitor, 11),
    "released ambient visit remained active")

local expiring = newRecord("visitor_expiring")
T.truthy(Service.Begin(expiring, site, {
    authorized = true,
    at = 20,
    durationHours = 0.1,
}))
worldAge = 20.2
T.equal(Service.Pump(worldAge, 4), 1,
    "expired ambient visit was not reclaimed by the bounded pump")
T.equal(expiring.orderSpec.kind, "roam",
    "expired ambient visit did not restore its previous order")

local resolveCalls = 0
PNC.Semantics = {
    CampSiteResolver = {
        Resolve = function()
            resolveCalls = resolveCalls + 1
            return {
                kind = "camp_site",
                scope = "room",
                siteID = "room:mobile:1",
                roomID = "mobile_room_1",
                buildingID = "mobile_building_1",
                roomName = "living room",
                roomBounds = {
                    minX = 90, minY = 90, maxX = 94, maxY = 94, z = 0,
                },
                x = 92, y = 92, z = 0,
                label = "living room",
            }, "resolved"
        end,
    },
}

local mobileOrder = {
    kind = "roam",
    roamMode = "shelter",
    ambientMobile = true,
    ambientObjective = "shelter",
    ambientSourceID = "mobile:faction:1",
    shelterSiteID = "building:mobile:1",
    shelterBounds = { minX = 88, minY = 88, maxX = 100, maxY = 100 },
    x = 92, y = 92, z = 0,
}
local mobileOne = newRecord("mobile_one")
mobileOne.orderSpec = copy(mobileOrder)
local mobileTwo = newRecord("mobile_two")
mobileTwo.orderSpec = copy(mobileOrder)
T.truthy(Service.TryStartMobileShelter(
    mobileOne, mobileOne.body, mobileOne.orderSpec, 40
), "mobile shelter did not start after arrival")
T.truthy(Service.TryStartMobileShelter(
    mobileTwo, mobileTwo.body, mobileTwo.orderSpec, 40
), "second mobile shelter lease did not start")
T.equal(resolveCalls, 1,
    "mobile shelter resolved the same loaded target more than once")
T.equal(mobileOne.orderSpec.kind, "camp",
    "mobile shelter did not install the ambient camp order")
T.equal(mobileOne.orderSpec.ambientAccessClass, "ai_faction_ambient",
    "mobile shelter used the player visitor access class")
T.truthy(Service.CanUseAmbient(mobileOne, 40),
    "mobile shelter did not remain item-free ambient")
T.truthy(Service.ReleaseMobileShelter(mobileOne,
    "mobile_shelter_day_started", 41),
    "mobile shelter did not release at the day boundary")
T.equal(mobileOne.orderSpec.kind, "roam",
    "mobile shelter release did not restore shelter roaming")

local invited = newRecord("visitor_invited")
local invitedOK, invitedReason = Service.BeginAtTarget(
    invited,
    { kind = "camp_site", scope = "room" },
    { record = invited },
    {
        authorized = true,
        accessClass = "player_visitor",
        purpose = "invited_visit",
        at = 42,
    }
)
T.truthy(invitedOK, invitedReason)
T.equal(invited.orderSpec.kind, "camp",
    "resolved invitation did not install a camp movement order")
T.equal(invited.orderSpec.ambientPurpose, "invited_visit",
    "resolved invitation lost its temporary purpose")

local hostile = newRecord("visitor_hostile")
hostile.hostility.attackPlayers = true
local hostileOK, hostileReason = Service.Begin(hostile, site, {
    authorized = true,
    at = 30,
})
T.falsy(hostileOK, "hostile NPC was admitted as an ambient visitor")
T.equal(hostileReason, "visitor_hostile",
    "hostile visitor rejection used the wrong reason")

local busy = newRecord("visitor_busy")
busy.runtime.taskLeaseId = "task:busy"
local busyOK, busyReason = Service.Begin(busy, site, {
    authorized = true,
    at = 30,
})
T.falsy(busyOK, "busy NPC was admitted as an ambient visitor")
T.equal(busyReason, "visitor_busy",
    "busy visitor rejection used the wrong reason")

PNC.Semantics.CampSiteResolver.Resolve = function()
    return {
        kind = "camp_site",
        scope = "room",
        siteID = "room:player:1",
        roomID = "player_room_1",
        buildingID = "player_building_1",
        roomName = "living room",
        roomBounds = {
            minX = 10, minY = 20, maxX = 14, maxY = 24, z = 0,
        },
        x = 12, y = 22, z = 0,
        label = "living room",
    }, "resolved"
end

local invitedPreviewRecord = newRecord("visitor_preview")
local invitationPreview = Service.GetInvitationPreview(
    invitedPreviewRecord,
    { id = "player_one" },
    { state = "friend" }
)
T.truthy(invitationPreview.eligible,
    "friendly live visitor did not receive an invitation preview")
T.equal(invitationPreview.baseID, "base:player",
    "invitation preview did not identify the player's base")

local invitedFriend = newRecord("visitor_friend")
local invitedFriendOK, invitedFriendReason, invitedFriendSummary =
    Service.Invite(
        invitedFriend,
        { id = "player_one" },
        { state = "friend" },
        { authorized = true, requestID = "invite:1", at = 50 }
    )
T.truthy(invitedFriendOK, invitedFriendReason)
T.equal(invitedFriendSummary.siteLabel, "living room",
    "invitation did not retain the resolved room label")
T.equal(invitedFriend.orderSpec.ambientPurpose, "invited_visit",
    "friendly invitation did not create a temporary visit lease")

PNC.Semantics.CampSiteResolver.Resolve = function(target)
    if target and target.scope == "room" then
        return {
            kind = "camp_site",
            scope = "room",
            siteID = "room:outside:1",
            roomID = "outside_room_1",
            roomBounds = {
                minX = 90, minY = 90, maxX = 94, maxY = 94, z = 0,
            },
            x = 92, y = 92, z = 0,
            label = "outside room",
        }, "resolved"
    end
    return {
        kind = "camp_site",
        scope = "campfire",
        siteID = "campfire:player:1",
        campfireID = "campfire:player:1",
        x = 16, y = 22, z = 0,
        label = "campfire",
    }, "resolved"
end

local campfireFriend = newRecord("visitor_campfire_friend")
local campfireOK, campfireReason, campfireSummary = Service.Invite(
    campfireFriend,
    { id = "player_one" },
    { state = "friend" },
    { authorized = true, requestID = "invite:campfire", at = 51 }
)
T.truthy(campfireOK, campfireReason)
T.equal(campfireSummary.site.scope, "campfire",
    "invitation did not fall back to a campfire inside the base")

local neutral = newRecord("visitor_neutral")
local neutralOK, neutralReason = Service.Invite(
    neutral,
    { id = "player_one" },
    { state = "neutral" },
    { authorized = true, requestID = "invite:2", at = 50 }
)
T.falsy(neutralOK, "neutral NPC was offered a temporary invitation")
T.equal(neutralReason, "visitor_relationship_not_friendly",
    "neutral invitation rejection used the wrong reason")
