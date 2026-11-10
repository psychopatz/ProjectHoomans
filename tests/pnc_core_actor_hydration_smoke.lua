local T = require "tests/support/test"

T.load("tests/pnc_npc_foundation_parity_baseline_smoke.lua")

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local actorRegistry = Actors.NewRegistry()
local previousDefaultRegistry = Actors.DefaultRegistry
Actors.DefaultRegistry = actorRegistry
PsychopatzCore.Actors = Actors

local actor, actorReason = actorRegistry:Create({
    actorId = "core:survivor:hydration",
    identitySeed = "core-survivor-hydration",
    archetypeID = "core.survivor",
    world = { position = { x = 101, y = 202, z = 0 } },
    extensions = {
        ["PsychopatzCore.SurvivorWorld"] = {
            factionID = "faction:hydration",
            communityID = "community:hydration",
            groupID = "group:hydration",
            role = "member",
        },
    },
})
T.truthy(actor, actorReason)

local records = {}
local dirty = 0
local previousRegistry = PNC.Registry
PNC.Registry = {
    Get = function(id) return records[tostring(id)] end,
    AddRecord = function(record)
        records[tostring(record.id)] = record
        return true
    end,
    MarkDirty = function() dirty = dirty + 1 end,
}

T.load("ProjectHoomans", "shared",
    "PNC/Core/Persistence/PNC_Persistence_CoreProvider.lua")

local Adapter = PNC.Persistence.CoreProvider
local record, status = Adapter.HydrateCoreActor(
    actor,
    PsychopatzCore
)
T.truthy(record, status)
T.equal(status, "created", "Core actor hydration status")
T.equal(record.id, actor.actorId, "hydrated record ID")
T.equal(record.coreActorID, actor.actorId, "hydrated Core actor ID")
T.equal(record.x, 101, "hydrated x position")
T.equal(record.y, 202, "hydrated y position")
T.equal(record.factionID, "faction:hydration",
    "hydrated faction affiliation")
T.equal(record.communityID, "community:hydration",
    "hydrated community affiliation")
T.equal(record.groupID, "group:hydration",
    "hydrated group affiliation")
T.equal(record.presenceState, PNC.Const.PRESENCE_ABSTRACT,
    "Core-only actor enters Hoomans as abstract")
T.truthy(dirty > 0, "hydration did not mark the runtime record dirty")

local second, secondStatus = Adapter.HydrateCoreActor(
    actor,
    PsychopatzCore
)
T.truthy(second, secondStatus)
T.equal(secondStatus, "existing", "repeated hydration status")
T.equal(records[actor.actorId], second,
    "repeated hydration replaced the record identity")

PNC.Registry = previousRegistry
Actors.DefaultRegistry = previousDefaultRegistry

T.finish("pnc_core_actor_hydration_smoke")
