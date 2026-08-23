local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local LIVE_BODY =
    T.path("ProjectHoomans", "shared", "PNC/Core/Pathing/")
    .. "PNC_LiveBodyControl.lua"
local ANIMATION =
    T.path("ProjectHoomans", "shared", "PNC/Core/Visuals/")
    .. "PNC_Animation.lua"

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

T.load(LIVE_BODY)
T.load(ANIMATION)

local modData = {}
local variables = {}
variables.AttackVariationX = "0.0"
variables.AttackVariationY = "0.0"
local bumpType = ""
local bumpDone = true
local useless = true
local actionState = "idle"
ZombieIdleState = {
    instance = function() return "idle_state" end,
}
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
    changeState = function(_, value)
        T.equal(value, "idle_state", "forced bump recovery state")
        actionState = "idle"
    end,
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

T.equal(
    PNC.Animation.ResolveBumpType("PNC_Attack1H1"),
    "PNC_Attack1H1",
    "one-handed engine contract"
)
T.equal(
    PNC.Animation.ResolveBumpType("PNC_Attack2HStamp"),
    "PNC_Attack2HStamp",
    "ground-stomp engine contract"
)
T.equal(
    PNC.Animation.ResolveBumpType("PNC_AttackRifle"),
    "PNC_AttackRifle",
    "firearm engine contract"
)
T.equal(
    PNC.Animation.ResolveBumpType("PNC_ClimbWindow"),
    "PNC_ClimbWindow",
    "non-combat bump remains namespaced"
)
T.equal(
    PNC.Animation.ResolveBumpType("BandageUpperBody"),
    "PNC_BandageUpperBody",
    "unnamespaced action is isolated for PNC"
)

local started, reason =
    PNC.Animation.PlayBump(body, record, "PNC_Attack1H1")
T.equal(started, true, "bump started")
T.equal(reason, "bump_type_setter", "bump start mode")
T.equal(bumpType, "PNC_Attack1H1", "engine bump type written")
T.equal(bumpDone, false, "stale Java bump completion latch reset")
T.equal(
    variables.BumpAnimFinished,
    false,
    "stale XML completion latch reset"
)
T.equal(
    variables.PNCAttackVariationX,
    "1.0",
    "private melee blend scalar initialized"
)
T.equal(
    variables.PNCAttackVariationY,
    "0.0",
    "private melee blend scalar direction initialized"
)
T.equal(
    variables.AttackVariationX,
    nil,
    "stale melee X blend scalar cleared"
)
T.equal(
    variables.AttackVariationY,
    nil,
    "stale melee Y blend scalar cleared"
)
T.equal(
    useless,
    true,
    "SP combat bump preserves Bandits-style useless shell"
)
T.equal(
    modData.PNC_BumpActionLease,
    true,
    "body action lease recorded"
)
T.equal(
    PNC.Animation.IsBumpActionActive(body, now),
    true,
    "animation adapter exposes active body lease"
)
local attackAnimState = variables.PNCAnim
T.equal(
    PNC.Animation.Apply(body, record, "Run"),
    false,
    "generic locomotion rejected during bump action"
)
T.equal(
    variables.PNCAnim,
    attackAnimState,
    "generic locomotion overwrote active attack variables"
)
T.equal(
    PNC.LiveBodyControl.ShouldKeepEngineMovementActive(record, body),
    false,
    "SP attack does not reactivate the engine zombie controller"
)
authority = false
T.equal(
    PNC.LiveBodyControl.ShouldKeepEngineMovementActive(record, body),
    false,
    "SP local action lease retains useless shell"
)

PNC.Animation.FinishBump(body, true)
T.equal(
    modData.PNC_BumpReleasePending,
    true,
    "bump release scheduled"
)
now = 1100
T.equal(
    PNC.Animation.PumpBumpRelease(body, now),
    false,
    "idle action releases completed bump"
)
T.equal(bumpType, "", "completed bump type cleared")
T.equal(
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
T.equal(started, true, "MP combat bump started")
T.equal(
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
T.equal(started, true, "scripted traversal bump started")
T.equal(useless, true, "scripted traversal retained safe fake-body mode")
T.equal(
    modData.PNC_BumpKeepUseless,
    true,
    "scripted traversal body-mode lease"
)
T.equal(
    PNC.LiveBodyControl.ShouldKeepEngineMovementActive(record, body),
    false,
    "safety audit does not reactivate unsafe native traversal"
)
PNC.Animation.FinishBump(body, true)
now = 1200
T.equal(
    PNC.Animation.PumpBumpRelease(body, now),
    false,
    "scripted traversal bump released"
)
T.equal(
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
T.equal(started, true, "stale-lease scenario started")
bumpType = ""
actionState = "idle"
now = 1651
T.equal(
    PNC.Animation.IsBumpActionActive(body, now),
    false,
    "cleared engine action retained a sliding idle lease"
)
T.equal(
    modData.PNC_BumpActionLease,
    nil,
    "stale action lease was not removed"
)
T.equal(
    PNC.Animation.Apply(body, record, "Walk"),
    true,
    "locomotion did not recover after a cancelled bump"
)
T.equal(variables.bMoving, true, "recovered body did not animate its legs")

now = 2000
actionState = "bumped"
started = PNC.Animation.PlayBump(
    body,
    record,
    "PNC_Attack1H1"
)
T.equal(started, true, "stuck bump scenario started")
PNC.Animation.FinishBump(body, true)
now = 2400
T.equal(
    PNC.Animation.PumpBumpRelease(body, now),
    true,
    "bumped state was force-cleared before its recovery grace"
)
now = 2800
T.equal(
    PNC.Animation.PumpBumpRelease(body, now),
    false,
    "stuck bumped state survived the hard recovery timeout"
)
T.equal(bumpType, "", "stuck bump selector was not cleared")
T.equal(actionState, "idle", "stuck bump did not return to idle")
T.equal(
    modData.PNC_BumpActionLease,
    nil,
    "stuck bump retained its body action lease"
)
T.finish("pnc_bump_action_lease_smoke")

T.finish("pnc_bump_action_lease_smoke")
