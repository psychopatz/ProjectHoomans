local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local now = 1000

PNC = {
    Core = {
        Now = function() return now end,
    },
    Const = {
        PRESENCE_LIVE = "LIVE",
    },
    ActorControl = {
        CanWrite = function() return true end,
    },
}

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Behaviors/PNC_Behavior_MoveIntent.lua"
)

local record = {
    id = "movement-intent-a",
    presenceState = "LIVE",
    x = 0,
    y = 0,
    z = 0,
    runtime = {},
}
local combatNavigation = {
    navigationPolicy = "combat",
    navigationProvider = "engine_path",
}
local retreatOptions = {
    source = "combat_retreat",
    priority = 100,
    lockKey = "combat_retreat",
    lockUntil = 2000,
}

local accepted, reason = PNC.BehaviorMoveIntent.RequestMove(
    record,
    -4,
    0,
    0,
    "walk",
    0.8,
    "recovering_stamina",
    combatNavigation,
    nil,
    retreatOptions
)
T.truthy(accepted, "retreat intent was rejected")
T.equal(reason, nil, "initial intent changed its return contract")
local firstRevision = record.runtime.moveIntent.revision

accepted = PNC.BehaviorMoveIntent.RequestMove(
    record,
    -4,
    0,
    0,
    "walk",
    0.8,
    "recovering_stamina",
    combatNavigation,
    nil,
    retreatOptions
)
T.truthy(accepted, "same retreat owner could not refresh its intent")
T.equal(record.runtime.moveIntent.revision, firstRevision,
    "same retreat intent created a duplicate revision")

accepted, reason = PNC.BehaviorMoveIntent.RequestMove(
    record,
    5,
    5,
    0,
    "walk",
    0.8,
    "follow_owner_walk"
)
T.falsy(accepted, "lower-priority movement replaced a locked retreat")
T.equal(reason, "movement_intent_locked",
    "locked movement exposed the wrong rejection reason")
T.equal(record.runtime.moveIntent.reason, "recovering_stamina",
    "locked retreat intent was overwritten")

T.truthy(
    PNC.BehaviorMoveIntent.ReleaseLock(record, "combat_retreat"),
    "retreat movement lock could not be released"
)
accepted = PNC.BehaviorMoveIntent.RequestMove(
    record,
    5,
    5,
    0,
    "walk",
    0.8,
    "follow_owner_walk"
)
T.truthy(accepted, "movement could not resume after retreat release")
T.equal(record.runtime.moveIntent.source, "behavior",
    "released movement did not return to the shared behavior source")

PNC.PathService = {
    Internal = {
        Core = PNC.Core,
        isAtGoal = function() return false end,
        buildGoal = function(x, y, z, mode, stopDistance)
            return {
                x = x,
                y = y,
                z = z,
                mode = mode,
                stopDistance = stopDistance,
            }
        end,
    },
}
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Pathing/PNC_PathService/Motion/PNC_PathService_MotionApi.lua"
)

local directRevision = record.runtime.moveIntent.revision
accepted = PNC.PathService.MoveToward(
    record,
    nil,
    7,
    7,
    0,
    "walk",
    0.8,
    "follow_owner_walk"
)
T.truthy(accepted, "direct live path movement was not accepted")
T.equal(record.runtime.moveIntent.x, 7,
    "direct live path movement bypassed the shared intent destination")
T.equal(record.runtime.moveIntent.revision, directRevision + 1,
    "direct live path movement did not create one shared revision")

local deduplicatedRevision = record.runtime.moveIntent.revision
PNC.PathService.MoveToward(
    record,
    nil,
    7,
    7,
    0,
    "walk",
    0.8,
    "follow_owner_walk"
)
T.equal(record.runtime.moveIntent.revision, deduplicatedRevision,
    "direct live path movement reintroduced duplicate revisions")

T.finish("pnc_movement_intent_arbitration_smoke")
