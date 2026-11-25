-- MedicalCareExecutor stuck-pose cleanup, hostile interruption, patient hold,
-- player action stop, and patient-moved-away cancellation + dialogue smoke test.
package.path = "./tests/?.lua;./tests/?/init.lua;./Contents/mods/ProjectHoomans/42.20/media/lua/shared/?.lua;./Contents/mods/ProjectHoomans/42.20/media/lua/server/?.lua;" .. package.path

local T = require "support.test"

local simNow = 100000
local finishedBumps = 0
local clearedPlayerActions = 0
local haltedActors = {}
local spoken = {}
local cancelledTasks = {}
local completedLeases = {}

_G.ISTimedActionQueue = {
    clear = function() clearedPlayerActions = clearedPlayerActions + 1 end,
}

local function makeBody(x, y, z)
    local vars = {}
    local md = {}
    return {
        x = x, y = y, z = z or 0,
        vars = vars, modData = md,
        getX = function(self) return self.x end,
        getY = function(self) return self.y end,
        getZ = function(self) return self.z end,
        setVariable = function(self, k, v) vars[k] = v end,
        getModData = function(self) return md end,
        faceThisObject = function() end,
    }
end

local medic = { id = "medic_1", name = "Mitzi", alive = true, x = 10, y = 10, z = 0, runtime = {} }
local medicBody = makeBody(10, 10, 0)
local npcPatient = { id = "pat_1", name = "Wilfredo", alive = true, x = 10.5, y = 10, z = 0, runtime = {} }
local npcPatientBody = makeBody(10.5, 10, 0)
local playerPatient = makeBody(10.5, 10, 0)
playerPatient.getUsername = function() return "Rick" end
playerPatient.getDisplayName = function() return "Rick" end
playerPatient.isDead = function() return false end

local activeTask = nil
local treatablePart = "ForeArm_L"
local combatFlags = {}

_G.PNC = {
    Core = { Now = function() return simNow end },
    MedicalCareRepository = {
        STATUS = { CLAIMED = "CLAIMED", TRAVELING = "TRAVELING", AT_PATIENT = "AT_PATIENT", TREATING = "TREATING", WAITING_FOR_SUPPLY = "WAITING_FOR_SUPPLY" },
    },
    MedicalCareService = {
        TERMINAL = { COMPLETED = true, CANCELLED = true },
        Get = function(id) return (activeTask and activeTask.id == id) and activeTask or nil end,
        SetPhase = function() return true end,
        Complete = function() if activeTask then activeTask.status = "COMPLETED" end return true end,
        Cancel = function() if activeTask then activeTask.status = "CANCELLED" end return true end,
        Requeue = function(_, reason, delayMs) cancelledTasks[#cancelledTasks + 1] = { reason = reason, delayMs = delayMs } return true end,
        MarkProgress = function() end,
    },
    Registry = {
        Get = function(id)
            if id == medic.id then return medic end
            if id == npcPatient.id then return npcPatient end
            return nil
        end,
        GetLiveZombie = function(id)
            if id == medic.id then return medicBody end
            if id == npcPatient.id then return npcPatientBody end
            return nil
        end,
    },
    BehaviorCommon = {
        HaltMovement = function(rec, _, reason)
            haltedActors[#haltedActors + 1] = { id = rec and rec.id, reason = reason }
        end,
    },
    Animation = {
        PlayBump = function() end,
        MaintainBump = function() end,
        FinishBump = function() finishedBumps = finishedBumps + 1 end,
    },
    Treatment = {
        GetNPCBandagePlan = function() return { requiresItem = false } end,
        GetNPCBandageDuration = function() return 4000 end,
        TryNPCMedicalTreatment = function() return true end,
    },
    Tasking = {
        Commands = {
            Complete = function(lid, reason) completedLeases[#completedLeases + 1] = { lid = lid, reason = reason } return true end,
            CancelForNPC = function(_, reason) cancelledTasks[#cancelledTasks + 1] = reason return true end,
        },
    },
    Semantics = {
        SpeechTransport = {
            ResolveLine = function(_, spec) return tostring(spec.role) .. "|" .. tostring(spec.tokens["addressee.name"]), { poolID = spec.poolID } end,
            Deliver = function(_, _, opts) spoken[#spoken + 1] = opts.text return true end,
        },
    },
}

PNC.MedicalCareExecutor = {
    Internal = {
        Patient = function(task) return task.patientKind == "player" and playerPatient or npcPatient end,
        CurrentPart = function() return treatablePart, treatablePart and { partId = treatablePart } or nil end,
        Treatable = function() return treatablePart and { { partId = treatablePart } } or {} end,
        ResolveLootPosition = function() return "High" end,
        ResolveLootBump = function() return "LootHigh" end,
        Position = function(_, body) return body:getX(), body:getY(), body:getZ() end,
        InTreatmentRange = function(_, aBody, _, pBody)
            local dx, dy = aBody:getX() - pBody:getX(), aBody:getY() - pBody:getY()
            return (dx * dx + dy * dy) <= 9
        end,
        Face = function() end,
        combatActive = function(rec) return combatFlags[rec and rec.id] == true end,
    },
}

require "PNC/Medical/MedicalCareExecutor/PNC_MedicalCareExecutor_Speech"
require "PNC/Medical/MedicalCareExecutor/PNC_MedicalCareExecutor_Actions"
require "PNC/Core/Health/PNC_Treatment/PNC_Treatment_Snapshot"
local Exec = PNC.MedicalCareExecutor
local lease = { leaseId = "lease_1", npcId = medic.id, sourceRef = "task_1" }

-- 1) NPC-to-NPC treatment holds patient still, and wound resolving mid-treatment cleans up medic pose!
activeTask = { id = "task_1", patientId = npcPatient.id, patientKind = "npc", status = "CLAIMED" }
treatablePart = "ForeArm_L"
local ok1 = Exec.Tick(lease)
T.equal(ok1, true, "medic starts treating NPC patient")
T.equal(medicBody.vars.LootPosition, "High", "medic sets LootPosition while treating")
T.equal(npcPatient.runtime.receivingMedicalCareBy, medic.id, "NPC patient is held still during treatment")

-- Wound resolves externally while medic is mid-treatment -> must NOT leave medic stuck!
treatablePart = nil
finishedBumps = 0
local ok2 = Exec.Tick(lease)
T.equal(ok2, true, "wound resolved mid-treatment completes cleanly")
T.truthy(finishedBumps >= 1, "Animation.FinishBump called on wound resolved mid-treatment")
T.equal(medicBody.vars.LootPosition, "", "LootPosition cleared so medic is not stuck in raised-arms pose")
T.equal(medic.runtime.medicalCare, nil, "medic medicalCare runtime cleared")
T.equal(npcPatient.runtime.receivingMedicalCareBy, nil, "patient hold released")

-- 2) Hostile interruption on patient aborts treatment, clears pose, and speaks hostile_interrupted
activeTask = { id = "task_1", patientId = npcPatient.id, patientKind = "npc", status = "CLAIMED" }
treatablePart = "ForeArm_L"
spoken = {}
finishedBumps = 0
Exec.Tick(lease) -- starts treating
combatFlags[npcPatient.id] = true
local okHostile, reasonHostile = Exec.Tick(lease)
T.equal(okHostile, false, "hostile threat on patient interrupts treatment")
T.equal(reasonHostile, "combat_active", "interrupt reason is combat_active")
T.truthy(finishedBumps >= 1, "Animation.FinishBump called on hostile interruption")
T.equal(medicBody.vars.LootPosition, "", "LootPosition cleared on hostile interruption")
T.truthy(#spoken >= 1 and string.find(spoken[#spoken], "hostile_interrupted", 1, true) ~= nil, "medic calls out hostile_interrupted")
combatFlags[npcPatient.id] = false

-- 3) Player target: stops player's timed action on start, and if player moves away -> cancels + says stop moving!
activeTask = { id = "task_1", patientId = "player:Rick", patientKind = "player", status = "CLAIMED" }
playerPatient.x, playerPatient.y = 10.5, 10
clearedPlayerActions = 0
spoken = {}
finishedBumps = 0
Exec.Tick(lease) -- starts treating player
T.equal(clearedPlayerActions, 1, "player's current timed action is stopped when medic begins bandaging")

-- Player walks 3 tiles away mid-bandage
playerPatient.x = 13.5
local okMoved, reasonMoved = Exec.Tick(lease)
T.equal(okMoved, false, "treatment cancels when player moves away")
T.equal(reasonMoved, "patient_moved_away", "cancel reason is patient_moved_away")
T.truthy(finishedBumps >= 1, "Animation.FinishBump called when patient moves away")
T.equal(medicBody.vars.LootPosition, "", "LootPosition cleared when patient moves away")
T.truthy(#spoken >= 1 and string.find(spoken[#spoken], "patient_moved_away|Rick", 1, true) ~= nil,
    "medic tells player to stop moving via ConvoDSL")

-- Verify requeue retry backoff on combat_active and patient_moved_away
local sawCombatBackoff, sawMoveBackoff = false, false
for _, entry in ipairs(cancelledTasks) do
    if type(entry) == "table" then
        if entry.reason == "combat_active" and (tonumber(entry.delayMs) or 0) >= 3000 then sawCombatBackoff = true end
        if entry.reason == "patient_moved_away" and (tonumber(entry.delayMs) or 0) >= 4000 then sawMoveBackoff = true end
    end
end
T.equal(sawCombatBackoff, true, "combat_active requeue applies retry backoff")
T.equal(sawMoveBackoff, true, "patient_moved_away requeue applies retry backoff")

-- 4) Snapshot preserves patientKind and TickOwnership holds patient still (while still yielding to ThreatGuard)
activeTask = { id = "task_1", patientId = "player:Rick", patientKind = "player", status = "CLAIMED" }
playerPatient.x, playerPatient.y = 10.5, 10
Exec.Tick(lease)
local snap = PNC.Treatment.BuildMedicalCareSnapshot(medic)
T.truthy(snap ~= nil and snap.patientKind == "player", "BuildMedicalCareSnapshot includes patientKind")
Exec.Cancel(lease, "test_cleanup")

local selfTreatCalled = false
local threatActive = false
PNC.BehaviorSystem = {
    Internal = {
        TickOwnership = {
            ThreatGuard = { Tick = function() return threatActive end },
            Treatment = { Tick = function() selfTreatCalled = true return true end },
            puppetOperaOwnsBehavior = function() return false end,
        },
    },
}
require "PNC/Core/Behaviors/PNC_BehaviorSystem_Tick_Ownership"
local Ownership = PNC.BehaviorSystem.Internal.TickOwnership

activeTask = { id = "task_1", patientId = npcPatient.id, patientKind = "npc", status = "CLAIMED" }
treatablePart = "ForeArm_L"
Exec.Tick(lease) -- medic begins treating npcPatient

-- Patient ownership tick must hold patient still and block self-treatment
selfTreatCalled = false
threatActive = false
T.equal(Ownership.Run(npcPatient, npcPatientBody, simNow), true, "TickOwnership holds NPC patient still while receiving medical care")
T.equal(selfTreatCalled, false, "patient hold prevents concurrent self-treatment")

-- Hostile threat preempts patient hold immediately
threatActive = true
T.equal(Ownership.Run(npcPatient, npcPatientBody, simNow), true, "ThreatGuard preempts patient hold")
threatActive = false

-- Expired hold auto-clears and falls through
T.equal(Ownership.Run(npcPatient, npcPatientBody, simNow + 60000), true, "expired hold clears and allows normal Treatment.Tick")
T.equal(npcPatient.runtime.receivingMedicalCareBy, nil, "expired patient hold self-clears")
T.equal(selfTreatCalled, true, "normal behavior resumes after hold expires")

print("pnc_medical_care_interrupt_and_cleanup_smoke: OK")
