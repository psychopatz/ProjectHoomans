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
    Data = records,
    Get = function(id) return records[tostring(id)] end,
    AddRecord = function(record)
        records[tostring(record.id)] = record
        return true
    end,
    MarkDirty = function() dirty = dirty + 1 end,
}

T.load("ProjectHoomans", "shared",
    "PNC/Core/Persistence/PNC_CoreActorExtension.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Core/Persistence/PNC_Persistence_CoreProvider.lua")

local Adapter = PNC.Persistence.CoreProvider
T.equal(Adapter.HydrateCoreActors, nil,
    "bulk HydrateCoreActors must be removed")

local record, status = Adapter.PromoteCoreActor(
    actor,
    PsychopatzCore,
    { reason = "smoke_test" }
)
T.truthy(record, status)
T.equal(status, "created", "Core actor promotion status")
T.equal(record.coreBacked, true, "promoted record must be coreBacked")
T.equal(record.id, actor.actorId, "promoted record ID")
T.equal(record.coreActorID, actor.actorId, "promoted Core actor ID")
T.equal(record.x, 101, "promoted x position")
T.equal(record.y, 202, "promoted y position")
T.equal(record.factionID, "faction:hydration",
    "promoted faction affiliation")
T.equal(record.communityID, "community:hydration",
    "promoted community affiliation")
T.equal(record.groupID, "group:hydration",
    "promoted group affiliation")
T.equal(record.presenceState, PNC.Const.PRESENCE_ABSTRACT,
    "Core-only actor enters Hoomans as abstract")
T.equal(dirty, 0, "clean lazy promotion must not falsely mark record dirty")

local second, secondStatus = Adapter.HydrateCoreActor(
    actor,
    PsychopatzCore
)
T.truthy(second, secondStatus)
T.equal(secondStatus, "existing", "repeated promotion must be idempotent")
T.equal(records[actor.actorId], second,
    "repeated promotion must preserve record identity")

PNC.Registry = previousRegistry
Actors.DefaultRegistry = previousDefaultRegistry

T.finish("pnc_core_actor_hydration_smoke")
