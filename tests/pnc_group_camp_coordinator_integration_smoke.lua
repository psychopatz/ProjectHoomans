local T = require "tests/support/test"
T.addPackagePaths()

local records = {}
local bodies = {}
local buildRootOnly
local coordinatorCalls = 0
local coordinatorOptions

local function makeRecord(id)
    local record = {
        id = id,
        alive = true,
        recruited = true,
        presenceState = "live",
        owner = "alice",
        orderSpec = {
            kind = "follow",
            ownerUsername = "alice",
            ownerOnlineID = 7,
        },
        runtime = {},
    }
    records[id] = record
    bodies[id] = {
        isDead = function() return false end,
        getX = function() return id == "npc-a" and 2 or 4 end,
        getY = function() return 0 end,
        getZ = function() return 0 end,
    }
    return record
end

makeRecord("npc-a")
makeRecord("npc-b")
-- Nearby group CAMP must not require the old order to still be FOLLOW. The
-- command is allowed to replace another owned companion order.
records["npc-b"].orderSpec.kind = "guard"

local player = {
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    getUsername = function() return "alice" end,
    getOnlineID = function() return 7 end,
    isDead = function() return false end,
}

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        ORDER_FOLLOW = "follow",
        ORDER_CAMP = "camp",
        COMPANION_COMMAND_RADIUS = 20,
        CAMP_RADIUS = 3,
        CAMP_RESOURCE_RADIUS = 12,
        ATTACK_TYPE_AUTO = "auto",
        ATTACK_TYPE_MELEE = "melee",
        ATTACK_TYPE_RANGED = "ranged",
        ATTACK_TYPE_NONE = "none",
    },
    Core = {
        IsAuthority = function() return true end,
        Now = function() return 1234 end,
        DistanceSq = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return dx * dx + dy * dy
        end,
    },
    Identity = {
        Verifier = {
            IsCompanion = function(record) return record.recruited == true end,
            IsOwnedByPlayer = function(record, value)
                return record.owner == value.getUsername()
            end,
        },
    },
    Registry = {
        Get = function(id) return records[tostring(id)] end,
        GetLiveZombie = function(id) return bodies[tostring(id)] end,
        ForEach = function(callback)
            callback(records["npc-a"])
            callback(records["npc-b"])
        end,
    },
    OrderSystem = {
        SetOrder = function(record, orderSpec)
            record.orderSpec = orderSpec
        end,
    },
    Network = {
        BroadcastRecord = function() end,
    },
    Semantics = {
        CampSiteResolver = {
            ValidateClientSite = function(target)
                local hint = target.clientHint
                return {
                    kind = "camp_site",
                    scope = hint.scope,
                    siteScope = hint.siteScope,
                    siteID = hint.siteID,
                    x = hint.x,
                    y = hint.y,
                    z = hint.z,
                    radius = 3,
                    stopDistance = 0.7,
                    label = hint.label,
                }
            end,
        },
    },
}

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Commands/PNC_CompanionCommandRegistry.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Commands/PNC_CompanionCommandDefinitions.lua"
)

PNC.CampZoneService = {
    BuildGroup = function(_, recipients, options)
        buildRootOnly = options.rootOnly
        T.equal(#recipients, 2, "registry sends only explicit live group ids")
        return { revision = 3, assignments = {} }
    end,
}
PNC.CampMovementCoordinator = {
    StartGroupCamp = function(site, recipients, directory, options)
            coordinatorCalls = coordinatorCalls + 1
            coordinatorOptions = options
        T.equal(site.siteID, "room:living",
            "coordinator receives the validated client root site")
        T.equal(directory, nil,
            "root transit does not build a full zone directory")
        for index = 1, #recipients do
            recipients[index].orderSpec = {
                kind = "camp",
                campId = options.campId,
                x = site.x,
                y = site.y,
                z = site.z,
                placementState = index == 1 and "moving" or "queued",
            }
        end
        return #recipients, "commanded", { "npc-a", "npc-b" }
    end,
}

local affected, reason, targetIDs = PNC.CompanionCommands.Execute(player, {
    commandID = "camp",
    scope = "group",
    targetIDs = { "npc-a", "npc-b" },
    campSiteHint = {
        scope = "room",
        siteScope = "room",
        siteID = "room:living",
        x = 5,
        y = 5,
        z = 0,
        label = "living room",
    },
})
T.equal(affected, 2, "group camp returns coordinator target count")
T.equal(reason, "commanded", "group camp returns coordinator reason")
T.equal(#targetIDs, 2, "group camp returns coordinator target ids")
T.equal(buildRootOnly, nil,
    "normal coordinator admission skips zone allocation entirely")
T.equal(coordinatorCalls, 1,
    "registry invokes one coordinator session for the group")
T.equal(coordinatorOptions.ownerKey, "7",
    "coordinator ownership is tied to the issuing player")
T.equal(records["npc-a"].orderSpec.placementState, "moving",
    "coordinator owns the first placement state")
T.equal(records["npc-b"].orderSpec.placementState, "queued",
    "coordinator owns later placement states")

T.finish("pnc_group_camp_coordinator_integration_smoke")
