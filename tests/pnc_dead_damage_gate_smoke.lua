local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "PsychopatzCore", "common" },
})

local now = 1000

PNC = {
    Core = {
        Now = function() return now end,
        IsAuthority = function() return true end,
        Clamp = function(value, minimum, maximum)
            return math.max(minimum, math.min(maximum, value))
        end,
    },
    Const = {
        DEFAULT_HP_MAX = 100,
        RECENT_DAMAGE_SHOW_MS = 4000,
        DEBUG_COMBAT_HOLD_MS = 1000,
        INCAPACITATED_GRACE_MS = 1000,
        PRESENCE_LIVE = "live",
        PRESENCE_CORPSE = "corpse",
    },
    Sandbox = {},
    Registry = {},
}

SandboxVars = nil
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Base/PNC_Sandbox.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Health/PNC_Health.lua"
)

local deadRecord = {
    id = "dead_gate",
    alive = false,
    presenceState = "corpse",
    runtime = {},
    health = { state = "dead", current = 0, max = 100 },
}
local liveRecord = {
    id = "live_gate",
    alive = true,
    presenceState = "live",
    runtime = {},
    health = { state = "normal", current = 100, max = 100 },
}
local deadBody = {
    isDead = function() return true end,
}
local liveBody = {
    isDead = function() return false end,
}

T.falsy(
    PNC.Sandbox.CanZombieTargetRecord(deadRecord, now),
    "dead records remain outside the zombie target set"
)
T.truthy(PNC.Health.IsDead(deadRecord, liveBody),
    "dead registry state is authoritative")
T.truthy(PNC.Health.IsDead(liveRecord, deadBody),
    "dead engine body is authoritative")
T.falsy(
    PNC.Health.ApplyDamage(deadRecord, liveBody, {
        amount = 10,
        attackerKind = "zombie",
    }),
    "damage cannot be applied to a dead record"
)
T.falsy(
    PNC.Health.ApplyDamage(liveRecord, deadBody, {
        amount = 10,
        attackerKind = "zombie",
    }),
    "damage cannot be applied through a dead engine body"
)
T.falsy(PNC.Health.ApplyStrainDamage(deadRecord, liveBody, 10, 0.75, "strain"),
    "strain cannot be applied to a dead record")
T.falsy(PNC.Health.Kill(deadRecord, liveBody, "repeat_death"),
    "death conversion is idempotent")

T.finish("pnc_dead_damage_gate_smoke")
