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
    },
    Stamina = {},
}

dofile(FILE)

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

print("pnc_stamina_physical_movement_smoke: ok")
