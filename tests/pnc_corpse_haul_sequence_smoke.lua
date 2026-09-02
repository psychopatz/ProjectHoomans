local T = require "tests/support/test"

T.addPackagePaths()

local clock = 1000
local revision = 0
local requests = {}
local halted = 0
local faced = 0

PNC = {
    Core = { Now = function() return clock end },
    WorkDefinitions = { JOB_BY_OPERATION = {
        CORPSE_HAUL = "CorpseHaul",
    } },
    BehaviorCommon = {
        ClearCombatTarget = function() end,
        HaltMovement = function() halted = halted + 1 end,
    },
    AnimationScenes = {
        Request = function(record, _, sceneId, options)
            revision = revision + 1
            requests[#requests + 1] = {
                id = sceneId, reason = options.reason,
            }
            record.runtime.animationScene = {
                id = sceneId, revision = revision,
            }
            return true, { revision = revision }
        end,
    },
}

local Sequence = T.load("ProjectHoomans", "shared",
    "PNC/Core/Production/PNC_WorkSequence.lua")
Sequence.Register("CORPSE_HAUL", {
    actions = {
        GRAB_PENDING = {
            sceneId = "production.corpse_grab", durationMs = 900,
            reason = "corpse_haul_grab",
        },
        DROP_PENDING = {
            sceneId = "production.corpse_drop", durationMs = 900,
            reason = "corpse_haul_drop",
        },
    },
})

local zombie = {
    faceLocationF = function() faced = faced + 1 end,
}
local record = { runtime = {} }
local order = {
    operation = "CORPSE_HAUL", phase = "GRAB_PENDING", x = 40, y = 40,
}

T.equal(Sequence.Status(record, order), "pending",
    "a new corpse interaction starts pending")
T.truthy(Sequence.Tick(record, zombie, order),
    "the sequence requests the grab presentation")
T.equal(Sequence.Status(record, order), "running",
    "a requested corpse interaction remains running")
T.equal(requests[1].id, "production.corpse_grab",
    "grab uses the reusable animation scene")
T.equal(requests[1].reason, "corpse_haul_grab",
    "grab carries an operation-specific reason")
T.truthy(halted > 0, "an interaction halts movement")
T.truthy(faced > 0, "an interaction faces its target")

local sceneRevision = record.runtime.animationScene.revision
record.runtime.animationScene = nil
record.runtime.lastAnimationScene = {
    id = "production.corpse_grab", revision = sceneRevision,
    reason = "completed",
}
clock = 1900
T.truthy(Sequence.Tick(record, zombie, order),
    "the sequence accepts a completed grab presentation")
T.equal(Sequence.Status(record, order), "completed",
    "completed grab presentation advances the sequence state")
T.falsy(record.runtime.workSequence.finishAt,
    "sequence does not duplicate animation-scene timing")
T.falsy(record.runtime.workSequence.completedAt,
    "sequence does not retain unused completion timestamps")

order.phase = "DROP_PENDING"
T.equal(Sequence.Status(record, order), "pending",
    "a new drop phase gets a fresh sequence state")
T.truthy(Sequence.Tick(record, zombie, order),
    "the sequence requests the drop presentation")
T.equal(requests[2].id, "production.corpse_drop",
    "drop uses the reusable animation scene")

T.finish("pnc_corpse_haul_sequence_smoke")
