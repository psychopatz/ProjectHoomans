local T = require "tests/support/test"
T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local retired = {}
local records = {
    {
        id = "npc_save_a",
        alive = true,
        presenceState = "live",
        runtime = {},
    },
    {
        id = "npc_save_b",
        alive = true,
        presenceState = "live",
        runtime = {},
    },
    {
        id = "npc_save_abstract",
        alive = true,
        presenceState = "abstract",
        runtime = {},
    },
}

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        ABSTRACT_DISTANCE = 40,
        LIVE_BODY_RETIRE_DISTANCE = 40,
        LIVE_BODY_SAFETY_SWEEP_MS = 100,
    },
    Core = {
        IsAuthority = function() return true end,
        Now = function() return 1000 end,
    },
    Registry = {
        ForEachLive = function(callback)
            callback(records[1], { id = "body_a" })
            callback(records[2], { id = "body_b" })
        end,
    },
    Presence = {
        Internal = {},
    },
}

PNC.Presence.Abstract = function(record, reason)
    retired[#retired + 1] = {
        id = record.id,
        reason = reason,
    }
    record.presenceState = "abstract"
    return true
end

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Presence/PNC_Presence/PNC_Presence_LiveBodySafety.lua"
)

local count, deferred, reason =
    PNC.Presence.RetireLiveBodiesForWorldSave("world_save_retire")
T.equal(count, 2, "world save did not retire all live carriers")
T.equal(deferred, 0, "world save unexpectedly deferred body retirement")
T.equal(reason, "retired", "world save retirement reason")
T.equal(retired[1].reason, "world_save_retire",
    "first save retirement reason")
T.equal(retired[2].reason, "world_save_retire",
    "second save retirement reason")
T.equal(records[1].presenceState, "abstract",
    "first live record remained embodied")
T.equal(records[2].presenceState, "abstract",
    "second live record remained embodied")
T.truthy(records[1].runtime.preSaveRetired,
    "first record missing save-retirement marker")
T.truthy(records[2].runtime.forcePresenceCheck,
    "second record was not queued for post-save presence")
T.equal(records[3].presenceState, "abstract",
    "already abstract record was mutated")

-- Failed engine removal stays visible to the save boundary as deferred.
PNC.Registry.ForEachLive = function(callback)
    records[1].presenceState = "live"
    callback(records[1], { id = "body_a" })
end
PNC.Presence.Abstract = function() return false end
count, deferred, reason =
    PNC.Presence.RetireLiveBodiesForWorldSave("world_save_retire")
T.equal(count, 0, "failed save retirement counted as success")
T.equal(deferred, 1, "failed save retirement was not surfaced")
T.equal(reason, "body_removal_deferred",
    "failed save retirement reason")

-- The persistence coordinator must retire physical carriers before it commits
-- the PNC registry snapshot. Reversing this ordering would persist wasLive and
-- recreate the restart rehydration problem even though the shell was removed.
local coordinator = T.read(
    "ProjectHoomans",
    "server",
    "PNC/Server/PNC_PersistenceCoordinator.lua"
)
local retirePos = coordinator:find(
    "RetireLiveBodiesForWorldSave", 1, true
)
local commitPos = coordinator:find(
    'Coordinator.Commit("world_save")', 1, true
)
T.truthy(retirePos and commitPos and retirePos < commitPos,
    "world-save persistence runs before live-body retirement")

return T.finish("pnc_world_save_body_retirement_smoke")
