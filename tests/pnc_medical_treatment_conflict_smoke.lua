local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
})

local now = 1000
PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}
getWorld = function()
    return { getGameMode = function() return "Sandbox" end }
end
ZombieIdleState = { instance = function() return "idle_state" end }

local finishBumpCalls = {}
local cancelledNPCs = {}
local requeuedTasks = {}

local records = {}
local bodies = {}

PNC = {
    Core = {
        Now = function() return now end,
        IsAuthority = function() return true end,
        IsManagedNPCBody = function() return true end,
        LogWarn = function() end,
        DeepCopy = function(v) return v end,
    },
    Const = {
        BANDAGE_RANGE = 3,
        TACTICAL_CLASS_COLONIST = "colonist",
        TACTICAL_CLASS_HOSTILE = "hostile",
        PRESENCE_LIVE = "LIVE",
    },
    Types = {
        IsColonist = function() return true end,
    },
    WorkPolicy = {
        IsEnabled = function() return true end,
        GetPriority = function() return 5 end,
    },
    Registry = {
        Get = function(id) return records[tostring(id)] end,
        GetLiveZombie = function(id) return bodies[tostring(id)] end,
        FindRecordByZombie = function(z) return z and z._record or nil end,
    },
    BehaviorCommon = {
        HaltMovement = function() end,
        MoveRecord = function() return true, "moving" end,
        ClearCombatTarget = function() end,
    },
    NPCWounds = {
        GetTreatableWounds = function(rec)
            return rec and rec._wounds or {}
        end,
        FindTreatableWound = function(rec)
            local w = rec and rec._wounds and rec._wounds[1]
            return w and w.partId or nil
        end,
    },
    Treatment = {
        GetNPCBandagePlan = function()
            return { fullType = "Base.Bandage", displayName = "Bandage", requiresItem = true }
        end,
        GetNPCBandageDuration = function() return 3000 end,
        HasNPCBandage = function() return true end,
        RequiresNPCMedicalItem = function() return true end,
        TryNPCMedicalTreatment = function() return true, "bandaged" end,
    },
    MedicalCareRepository = {
        STATUS = {
            QUEUED = "QUEUED",
            CLAIMED = "CLAIMED",
            TRAVELING = "TRAVELING",
            AT_PATIENT = "AT_PATIENT",
            TREATING = "TREATING",
            WAITING_FOR_SUPPLY = "WAITING_FOR_SUPPLY",
            COMPLETED = "COMPLETED",
            CANCELLED = "CANCELLED",
        },
        TERMINAL = { COMPLETED = true, CANCELLED = true },
    },
    MedicalCareService = {
        STATUS = {
            QUEUED = "QUEUED",
            CLAIMED = "CLAIMED",
            TRAVELING = "TRAVELING",
            AT_PATIENT = "AT_PATIENT",
            TREATING = "TREATING",
            WAITING_FOR_SUPPLY = "WAITING_FOR_SUPPLY",
            COMPLETED = "COMPLETED",
            CANCELLED = "CANCELLED",
        },
        TERMINAL = { COMPLETED = true, CANCELLED = true },
        Get = function(id) return PNC._tasks and PNC._tasks[id] or nil end,
        SetPhase = function() return true end,
        MarkProgress = function() return true end,
        Complete = function() return true end,
        Cancel = function() return true end,
        Requeue = function(id, reason)
            requeuedTasks[#requeuedTasks + 1] = { id = id, reason = reason }
            return true
        end,
    },
    Tasking = {
        Commands = {
            CancelForNPC = function(npcId, reason)
                cancelledNPCs[#cancelledNPCs + 1] = { npcId = npcId, reason = reason }
                return true
            end,
        },
    },
    MedicalCareExecutor = { Internal = {} },
}

T.load("ProjectHoomans", "shared", "PNC/Core/Pathing/PNC_LiveBodyControl.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Visuals/PNC_Animation.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Behaviors/PNC_Behavior_Treatment.lua")
T.load("ProjectHoomans", "server", "PNC/Medical/MedicalCareExecutor/PNC_MedicalCareExecutor_Core.lua")
T.load("ProjectHoomans", "server", "PNC/Medical/MedicalCareExecutor/PNC_MedicalCareExecutor_Actions.lua")

local origFinishBump = PNC.Animation.FinishBump
PNC.Animation.FinishBump = function(z, force, owner)
    finishBumpCalls[#finishBumpCalls + 1] = z
    return origFinishBump(z, force, owner)
end

local function makeBody(rec)
    local s = {
        modData = { PNC_UUID = rec.id },
        vars = {},
        bumpType = "",
        bumpDone = false,
        useless = true,
        actionState = "idle",
        legacyState = "idle_state",
        x = 10,
        y = 10,
        z = 0,
    }
    local b = {
        _s = s,
        _record = rec,
        getX = function() return s.x end,
        getY = function() return s.y end,
        getZ = function() return s.z end,
        getModData = function() return s.modData end,
        getActionStateName = function() return s.actionState end,
        getBumpType = function() return s.bumpType end,
        setBumpType = function(_, v) s.bumpType = tostring(v or "") end,
        setBumpDone = function(_, v) s.bumpDone = v == true end,
        setBumpFall = function() end,
        setVariable = function(_, k, v) s.vars[k] = v end,
        getVariableString = function(_, k) return tostring(s.vars[k] or "") end,
        clearVariable = function(_, k) s.vars[k] = nil end,
        reportEvent = function() end,
        changeState = function(_, st) s.legacyState = st end,
        setRunning = function() end,
        setMoving = function() end,
        setSneaking = function() end,
        setWalkType = function() end,
        setSpeedMod = function() end,
        setAnimatingBackwards = function() end,
        setUseless = function(_, v) s.useless = v == true end,
        isUseless = function() return s.useless end,
        setTarget = function() end,
        setTargetSeenTime = function() end,
        setEatBodyTarget = function() end,
        setThumpTarget = function() end,
        clearAggroList = function() end,
        setAttackedBy = function() end,
        setNoTeeth = function() end,
        setZombiesDontAttack = function() end,
        setReanimatedForGrappleOnly = function() end,
        faceThisObject = function() end,
    }
    function b:stepActionContext()
        if s.actionState == "bumped"
            and s.useless == false
            and s.vars.BumpAnimFinished == true
        then
            s.actionState = "idle"
            s.vars.BumpAnimFinished = nil
        end
        if s.actionState == "idle" and s.bumpType ~= "" then
            s.actionState = "bumped"
        end
    end
    return b
end

local rory = {
    id = "npcRory",
    alive = true,
    presenceState = "LIVE",
    x = 10, y = 10, z = 0,
    _wounds = { { partId = "ForeArm_L" } },
    runtime = {
        selfTreatment = { phase = "bandaging", partId = "ForeArm_L", startedAt = 1000, finishAt = 4000 },
    },
}
local jarrod = {
    id = "npcJarrod",
    alive = true,
    presenceState = "LIVE",
    x = 10, y = 10, z = 0,
    runtime = {},
}
local meghan = {
    id = "npcMeghan",
    alive = true,
    presenceState = "LIVE",
    x = 10, y = 10, z = 0,
    runtime = {},
}
records.npcRory = rory
records.npcJarrod = jarrod
records.npcMeghan = meghan
bodies.npcRory = makeBody(rory)
bodies.npcJarrod = makeBody(jarrod)
bodies.npcMeghan = makeBody(meghan)

local task = {
    id = "med-1",
    patientKind = "npc",
    patientId = "npcRory",
    status = "TRAVELING",
    policy = { requireItem = true },
}
PNC._tasks = { ["med-1"] = task }

-- 1. CanTreat rejects when patient is already self-bandaging.
local ok, reason = PNC.MedicalCareExecutor.Internal.CanTreat(jarrod, task)
T.equal(ok, false, "doctor must not treat an NPC already self-bandaging")
T.equal(reason, "patient_self_bandaging", "rejection reason identifies self-bandaging")

-- 2. In-flight doctor arriving while patient is self-bandaging yields & cancels cleanly.
local ticked, tickReason = PNC.MedicalCareExecutor.Tick({
    leaseId = "lease-1",
    npcId = "npcJarrod",
    sourceRef = "med-1",
})
T.equal(ticked, false, "arriving medic yields when patient is already self-bandaging")
T.equal(tickReason, "patient_self_bandaging", "tick cancellation reason")
T.equal(cancelledNPCs[#cancelledNPCs].reason, "PATIENT_ALREADY_TREATING",
    "tasking lease cancelled cleanly")

-- 3. Multi-medic conflict: if Jarrod is actively treating Rory, Meghan is rejected.
rory.runtime.selfTreatment.phase = "idle"
jarrod.runtime.medicalCare = { phase = "treating", patientId = "npcRory", finishAt = 5000 }
rory.runtime.receivingMedicalCareBy = "npcJarrod"
rory.runtime.receivingMedicalCareUntil = 5000
local ok2, reason2 = PNC.MedicalCareExecutor.Internal.CanTreat(meghan, task)
T.equal(ok2, false, "second medic cannot treat a patient already being treated")
T.equal(reason2, "patient_treated_by_other_medic", "multi-medic rejection reason")

-- 4. Self-treatment yields and finishes bump if a doctor is already actively treating the NPC.
rory.runtime.selfTreatment = { phase = "bandaging", partId = "ForeArm_L", startedAt = 1000, finishAt = 4000 }
local beforeFinish = #finishBumpCalls
local selfTicked = PNC.BehaviorTreatment.Tick(rory, bodies.npcRory, 2000)
T.equal(selfTicked, false, "self-treatment yields while receiving medical care")
T.equal(rory.runtime.selfTreatment.phase, "idle", "self-treatment phase cleared on yield")
T.equal(#finishBumpCalls, beforeFinish + 1, "self-treatment FinishBump called on yield")

-- 5. Pending bump release keeps ActionContext useful even under stationary presentation (LivingRoom)
--    and EnforceManagedSafety pumps the release to completion.
local origStationary = PNC.LiveBodyControl.ResolveStationaryPresentation
PNC.LiveBodyControl.ResolveStationaryPresentation = function()
    return "seat", "living_room"
end
local jBody = makeBody(jarrod)
bodies.npcJarrod = jBody
jBody._s.actionState = "bumped"
jBody._s.bumpType = "PNC_Loot"
jBody._s.modData.PNC_BumpActionLease = true
jBody._s.modData.PNC_BumpActionLeaseUntil = 1500
jBody._s.modData.PNC_BumpKeepUseless = true
now = 2000
-- Expired lease in ShouldKeepEngineMovementActive hands off to FinishBump and returns true.
T.equal(PNC.LiveBodyControl.ShouldKeepEngineMovementActive(jarrod, jBody), true,
    "expired bump lease hands off to FinishBump and keeps body useful")
T.equal(jBody._s.modData.PNC_BumpReleasePending, true, "release armed from Maintenance")
T.equal(jBody._s.bumpType, "", "FinishBump immediately clears BumpType to prevent re-entry")
T.equal(jBody._s.modData.PNC_BumpKeepUseless, false, "FinishBump clears KeepUseless")

-- EnforceManagedSafety keeps body useful and pumps release while stationary presentation is active.
PNC.LiveBodyControl.EnforceManagedSafety(jBody, "zombie_update", true)
T.equal(jBody._s.useless, false, "body stays useful during bump release despite LivingRoom lock")
jBody:stepActionContext()
T.equal(jBody._s.actionState, "idle", "ActionContext transitions from bumped to idle")
now = 2100
PNC.LiveBodyControl.EnforceManagedSafety(jBody, "zombie_update", true)
T.equal(jBody._s.modData.PNC_BumpReleasePending, nil, "EnforceManagedSafety completes bump release")
PNC.LiveBodyControl.ResolveStationaryPresentation = origStationary
