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
        Requeue = function(_, reason) cancelledTasks[#cancelledTasks + 1] = reason return true end,
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

require "PNC/Medical/MedicalCareExecutor/PNC_MedicalCareExecutor_Actions"
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
T.truthy(#spoken >= 1 and string.find(spoken[1], "hostile_interrupted", 1, true) ~= nil, "medic calls out hostile_interrupted")
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
T.truthy(#spoken >= 1 and string.find(spoken[1], "patient_moved_away|Rick", 1, true) ~= nil,
    "medic tells player to stop moving via ConvoDSL")

print("pnc_medical_care_interrupt_and_cleanup_smoke: OK")
