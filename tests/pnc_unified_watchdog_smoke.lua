local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local now = 1000
getWorld = function()
    return {
        getGameMode = function() return "Sandbox" end,
    }
end

ZombieIdleState = {
    instance = function() return "idle_state" end,
}

PNC = {
    Core = {
        Now = function() return now end,
        IsAuthority = function() return true end,
        LogWarn = function() end,
    },
}

T.load("ProjectHoomans", "shared", "PNC/Core/Pathing/PNC_LiveBodyControl.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Visuals/PNC_Animation.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Watchdog/PNC_Watchdog.lua")

-- Real PZ Build 42 body mock: changeState() changes legacy state only,
-- while ActionContext stays in "bumped" until BumpAnimFinished==true and
-- BumpType=="" AND useless==false on the next engine tick.
local function newBody()
    local state = {
        modData = { PNC_UUID = "npcJarrodpatz_X2I3" },
        vars = {},
        bumpType = "",
        bumpDone = false,
        useless = true,
        actionState = "idle",
        legacyState = "idle_state",
        events = {},
    }
    local body = {
        _s = state,
        getModData = function() return state.modData end,
        getActionStateName = function() return state.actionState end,
        getBumpType = function() return state.bumpType end,
        setBumpType = function(_, v) state.bumpType = tostring(v or "") end,
        setBumpDone = function(_, v) state.bumpDone = v == true end,
        setBumpFall = function() end,
        setVariable = function(_, k, v) state.vars[k] = v end,
        getVariableString = function(_, k) return tostring(state.vars[k] or "") end,
        clearVariable = function(_, k) state.vars[k] = nil end,
        reportEvent = function(_, ev) state.events[#state.events + 1] = ev end,
        changeState = function(_, st) state.legacyState = st end,
        setRunning = function() end,
        setMoving = function() end,
        setSneaking = function() end,
        setWalkType = function() end,
        setSpeedMod = function() end,
        setAnimatingBackwards = function() end,
        setUseless = function(_, v) state.useless = v == true end,
        isUseless = function() return state.useless end,
        setTarget = function() end,
        setTargetSeenTime = function() end,
        setEatBodyTarget = function() end,
        setThumpTarget = function() end,
        clearAggroList = function() end,
        setAttackedBy = function() end,
        setNoTeeth = function() end,
        setZombiesDontAttack = function() end,
        setReanimatedForGrappleOnly = function() end,
    }
    function body:stepActionContext()
        if state.actionState == "bumped"
            and state.useless == false
            and state.vars.BumpAnimFinished == true
        then
            state.actionState = "idle"
            state.vars.BumpAnimFinished = nil
        end
        if state.actionState == "idle" and state.bumpType ~= "" then
            state.actionState = "bumped"
        end
    end
    return body
end

-- 1. Expired bump lease must hand off to FinishBump instead of stranding bumped.
local body = newBody()
local record = { id = "npcJarrodpatz_X2I3", alive = true, runtime = {} }
PNC.Animation.PlayBump(body, record, "Loot", { leaseUntil = 2000 })
body._s.actionState = "bumped"
T.equal(body._s.bumpType, "PNC_Loot", "medical loot bump active")

now = 2500
local active = PNC.Animation.IsBumpActionActive(body, now)
T.falsy(active, "expired lease reports inactive")
T.equal(body._s.modData.PNC_BumpReleasePending, true,
    "expired lease hands off to PumpBumpRelease")
T.equal(body._s.vars.BumpAnimFinished, true,
    "expired lease sets BumpAnimFinished")

-- 2. PumpBumpRelease keeps pumping past hard timeout if ActionContext hasn't stepped yet.
now = 3300
local stillReleasing = PNC.Animation.PumpBumpRelease(body, now)
T.equal(stillReleasing, true, "PumpBumpRelease keeps retrying while still bumped")
T.equal(body._s.bumpType, "", "hard timeout clears BumpType")
T.equal(body._s.useless, false, "hard timeout keeps body useful so ActionContext steps")
body:stepActionContext()
T.equal(body._s.actionState, "idle", "ActionContext transitions cleanly to idle")
now = 3350
T.equal(PNC.Animation.PumpBumpRelease(body, now), false, "release completes once idle")

-- 3. SuppressZombieState on an orphaned bumped body clears BumpType + sets latches + keeps useful.
local body2 = newBody()
body2._s.actionState = "bumped"
body2._s.bumpType = "PNC_LootLow"
body2._s.useless = true
local suppressed = PNC.LiveBodyControl.SuppressZombieState(body2, nil, now, true)
T.truthy(suppressed, "SuppressZombieState handles bumped")
T.equal(body2._s.bumpType, "", "SuppressZombieState clears BumpType")
T.equal(body2._s.vars.BumpAnimFinished, true, "SuppressZombieState sets BumpAnimFinished")
T.equal(body2._s.useless, false, "SuppressZombieState allows ActionContext tick")
body2:stepActionContext()
T.equal(body2._s.actionState, "idle", "orphaned bumped exits to idle on next tick")

-- 4. Unified Watchdog.AuditActor recovers orphaned bumped pose, selfTreatment, medicalCare, and patient hold.
local body3 = newBody()
body3._s.actionState = "bumped"
body3._s.bumpType = "PNC_Loot"
local rec3 = { id = "npcJarrodpatz_X2I3", alive = true, runtime = {} }
T.truthy(PNC.Watchdog.AuditActor(rec3, body3, now), "Watchdog recovers orphaned bumped pose")
T.equal(body3._s.bumpType, "", "Watchdog cleared orphaned BumpType")
body3:stepActionContext()
T.equal(body3._s.actionState, "idle", "Watchdog orphaned bumped exited to idle")

local recTreat = {
    id = "npcSelf",
    alive = true,
    runtime = {
        tacticalState = "self_bandage",
        selfTreatment = { phase = "bandaging", startedAt = 1000, finishAt = 2000 },
    },
}
now = 4000
T.truthy(PNC.Watchdog.AuditActor(recTreat, newBody(), now),
    "Watchdog recovers expired selfTreatment")
T.equal(recTreat.runtime.selfTreatment.phase, "idle", "selfTreatment reset to idle")
T.equal(recTreat.runtime.tacticalState, nil, "selfTreatment tacticalState cleared")

local recPatient = {
    id = "npcPatient",
    alive = true,
    runtime = {
        receivingMedicalCareBy = "npcGone",
        receivingMedicalCareUntil = 2000,
    },
}
PNC.Watchdog.AuditActor(recPatient, newBody(), now)
T.equal(recPatient.runtime.receivingMedicalCareBy, nil,
    "Watchdog clears expired patient hold")

-- 5. Unified Task snapshot normalization promotes invalid=true to watchable+forceRecovery.
local norm = PNC.Watchdog.NormalizeTaskSnapshot(
    { invalid = true, phase = "WAITING" },
    { sourceDomain = "NeedFacility" }
)
T.equal(norm.watchable, true, "invalid snapshot becomes watchable")
T.equal(norm.forceRecovery, true, "invalid snapshot forces recovery")
T.truthy((PNC.Watchdog.GetDiagnostics().counters.total or 0) >= 3,
    "unified watchdog diagnostics record recoveries")
