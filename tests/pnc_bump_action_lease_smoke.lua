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
local bumpType = ""
local useless = true
local actionState = "idle"
local body = {
    getModData = function()
        return modData
    end,
    getActionStateName = function()
        return actionState
    end,
    setVariable = function(_, key, value)
        variables[key] = value
    end,
    setBumpType = function(_, value)
        bumpType = value
    end,
    setBumpDone = function() end,
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
    "Attack1H1",
    "one-handed engine contract"
)
assertEqual(
    PNC.Animation.ResolveBumpType("PNC_Attack2HStamp"),
    "Attack2HStamp",
    "ground-stomp engine contract"
)
assertEqual(
    PNC.Animation.ResolveBumpType("PNC_AttackRifle"),
    "AttackRifle",
    "firearm engine contract"
)
assertEqual(
    PNC.Animation.ResolveBumpType("PNC_ClimbWindow"),
    "PNC_ClimbWindow",
    "non-combat bump remains namespaced"
)

local started, reason =
    PNC.Animation.PlayBump(body, record, "PNC_Attack1H1")
assertEqual(started, true, "bump started")
assertEqual(reason, "bump_type_setter", "bump start mode")
assertEqual(bumpType, "Attack1H1", "engine bump type written")
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

print("pnc_bump_action_lease_smoke: ok")
