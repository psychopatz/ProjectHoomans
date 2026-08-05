local FILE =
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Combat/PNC_Combat_AttackActions.lua"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual")
            .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local now = 1000
local replayCount = 0
local bumpTypeWritten = false
local targetBody = {
    isDead = function() return false end,
    getX = function() return 1 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}
local body = {
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    getActionStateName = function() return "pathfind" end,
    getBumpType = function() return "PNC_Attack1H1" end,
    setBumpType = function(_, value)
        bumpTypeWritten = true
    end,
    getVariableBoolean = function() return false end,
}

PNC = {
    Core = {
        Now = function() return now end,
        ResolvePlayerByOnlineID = function() return nil end,
        ResolvePlayerByUsername = function() return nil end,
        Log = function() end,
    },
    Const = {
        MELEE_RANGE = 1.3,
        MELEE_HIT_TOLERANCE = 0.12,
    },
    Registry = {
        Get = function() return nil end,
        GetLiveZombie = function() return nil end,
    },
    Perception = {
        FindZombieByID = function() return targetBody end,
        CanSeeWorldObject = function() return true, "clear" end,
    },
    Animation = {
        PlayBump = function()
            replayCount = replayCount + 1
        end,
        FinishBump = function() end,
    },
    Combat = {
        Internal = {
            ATTACK_TIMINGS = {
                melee = { hitDelay = 320, duration = 760 },
            },
            faceTarget = function() end,
        },
    },
    PathService = {
        IsTraversalActive = function() return false end,
    },
}

dofile(FILE)

local record = {
    id = "animation_retry",
    alive = true,
    runtime = {
        attackAction = {
            attackKind = "melee",
            attackType = "melee",
            anim = "PNC_Attack1H1",
            hitAt = 1400,
            finishAt = 1800,
            hitDone = false,
            animationRetries = 0,
            animationRetryAt = 1000,
            target = {
                kind = "zombie",
                zombieId = "zed",
                worldObject = targetBody,
            },
        },
    },
}

local active, reason = PNC.Combat.PumpAttackAction(record, body)
assertEqual(active, true, "attack remains active during retry")
assertEqual(reason, "attack_anim_melee", "attack retry reason")
assertEqual(
    bumpTypeWritten,
    false,
    "attack pump does not rewrite BumpType"
)
assertEqual(replayCount, 0, "attack pump does not replay the bump trigger")
assertEqual(
    record.runtime.attackAction.animationRetries,
    0,
    "animation retry remains disabled"
)

print("pnc_attack_animation_retry_smoke: ok")
