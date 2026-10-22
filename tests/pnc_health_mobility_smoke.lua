local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "PsychopatzCore", "common" },
})

local now = 1000

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function ensureHealth(record)
    record.health = record.health or {
        current = 100,
        max = 100,
        state = "normal",
        lastDamageAt = 0,
        downedAt = 0,
        recentDamageUntil = 0,
        reviveUntil = 0,
        reviveProtectionUntil = 0,
        body = { parts = {}, wounds = {} },
    }
    return record.health
end

PNC = {
    Core = {
        Now = function() return now end,
        IsAuthority = function() return true end,
        Clamp = clamp,
        Distance = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return math.sqrt(dx * dx + dy * dy)
        end,
    },
    Const = {
        DEFAULT_HP_MAX = 100,
        DEBUG_COMBAT_HOLD_MS = 2500,
        RECENT_DAMAGE_SHOW_MS = 4000,
        LIMP_HEALTH_RATIO = 0.40,
        LIMP_WALK_SPEED = 0.44,
    },
    Sandbox = {
        CanZombieTargetRecord = function() return true end,
    },
    Registry = {
        MarkDirty = function() end,
    },
    Health = {
        Internal = {},
        Ensure = ensureHealth,
        MarkRecentDamage = function(record, damageAt)
            record.health.lastDamageAt = damageAt
        end,
    },
    NPCWounds = {
        Internal = {},
    },
}

local Wounds = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Definitions.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_BodyState.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Health/PNC_Health/PNC_Health_Damage.lua"
)

PNC.Health.EnterIncapacitated = function(record)
    record.health.state = "incapacitated"
    return true
end

PNC.Health.Kill = function(record, _, reason)
    record.alive = false
    record.health.state = "dead"
    record.health.current = 0
    record.deathReason = reason
    return true
end

local function makeRecord(id)
    local record = {
        id = id,
        alive = true,
        runtime = {},
        health = {
            current = 100,
            max = 100,
            state = "normal",
            body = { parts = {}, wounds = {} },
        },
    }
    Wounds.Ensure(record)
    return record
end

local headVictim = makeRecord("head_victim")
local applied, reason = PNC.Health.ApplyDamage(
    headVictim,
    nil,
    { amount = 50, partId = "Head", type = "test_head" }
)
T.equal(applied, true, "head damage was accepted")
T.equal(reason, "killed", "zero head health is lethal")
T.equal(headVictim.health.state, "dead", "head failure enters dead state")
T.equal(headVictim.deathReason, "vital_part_Head",
    "head death keeps a stable reason")

local torsoVictim = makeRecord("torso_victim")
applied, reason = PNC.Health.ApplyDamage(
    torsoVictim,
    nil,
    { amount = 50, partId = "Torso_Upper", type = "test_torso" }
)
T.equal(applied, true, "torso damage was accepted")
T.equal(reason, "killed", "zero upper torso health is lethal")
T.equal(torsoVictim.health.state, "dead", "torso failure enters dead state")

local legVictim = makeRecord("leg_victim")
applied, reason = PNC.Health.ApplyDamage(
    legVictim,
    nil,
    { amount = 30, partId = "LowerLeg_L", type = "test_leg" }
)
T.equal(applied, true, "leg damage was accepted")
T.equal(reason, "applied", "non-vital leg damage does not kill")
local mobility = Wounds.GetMobilityState(legVictim)
T.truthy(mobility, "damaged leg produces a mobility state")
T.equal(mobility.mode, "limp", "damaged leg selects limp mode")
T.equal(mobility.side, "left", "mobility state preserves the injured side")
T.equal(mobility.partId, "LowerLeg_L", "mobility state preserves the injured part")

Wounds.ApplyBodyHealing(legVictim, 30, "LowerLeg_L")
T.falsy(Wounds.GetMobilityState(legVictim),
    "healed leg releases the limp state")

PNC.Stamina = {
    BuildMovementProfile = function(_, requestedMode, options)
        return {
            profileKey = requestedMode,
            staminaMode = options and options.staminaMode or "travel",
            ratio = 1,
            moveExhausted = false,
        }
    end,
}
PNC.LocomotionProfiles = nil
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Pathing/PNC_LocomotionProfiles.lua"
)
local profiles = PNC.LocomotionProfiles
local mobilityRecord = makeRecord("mobility_path")
mobilityRecord.health.body.parts.UpperLeg_R.current = 30
local lane = {
    mode = "run",
    phase = "active",
    stopDistance = 0.7,
}
local goal = { x = 10, y = 0, z = 0, mode = "run" }
PNC.PathService = {
    Internal = {
        Core = PNC.Core,
        LocomotionProfiles = profiles,
        RUN_STOP_DISTANCE = 1.2,
        RUN_START_DISTANCE = 4.0,
    },
}
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Pathing/PNC_PathService/Context/PNC_PathService_Context_Goals.lua"
)
local mode = PNC.PathService.Internal.computeResolvedMode(
    mobilityRecord,
    lane,
    { getX = function() return 0 end, getY = function() return 0 end },
    goal
)
T.equal(mode, "limp", "pathing resolves injured NPCs to limp mode")
lane.resolvedMode = mode
local profile = profiles.Resolve(
    mobilityRecord,
    lane,
    nil,
    goal,
    now
)
T.equal(profile.walkType, "Limp", "limp profile selects limp animation")
T.equal(profile.engineWalkType, "Limp",
    "limp profile selects the engine walk type")
T.equal(profile.isRunning, false, "limping never remains a run profile")
T.near(profile.speed, 0.44, 0.000001, "limp profile slows movement")

local animationWrites = {}
local zombie = {
    setVariable = function(_, key, value)
        animationWrites[key] = value
    end,
    setMoving = function() end,
    setSneaking = function() end,
    setWalkType = function(_, value)
        animationWrites.engineWalkType = value
    end,
    setSpeedMod = function() end,
    setAnimatingBackwards = function() end,
}
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Visuals/PNC_Animation/PNC_Animation_LocomotionVariables.lua"
)
local Animation = PNC.Animation
Animation.Internal.setLocomotionVars(zombie, profile, true, profile.animSpeed)
Animation.Internal.applyWalkType(zombie, profile.engineWalkType, profile.animSpeed)
T.equal(animationWrites.PNCWalkType, "Limp",
    "animation writes the limp walk type")
T.equal(animationWrites.engineWalkType, "Limp",
    "animation applies the engine limp walk type")

T.finish("pnc_health_mobility_smoke")
