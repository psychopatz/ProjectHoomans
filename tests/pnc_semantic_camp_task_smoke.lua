local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
})

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local CampSite = T.load("ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticCampSite.lua")
local roomAvailable = true
local roomSite = {
    kind = CampSite.KIND,
    scope = CampSite.SCOPES.ROOM,
    siteScope = CampSite.SCOPES.ROOM,
    siteID = "room:building-1:bedroom-1",
    roomID = "bedroom-1",
    buildingID = "building-1",
    roomType = "BEDROOM",
    x = 10.5, y = 10.5, z = 0,
    label = "bedroom", risk = "sheltered",
    mode = "walk", stopDistance = 0.7,
    radius = 3, resourceRadius = 12,
    roomBounds = { minX = 10, minY = 10, maxX = 12, maxY = 12, z = 0 },
}
local campfireSite = {
    kind = "campfire",
    targetID = "campfire@4:4:0",
    x = 4.5, y = 4.5, z = 0,
    stopDistance = 1.25,
}
local Geometry = {
    FindNearestRoom = function()
        if roomAvailable then return roomSite end
        return nil, "room_not_found"
    end,
}
local WorldTargets = {
    Resolve = function(target)
        if target and target.kind == "campfire" then
            return campfireSite
        end
        return nil, "unsupported_target"
    end,
}
local submittedPlan
local registeredHandler
local Plans = {
    Submit = function(plan)
        submittedPlan = plan
        return true, plan
    end,
}
local Requests = {
    RegisterHandler = function(action, handler)
        if action == "CAMP" then registeredHandler = handler end
        return true
    end,
}
local player = {
    getX = function() return 10 end,
    getY = function() return 10 end,
    getZ = function() return 0 end,
}

PNC = {
    Core = { Now = function() return 1000 end },
    Semantics = {
        CampSite = CampSite,
        CampSiteGeometry = Geometry,
        WorldTargetResolver = WorldTargets,
        ActionPlanService = Plans,
        TaskRequestService = Requests,
    },
}

local Resolver = T.load("ProjectHoomans", "server",
    "PNC/Semantics/PNC_SemanticCampSiteResolver.lua")

local resolvedRoom, roomReason = Resolver.Resolve({
    kind = CampSite.KIND,
    scope = CampSite.SCOPES.ROOM,
    roomQuery = "bedroom",
}, { player = player, cell = {} })
T.equal(roomReason, nil, "explicit room camp has no resolution error")
T.equal(resolvedRoom.siteID, roomSite.siteID,
    "explicit room camp resolves the authoritative room")

roomAvailable = false
local resolvedHere, hereReason = Resolver.Resolve({
    kind = CampSite.KIND,
    scope = CampSite.SCOPES.HERE,
}, { player = player, cell = {} })
T.equal(hereReason, nil, "here camp falls back without an error")
T.equal(resolvedHere.scope, CampSite.SCOPES.CAMPFIRE,
    "here camp falls back to a nearby campfire")

local missingRoom, missingReason = Resolver.Resolve({
    kind = CampSite.KIND,
    scope = CampSite.SCOPES.ROOM,
    roomQuery = "bedroom",
}, { player = player, cell = {} })
T.truthy(missingRoom,
    "missing room type falls back to the nearest available camp site")
T.equal(missingRoom.scope, CampSite.SCOPES.CAMPFIRE,
    "missing room type falls back to a campfire")
T.equal(missingReason, nil,
    "campfire fallback does not report an unresolved room")

roomAvailable = true
local Handler = T.load("ProjectHoomans", "server",
    "PNC/Semantics/PNC_SemanticCampTaskHandler.lua")
T.truthy(registeredHandler == Handler,
    "CAMP handler registers with the shared task service")
local clientValidationCalls = 0
local broadResolutionCalls = 0
local originalValidateClientSite = Resolver.ValidateClientSite
local originalResolve = Resolver.Resolve
Resolver.ValidateClientSite = function(target, context)
    clientValidationCalls = clientValidationCalls + 1
    return roomSite
end
Resolver.Resolve = function(target, context)
    broadResolutionCalls = broadResolutionCalls + 1
    return originalResolve(target, context)
end
local result = Handler.Submit({
    intent = "REQUEST",
    action = "CAMP",
    rawText = "Let's camp in the bedroom",
    confidence = 0.96,
    recipient = { id = "npc:camp" },
    target = {
        kind = CampSite.KIND,
        scope = CampSite.SCOPES.ROOM,
        roomQuery = "bedroom",
        clientHint = {
            kind = CampSite.KIND,
            scope = CampSite.SCOPES.ROOM,
            siteID = roomSite.siteID,
            roomID = roomSite.roomID,
            buildingID = roomSite.buildingID,
            x = roomSite.x,
            y = roomSite.y,
            z = roomSite.z,
        },
    },
}, { npcID = "npc:camp", player = player })
T.truthy(result.accepted, "CAMP admission accepts a resolved room")
T.equal(submittedPlan.steps[1].action, "MOVE_TO",
    "camp plan starts with the shared movement step")
T.equal(submittedPlan.steps[2].action, "VERIFY_CAMP_SITE",
    "camp plan verifies arrival before committing")
T.equal(submittedPlan.steps[3].action, "COMMIT_CAMP_ORDER",
    "camp plan commits the durable order last")
T.equal(submittedPlan.steps[1].parameters.target.x, roomSite.x,
    "camp movement uses the resolved room anchor")
T.equal(clientValidationCalls, 1,
    "client-originated CAMP uses exact hint validation")
T.equal(broadResolutionCalls, 0,
    "client-originated CAMP does not fall back to broad discovery")
Resolver.ValidateClientSite = originalValidateClientSite
Resolver.Resolve = originalResolve

local noHint = Handler.Submit({
    intent = "REQUEST",
    action = "CAMP",
    rawText = "Let's camp here",
    confidence = 0.96,
    recipient = { id = "npc:camp" },
    target = { kind = CampSite.KIND, scope = CampSite.SCOPES.HERE },
}, { npcID = "npc:camp", player = player })
T.falsy(noHint.accepted,
    "client-originated CAMP without an observation is rejected")
T.equal(noHint.reason, "camp_site_hint_required",
    "missing client observation has a stable rejection reason")

T.finish("pnc_semantic_camp_task_smoke")
