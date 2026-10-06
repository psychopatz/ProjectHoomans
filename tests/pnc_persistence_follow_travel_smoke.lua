local T = require "tests/support/test"

local dirtyReason

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do
        result[key] = copy(item)
    end
    return result
end

PNC = {
    Const = {
        ORDER_FOLLOW = "follow",
        ORDER_TRAVEL = "travel",
    },
    Core = {
        Now = function() return 10 end,
        DeepCopy = copy,
    },
    Identity = {
        ApplyRecordIdentity = function() end,
    },
    Registry = {
        MarkDirty = function(_, reason)
            dirtyReason = reason
        end,
    },
    Journals = {
        RemoveNPC = function() end,
    },
    Persistence = {
        Internal = {
            sanitizeCorpse = function() return nil end,
            sanitizeSocial = function() return {} end,
            sanitizeStamina = function() end,
        },
        RebuildRuntime = function(record)
            record.runtime = {}
            return record
        end,
        Repairs = {
            Apply = function() end,
        },
    },
    Travel = {
        Model = {
            Normalize = function(raw)
                return copy(raw)
            end,
            IsActive = function(journey)
                return journey and journey.state == "en_route"
            end,
        },
        Service = {
            WorldHour = function() return 10 end,
        },
    },
}

T.load(T.path("ProjectHoomans", "shared",
    "PNC/Core/Persistence/PNC_Persistence/PNC_Persistence_DeserializeFinalization.lua"))

local follower = {
    id = "follower",
    alive = true,
    x = 7400,
    y = 6100,
    z = 0,
    orderSpec = { kind = "follow", ownerUsername = "owner" },
}
local followerRaw = {
    travel = {
        state = "en_route",
        journeyId = "journey:stale-home",
        destination = { x = 7000, y = 5000, z = 0 },
    },
}
local restoredFollower = PNC.Persistence.Internal.FinalizeDeserializedRecord(
    follower,
    followerRaw,
    {},
    { skillLevelDeltas = {}, skillXP = {} }
)
T.falsy(restoredFollower.travel,
    "load must retire travel attached to a persisted Follow order")
T.equal(restoredFollower.orderSpec.kind, "follow",
    "load must preserve the persisted Follow order")
T.equal(restoredFollower.x, 7400,
    "load must preserve the persisted abstract x position")
T.equal(restoredFollower.y, 6100,
    "load must preserve the persisted abstract y position")
T.equal(dirtyReason, "follow_travel_reconciled",
    "load repair must mark the stale route for persistence cleanup")

local traveler = {
    id = "traveler",
    alive = true,
    x = 10,
    y = 20,
    z = 0,
    orderSpec = { kind = "guard" },
}
local travelerRaw = {
    travel = {
        state = "en_route",
        journeyId = "journey:valid-travel",
        destination = { x = 100, y = 200, z = 0 },
    },
}
local restoredTraveler = PNC.Persistence.Internal.FinalizeDeserializedRecord(
    traveler,
    travelerRaw,
    {},
    { skillLevelDeltas = {}, skillXP = {} }
)
T.truthy(restoredTraveler.travel,
    "load must retain active travel for non-follow orders")
T.equal(restoredTraveler.orderSpec.kind, "travel",
    "active travel remains the movement owner for non-follow orders")
T.equal(restoredTraveler.orderSpec.journeyId, "journey:valid-travel",
    "active travel order points at the restored journey")

T.finish("pnc_persistence_follow_travel_smoke")
