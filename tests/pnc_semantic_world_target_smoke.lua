local T = require "tests/support/test"
T.addPackagePaths()

local acceptedCalls = 0
local campfire = {
    getID = function() return 77 end,
    isCampfire = function() return true end,
}
local globalCampfire = {
    getX = function() return 30 end,
    getY = function() return 31 end,
    getZ = function() return 0 end,
}
local globalCampfireSquare = {
    getX = function() return 30 end,
    getY = function() return 31 end,
    getZ = function() return 0 end,
    getCampfire = function() return globalCampfire end,
}

PNC = {
    NearbyResourceLocator = {
        FindObject = function(_, options)
            acceptedCalls = acceptedCalls + 1
            if tostring(options.cacheKey or "")
                == "semantic_campfire:campfire@30:31:0"
            then
                T.truthy(options.specialObject,
                    "campfire lookup provides the special-object hook")
                local special = options.specialObject
                    and options.specialObject(globalCampfireSquare)
                T.truthy(special, "special-object hook finds the global campfire")
                local candidate = special and {
                    object = special.object,
                    key = special.key,
                    source = special.source,
                    x = 30.5, y = 31.5, z = 0,
                } or nil
                return candidate and options.accept(candidate) and candidate
                    or nil
            end
            local candidate = {
                object = campfire,
                key = "campfire@12:14:0#77",
                x = 12.5, y = 14.5, z = 0,
            }
            return options.accept(candidate) and candidate or nil
        end,
    },
    FacilityInteractionTargets = {
        ResolveResource = function(resource)
            return {
                {
                    kind = "seat",
                    targetID = resource.resourceKey,
                    x = 20.5, y = 21.5, z = 0,
                    validSpot = true,
                },
            }
        end,
    },
    Semantics = {},
}

T.load(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/PNC_SemanticWorldTargetResolver.lua"
)
local Resolver = PNC.Semantics.WorldTargetResolver

local direct = Resolver.Resolve({ kind = "world_point", x = 1, y = 2, z = 0,
    stopDistance = 1.2 })
T.equal(direct.x, 1, "direct target remains primitive")
T.equal(direct.stopDistance, 1.2, "direct stop distance is retained")

local campTarget, campReason = Resolver.Resolve({
    kind = "campfire", radius = 16,
}, {
    record = { x = 10, y = 10, z = 0 },
})
T.truthy(campTarget, "nearest campfire resolves")
T.equal(campReason, nil, "campfire has no resolution error")
T.equal(campTarget.targetID, "campfire@12:14:0#77",
    "campfire uses a stable locator key")
T.equal(campTarget.objectKind, "campfire", "campfire kind is explicit")
T.equal(campTarget.x, 12.5, "campfire coordinate is copied")
T.falsy(campTarget.object, "Java object does not cross the boundary")
T.equal(acceptedCalls, 1, "campfire lookup is bounded to one locator call")

local globalCampTarget, globalCampReason = Resolver.Resolve({
    kind = "campfire",
    targetID = "campfire@30:31:0",
}, {
    record = { x = 28, y = 29, z = 0 },
})
T.truthy(globalCampTarget,
    "global campfire resolves through the square hook: "
        .. tostring(globalCampReason))
T.equal(globalCampReason, nil, "global campfire has no resolution error")
T.equal(globalCampTarget.targetID, "campfire@30:31:0",
    "global campfire receives a stable coordinate identity")
T.equal(globalCampTarget.x, 30.5,
    "global campfire uses the square center as its approach point")
T.equal(acceptedCalls, 2, "global campfire lookup is bounded")

local resourceTarget = Resolver.Resolve({
    kind = "facility_resource",
    resource = { resourceKey = "seat:1" },
})
T.equal(resourceTarget.kind, "seat", "facility target is normalized")
T.equal(resourceTarget.targetID, "seat:1",
    "facility target keeps its primitive identity")
T.equal(resourceTarget.x, 20.5, "facility target keeps its approach point")

local _, missingReason = Resolver.Resolve({ kind = "campfire" }, {
    record = nil,
})
T.equal(missingReason, "world_origin_unavailable",
    "world lookup fails safely without an origin")

T.finish("pnc_semantic_world_target_smoke")
