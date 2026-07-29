local LIVE_BODY =
    "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/Pathing/"
    .. "PNC_LiveBodyControl.lua"
local ANIMATION =
    "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/Visuals/"
    .. "PNC_Animation.lua"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual")
            .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local now = 1000
local authority = true
local gameMode = "Sandbox"

getWorld = function()
    return {
        getGameMode = function() return gameMode end,
    }
end

PNC = {
    Core = {
        Now = function() return now end,
        IsAuthority = function() return authority end,
    },
}

dofile(LIVE_BODY)
dofile(ANIMATION)

local modData = {}
local variables = {}
variables.AttackVariationX = "0.0"
variables.AttackVariationY = "0.0"
local bumpType = ""
local bumpDone = true
local useless = true
local actionState = "idle"
local body = {
    getModData = function()
        return modData
    end,
    getActionStateName = function()
        return actionState
    end,
    getBumpType = function()
        return bumpType
    end,
    setVariable = function(_, key, value)
        variables[key] = value
    end,
    clearVariable = function(_, key)
        variables[key] = nil
    end,
    setBumpType = function(_, value)
        bumpType = value
    end,
    setBumpDone = function(_, value)
        bumpDone = value == true
    end,
    setBumpFall = function() end,
    setRunning = function() end,
    setMoving = function() end,
    setSneaking = function() end,
    setWalkType = function() end,
    setSpeedMod = function() end,
    setAnimatingBackwards = function() end,
    setUseless = function(_, value)
        useless = value
    end,
    isUseless = function()
        return useless
    end,
}
local record = {
    runtime = {
        attackAction = {
            finishAt = 1800,
        },
    },
}

assertEqual(
    PNC.Animation.ResolveBumpType("PNC_Attack1H1"),
    "PNC_Attack1H1",
    "one-handed engine contract"
)
assertEqual(
    PNC.Animation.ResolveBumpType("PNC_Attack2HStamp"),
    "PNC_Attack2HStamp",
    "ground-stomp engine contract"
)
assertEqual(
    PNC.Animation.ResolveBumpType("PNC_AttackRifle"),
    "PNC_AttackRifle",
    "firearm engine contract"
)
assertEqual(
    PNC.Animation.ResolveBumpType("PNC_ClimbWindow"),
    "PNC_ClimbWindow",
    "non-combat bump remains namespaced"
)
assertEqual(
    PNC.Animation.ResolveBumpType("BandageUpperBody"),
    "PNC_BandageUpperBody",
    "unnamespaced action is isolated for PNC"
)

local started, reason =
    PNC.Animation.PlayBump(body, record, "PNC_Attack1H1")
assertEqual(started, true, "bump started")
assertEqual(reason, "bump_type_setter", "bump start mode")
assertEqual(bumpType, "PNC_Attack1H1", "engine bump type written")
assertEqual(bumpDone, false, "stale Java bump completion latch reset")
assertEqual(
    variables.BumpAnimFinished,
    false,
    "stale XML completion latch reset"
)
assertEqual(
    variables.PNCAttackVariationX,
    "1.0",
    "private melee blend scalar initialized"
)
assertEqual(
    variables.PNCAttackVariationY,
    "0.0",
    "private melee blend scalar direction initialized"
)
assertEqual(
    variables.AttackVariationX,
    nil,
    "stale melee X blend scalar cleared"
)
assertEqual(
    variables.AttackVariationY,
    nil,
    "stale melee Y blend scalar cleared"
)
assertEqual(
    useless,
    true,
    "SP combat bump preserves Bandits-style useless shell"
)
assertEqual(
    modData.PNC_BumpActionLease,
    true,
    "body action lease recorded"
)
assertEqual(
    PNC.Animation.IsBumpActionActive(body, now),
    true,
    "animation adapter exposes active body lease"
)
local attackAnimState = variables.PNCAnim
assertEqual(
    PNC.Animation.Apply(body, record, "Run"),
    false,
    "generic locomotion rejected during bump action"
)
assertEqual(
    variables.PNCAnim,
    attackAnimState,
    "generic locomotion overwrote active attack variables"
)
assertEqual(
    PNC.LiveBodyControl.ShouldKeepEngineMovementActive(record, body),
    false,
    "SP attack does not reactivate the engine zombie controller"
)
authority = false
assertEqual(
    PNC.LiveBodyControl.ShouldKeepEngineMovementActive(record, body),
    false,
    "SP local action lease retains useless shell"
)

PNC.Animation.FinishBump(body, true)
assertEqual(
    modData.PNC_BumpReleasePending,
    true,
    "bump release scheduled"
)
now = 1100
assertEqual(
    PNC.Animation.PumpBumpRelease(body, now),
    false,
    "idle action releases completed bump"
)
assertEqual(bumpType, "", "completed bump type cleared")
assertEqual(
    modData.PNC_BumpActionLease,
    nil,
    "completed action lease cleared"
)

gameMode = "Multiplayer"
started = PNC.Animation.PlayBump(
    body,
    record,
    "PNC_Attack1H1"
)
assertEqual(started, true, "MP combat bump started")
assertEqual(
    useless,
    false,
    "MP combat bump keeps replicated ActionContext useful"
)
PNC.Animation.FinishBump(body, true)
now = 1150
PNC.Animation.PumpBumpRelease(body, now)

started = PNC.Animation.PlayBump(
    body,
    record,
    "PNC_ClimbFence",
    { keepManagedUseless = true }
)
assertEqual(started, true, "scripted traversal bump started")
assertEqual(useless, true, "scripted traversal retained safe fake-body mode")
assertEqual(
    modData.PNC_BumpKeepUseless,
    true,
    "scripted traversal body-mode lease"
)
assertEqual(
    PNC.LiveBodyControl.ShouldKeepEngineMovementActive(record, body),
    false,
    "safety audit does not reactivate unsafe native traversal"
)
PNC.Animation.FinishBump(body, true)
now = 1200
assertEqual(
    PNC.Animation.PumpBumpRelease(body, now),
    false,
    "scripted traversal bump released"
)
assertEqual(
    modData.PNC_BumpKeepUseless,
    nil,
    "scripted traversal body-mode lease cleared"
)

now = 1300
started = PNC.Animation.PlayBump(
    body,
    record,
    "PNC_Attack1H1"
)
assertEqual(started, true, "stale-lease scenario started")
bumpType = ""
actionState = "idle"
now = 1651
assertEqual(
    PNC.Animation.IsBumpActionActive(body, now),
    false,
    "cleared engine action retained a sliding idle lease"
)
assertEqual(
    modData.PNC_BumpActionLease,
    nil,
    "stale action lease was not removed"
)
assertEqual(
    PNC.Animation.Apply(body, record, "Walk"),
    true,
    "locomotion did not recover after a cancelled bump"
)
assertEqual(variables.bMoving, true, "recovered body did not animate its legs")

print("pnc_bump_action_lease_smoke: ok")
