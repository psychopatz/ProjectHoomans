local T = require "tests/support/test"

PNC = {}
local Bridge = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Director/PNC_CoreGroupTraversalBridge.lua"
)
local ActorJourney = require
    "PsychopatzCore/Actors/PsychopatzActorJourney"

local legacy = {
    id = "agroup_bridge",
    state = "TRAVELING",
    location = {
        id = "aloc_origin",
        type = "SETTLEMENT",
        x = 0, y = 0, z = 0,
    },
    targetLocation = {
        id = "aloc_target",
        type = "SETTLEMENT",
        x = 100, y = 0, z = 0,
    },
    stateStartedAt = 10,
    stateEndsAt = 20,
    memberIds = { "actor_a", "actor_b" },
}

local migrated, migrateReason = Bridge.Ensure(legacy, 15)
T.truthy(migrated, migrateReason)
T.equal(migrateReason, "legacy_migrated",
    "legacy travel should migrate exactly once")
T.equal(migrated.groupID, legacy.id, "group journey owner")
T.near(migrated.progress, 0.5, 0.0001,
    "legacy timing should map to Core progress")

local projected = assert(Bridge.Project(legacy, 15))
T.near(projected.x, 50, 0.0001,
    "group projection should use Core journey")

local memberPoint, memberSource =
    Bridge.ProjectMember(legacy, "actor_a", nil, 15)
T.truthy(memberPoint, "member projection missing")
T.equal(memberSource, "group",
    "normal member must inherit group journey")
T.near(memberPoint.x, 50, 0.0001,
    "normal member should share group position")

local actorOverride = assert(ActorJourney.New(
    "actor_a",
    {
        origin = { x = 0, y = 50, z = 0 },
        destination = { x = 100, y = 50, z = 0 },
        speed = 10,
        startAt = 10,
    },
    10
))
local overridePoint, overrideSource = Bridge.ProjectMember(
    legacy,
    "actor_a",
    {
        location = { position = { x = 0, y = 50, z = 0 } },
        journey = actorOverride,
    },
    15
)
T.equal(overrideSource, "actor_override",
    "separated actor must keep actor-owned travel")
T.near(overridePoint.x, 50, 0.0001, "override x")
T.near(overridePoint.y, 50, 0.0001, "override y")

local missing, missingReason = Bridge.ProjectMember(
    legacy, "actor_missing", nil, 15)
T.falsy(missing, "non-member projection must reject")
T.equal(missingReason, "group_member_not_found",
    "non-member rejection reason")

local arrived = assert(Bridge.Advance(legacy, 20))
T.equal(arrived.state, "arrived",
    "Core journey should own arrival timing")
T.near(arrived.progress, 1, 0.0001, "arrival progress")

local fresh = {
    id = "agroup_fresh",
    location = {
        id = "aloc_origin",
        x = 0, y = 0, z = 0,
    },
    memberIds = { "actor_c" },
}
local begun = assert(Bridge.Begin(
    fresh,
    { id = "aloc_target", x = 60, y = 0, z = 0 },
    6,
    100
))
T.equal(begun.state, "en_route", "fresh journey starts")
T.near(begun.eta, 106, 0.0001, "fresh journey eta")
T.near(fresh.stateEndsAt, 106, 0.0001,
    "legacy end time is compatibility summary only")

T.finish("pnc_core_group_traversal_bridge_smoke")
