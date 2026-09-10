local T = require "tests/support/test"

local now = 100
local live = true
local emitted = {}

PNC = {
    Const = { PRESENCE_LIVE = "live" },
    Registry = {
        Get = function()
            return { alive = true, presenceState = live and "live" or "abstract" }
        end,
        GetLiveZombie = function()
            return live and {} or nil
        end,
    },
    AbstractWorldStore = {
        Emit = function(eventName)
            emitted[#emitted + 1] = eventName
        end,
    },
    AbstractLocations = {
        Depart = function() end,
        Arrive = function() end,
    },
    AbstractGroupManagerInternal = { Touch = function() end },
    DirectorConfig = {},
}

PNC.AbstractGroups = {
    SetState = function(group, state, at, endsAt)
        group.state = state
        group.stateStartedAt = at
        group.stateEndsAt = endsAt
        return true
    end,
}

T.load(
    "ProjectHoomans",
    "server",
    "PNC/Director/AbstractGroupManager/PNC_AbstractGroupManager_ThreatAndLOD.lua"
)
local Groups = PNC.AbstractGroups

local group = {
    id = "agroup_mobile",
    memberIds = { "npc_mobile" },
    state = "TRAVELING",
    targetLocation = { id = "road_target" },
    mobileAmbient = true,
    simulation = { lod = "ACTIVE" },
}

local lod = Groups.RefreshLOD(group, now)
T.equal(lod, "ACTIVE", "live group remains active")
T.equal(group.state, "ACTIVE",
    "stale live traversal shadow is repaired")
T.equal(group.targetLocation, nil,
    "stale live traversal target is cleared")
T.truthy(emitted[1] == "GROUP_LIVE_TRAVEL_REPAIRED",
    "live traversal repair emits an observable event")

group.state = "TRAVELING"
group.targetLocation = { id = "directed_target" }
group.mobileAmbient = false
local directedLod = Groups.RefreshLOD(group, now + 1)
T.equal(directedLod, "ACTIVE", "directed live group remains active")
T.equal(group.state, "TRAVELING",
    "directed live traversal state is preserved")
T.equal(group.targetLocation.id, "directed_target",
    "directed live traversal target is preserved")

live = false
group.state = "ACTIVE"
group.simulation.lod = "ACTIVE"
local abstractLod = Groups.RefreshLOD(group, now + 1)
T.equal(abstractLod, "ABSTRACT", "abstract group transitions to abstract LOD")
T.equal(group.state, "ARRIVED", "abstracted non-traveling group arrives")

T.finish("pnc_mobile_traversal_lifecycle_smoke")
