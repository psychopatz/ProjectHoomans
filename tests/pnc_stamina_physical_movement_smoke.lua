local FILE =
    "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/"
    .. "Stamina/PNC_Stamina_Movement.lua"

local now = 1000
PNC = {
    Core = {
        Now = function()
            return now
        end,
    },
    Const = {
        STAMINA_MOVE_DRAIN_WALK = 3,
        STAMINA_MOVE_DRAIN_RUN = 10,
        STAMINA_MOVE_DRAIN_SNEAK = 4,
        STAMINA_MOVE_DRAIN_CRAWL = 2.2,
        STAMINA_MOVE_DRAIN_RECOVERY_WALK = 1.4,
        STAMINA_MOVE_DRAIN_RECOVERY_SNEAK = 1.8,
        STAMINA_MOVE_PROGRESS_LEASE_MS = 750,
        STAMINA_MOVE_EXHAUST_PAUSE = 0.2,
        STAMINA_MOVE_EXHAUST_RESUME = 0.35,
        STAMINA_MOVE_RECOVERY_PAUSE = 0.12,
        STAMINA_MOVE_RECOVERY_RESUME = 0.25,
        STAMINA_MOVE_CRAWL_PAUSE = 0.08,
        STAMINA_MOVE_CRAWL_RESUME = 0.18,
        STAMINA_SPRINT_BREATHER_MS = 1500,
    },
    Stamina = {},
}

dofile(FILE)

PNC.Stamina.GetRatio = function(recordValue)
    return recordValue.stamina.current
        / recordValue.stamina.max
end

local record = {
    stamina = {
        current = 100,
        max = 100,
        encumbranceDrainMultiplier = 1,
    },
    runtime = {
        pathing = {
            phase = "active",
            profileKey = "run",
            staminaMode = "travel",
            lastPhysicalMoveAt = 0,
        },
    },
}

local drain = PNC.Stamina.ApplyMovementDrain(record, 1)
assert(drain == 0 and record.stamina.current == 100,
    "movement intent drained stamina without physical progress")

record.runtime.pathing.lastPhysicalMoveAt = now
drain = PNC.Stamina.ApplyMovementDrain(record, 1)
assert(drain == 10 and record.stamina.current == 90,
    "recent physical running progress did not drain stamina")

now = now + 751
drain = PNC.Stamina.ApplyMovementDrain(record, 1)
assert(drain == 0 and record.stamina.current == 90,
    "stalled delegated movement continued draining stamina")

record.stamina.current = 10
record.runtime.moveExhausted = false
record.runtime.sprintSlowUntil = 0
local profile = PNC.Stamina.BuildMovementProfile(
    record,
    "run",
    {
        now = now,
        moving = true,
        staminaMode = "travel",
    }
)
assert(profile.profileKey == "recovery_walk",
    "ordinary exhausted travel invented a crouch posture")

record.runtime.sprintSlowUntil = 0
profile = PNC.Stamina.BuildMovementProfile(
    record,
    "run",
    {
        now = now,
        moving = true,
        staminaMode = "sneak",
    }
)
assert(profile.profileKey == "recovery_sneak",
    "explicit stealth recovery lost its crouch posture")

print("pnc_stamina_physical_movement_smoke: ok")
