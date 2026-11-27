local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
})

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local now = 1000
local records = {}
local bodies = {}
local tasks = {}
local leases = {}
local registered
local lastTreatmentOptions
local doctorBandagesConsumed = 0
local animationStarts = 0
local animationMaintains = 0
local animationFinishes = 0
local moveRequests = 0

local function body(x, y, z)
    local value = { x = x, y = y, z = z, vars = {}, modData = {} }
    function value:getX() return self.x end
    function value:getY() return self.y end
    function value:getZ() return self.z end
    function value:setVariable(key, entry) self.vars[key] = entry end
    function value:getModData() return self.modData end
    function value:faceThisObject(target) self.facing = target end
    function value:getEmitter()
        return { playSound = function() end }
    end
    return value
end

local function statusTable()
    return {
        QUEUED = "QUEUED",
        WAITING_FOR_DOCTOR = "WAITING_FOR_DOCTOR",
        WAITING_FOR_SUPPLY = "WAITING_FOR_SUPPLY",
        CLAIMED = "CLAIMED",
        TRAVELING = "TRAVELING",
        AT_PATIENT = "AT_PATIENT",
        TREATING = "TREATING",
        COMPLETED = "COMPLETED",
        CANCELLED = "CANCELLED",
        FAILED = "FAILED",
        QUARANTINED = "QUARANTINED",
    }
end

local Status = statusTable()
local terminal = {
    COMPLETED = true, CANCELLED = true, FAILED = true, QUARANTINED = true,
}

local function copyTask(task)
    local output = {}
    for key, value in pairs(task) do output[key] = value end
    return output
end

PNC = {
    Const = { BANDAGE_RANGE = 3, PRESENCE_LIVE = "live" },
    Core = {
        Now = function() return now end,
        DeepCopy = function(value) return value end,
    },
    Types = {
        IsColonist = function(record)
            return record and record.tacticalClass == "colonist"
        end,
    },
    Registry = {
        Get = function(id) return records[tostring(id)] end,
        GetLiveZombie = function(id) return bodies[tostring(id)] end,
    },
    BehaviorCommon = {
        HaltMovement = function() end,
        MoveRecord = function()
            moveRequests = moveRequests + 1
            return true, "move_intent"
        end,
    },
    Animation = {
        PlayBump = function(_, record, bump, options)
            animationStarts = animationStarts + 1
            record.lastBump = bump
            record.lastBumpLease = options.leaseUntil
            return true
        end,
        MaintainBump = function() animationMaintains = animationMaintains + 1 end,
        FinishBump = function() animationFinishes = animationFinishes + 1 end,
    },
    TaskLeaseService = {
        SetPhase = function(id, phase)
            local lease = leases[tostring(id)]
            if lease then lease.phase = phase end
            return lease ~= nil
        end,
        Get = function(id) return leases[tostring(id)] end,
    },
    Tasking = { Commands = {}, Internal = {} },
    MedicalCareRepository = { STATUS = Status, TERMINAL = terminal },
    MedicalCareService = {},
    Treatment = {
        GetNPCBandagePlan = function(record)
            if record and record.tacticalClass == "colonist" then
                local items = record.inventory and record.inventory.items or {}
                local bandage = items.bandage
                if not bandage or (tonumber(bandage.stack) or 0) <= 0 then
                    return nil
                end
                return {
                    fullType = "Base.Bandage",
                    displayName = "Bandage",
                    requiresItem = true,
                }
            end
            return { fullType = "PNC.AbstractMedical", displayName = "abstract" }
        end,
        GetNPCBandageDuration = function() return 100 end,
        TryNPCMedicalTreatment = function(actor, patient, partId, options)
            lastTreatmentOptions = options
            T.equal(actor.alive, true, "doctor remains alive at commit")
            T.equal(patient.alive, true, "patient remains alive at commit")
            if actor.tacticalClass == "colonist" then
                actor.inventory.items.bandage.stack =
                    actor.inventory.items.bandage.stack - 1
                doctorBandagesConsumed = doctorBandagesConsumed + 1
            end
            patient.wounds = {}
            return true, "treated"
        end,
    },
    NPCWounds = {
        GetTreatableWounds = function(record)
            local output = {}
            for _, partId in ipairs(record.wounds or {}) do
                output[#output + 1] = { partId = partId, wound = {} }
            end
            return output
        end,
    },
}

PNC.MedicalCareService.TERMINAL = terminal

PNC.MedicalCareService.List = function()
    local output = {}
    for _, task in pairs(tasks) do
        if not terminal[task.status] then output[#output + 1] = copyTask(task) end
    end
    table.sort(output, function(left, right)
        return left.priority > right.priority
    end)
    return output
end
PNC.MedicalCareService.Get = function(id)
    local task = tasks[tostring(id)]
    return task and copyTask(task) or nil
end
PNC.MedicalCareService.SetPhase = function(id, phase, options)
    local task = tasks[tostring(id)]
    if not task or terminal[task.status] then return false end
    task.status = phase
    task.phase = phase
    options = options or {}
    if options.actorId ~= nil then task.actorId = tostring(options.actorId) end
    if options.clearActor then task.actorId = nil end
    if options.clearReservation then task.reservationId = nil end
    if options.supplyRequesterId ~= nil then
        task.supplyRequesterId = tostring(options.supplyRequesterId)
    end
    if options.supplyRequestId ~= nil then
        task.supplyRequestId = tostring(options.supplyRequestId)
    elseif phase == Status.WAITING_FOR_SUPPLY and not task.supplyRequestId then
        task.supplyRequestId = "medical-bandage:" .. tostring(task.id) .. ":1"
    end
    task.blockedReason = options.blockedReason or task.blockedReason
    task.lastProgressAt = now
    return true
end
PNC.MedicalCareService.MarkProgress = function(id)
    local task = tasks[tostring(id)]
    if task then task.lastProgressAt = now end
    return task ~= nil
end
PNC.MedicalCareService.Complete = function(id, reason)
    local task = tasks[tostring(id)]
    if not task or terminal[task.status] then return false end
    task.status, task.phase = Status.COMPLETED, Status.COMPLETED
    task.completionReason = reason
    task.actorId = nil
    return true
end
PNC.MedicalCareService.Cancel = function(id)
    local task = tasks[tostring(id)]
    if not task or terminal[task.status] then return false end
    task.status, task.phase = Status.CANCELLED, Status.CANCELLED
    task.actorId = nil
    return true
end
PNC.MedicalCareService.Requeue = function(id, reason)
    local task = tasks[tostring(id)]
    if not task or terminal[task.status] then return false end
    task.status, task.phase = Status.WAITING_FOR_DOCTOR, Status.WAITING_FOR_DOCTOR
    task.blockedReason = reason
    task.actorId = nil
    return true
end

function PNC.Tasking.Commands.RegisterProvider(_, provider)
    registered = provider
    return true
end
function PNC.Tasking.Commands.Complete(id)
    local lease = leases[tostring(id)]
    if not lease then return false end
    registered.Complete(lease, "test_complete")
    leases[tostring(id)] = nil
    return true
end
function PNC.Tasking.Commands.CancelForNPC(npcId, reason)
    local lease
    for _, entry in pairs(leases) do
        if tostring(entry.npcId) == tostring(npcId) then lease = entry end
    end
    if not lease then return false end
    registered.Cancel(lease, reason)
    leases[lease.leaseId] = nil
    return true
end

local Executor = T.load("ProjectHoomans", "server",
    "PNC/Medical/PNC_MedicalCareExecutor.lua")
T.equal(registered, Executor, "medical provider registered with tasking")
T.equal(Executor.Internal.ResolveLootBump("Low"), "LootLow",
    "downed/low patient uses player bedside low loot animation")
T.equal(Executor.Internal.ResolveLootBump("High"), "LootHigh",
    "head patient uses player bedside high loot animation")
T.equal(Executor.Internal.ResolveLootBump("Mid"), "Loot",
    "normal patient uses player bedside loot animation")

local doctor = {
    id = "doctor", alive = true, tacticalClass = "colonist",
    archetypeID = "Doctor", affiliation = { factionID = "colony" },
    inventory = { items = {
        bandage = { stack = 1 },
    } },
    runtime = {},
}
local patient = {
    id = "patient", alive = true, tacticalClass = "colonist",
    affiliation = { factionID = "colony" },
    runtime = {}, wounds = { "UpperArm_L" },
}
records.doctor, records.patient = doctor, patient
bodies.doctor, bodies.patient = body(0, 0, 0), body(5, 0, 0)

local task = {
    id = "medical:live", patientKind = "npc", patientId = "patient",
    status = Status.WAITING_FOR_DOCTOR, phase = Status.WAITING_FOR_DOCTOR,
    priority = 100, retryAt = 0, revision = 1, createdAt = 1,
    lastProgressAt = now, actorId = nil,
}
tasks[task.id] = task
T.truthy(Executor.GetCandidates("doctor")[1],
    "doctor discovers a same-faction patient request")
local assignment = Executor.Assign(Executor.GetCandidates("doctor")[1])
T.truthy(assignment, "doctor claims the durable medical request")
local lease = {
    leaseId = "lease:live", npcId = "doctor", sourceRef = task.id,
    sourceDomain = "medical", phase = "ASSIGNED", lastProgressAt = now,
}
leases[lease.leaseId] = lease
T.truthy(Executor.Start(lease), "live doctor enters medical travel")
T.truthy(Executor.Tick(lease), "live doctor requests movement to patient")
T.equal(moveRequests, 1, "movement is routed through the common movement intent")
bodies.doctor.x = 4.5
T.truthy(Executor.Tick(lease), "doctor starts bedside treatment in range")
T.equal(doctor.lastBump, "Loot", "doctor uses player-to-NPC Loot animation")
T.equal(bodies.doctor.vars.LootPosition, "Mid",
    "doctor sets the player bedside LootPosition")
now = 1200
T.truthy(Executor.Tick(lease), "doctor commits treatment after animation")
T.equal(lastTreatmentOptions.consumeItem, false,
    "non-item policy is passed explicitly to the treatment commit")
T.equal(doctorBandagesConsumed, 1,
    "colonist doctor consumed its own bandage at the treatment commit")
T.equal(doctor.inventory.items.bandage.stack, 0,
    "colonist doctor bandage stack was decremented")
T.equal(task.status, Status.COMPLETED,
    "completed patient request is closed durably")
T.equal(animationStarts, 1, "bedside animation starts once")
T.truthy(animationFinishes > 0, "bedside animation is released")

local aiDoctor = {
    id = "ai-doctor", alive = true, tacticalClass = "neutral",
    affiliation = { factionID = "raiders", role = "medic" },
    runtime = {},
}
local aiPatient = {
    id = "ai-patient", alive = true, tacticalClass = "neutral",
    affiliation = { factionID = "raiders" },
    runtime = {}, wounds = { "Head" },
}
records[aiDoctor.id], records[aiPatient.id] = aiDoctor, aiPatient
local aiTask = {
    id = "medical:abstract", patientKind = "npc", patientId = aiPatient.id,
    status = Status.WAITING_FOR_DOCTOR, phase = Status.WAITING_FOR_DOCTOR,
    priority = 40, retryAt = 0, revision = 1, createdAt = 1,
    lastProgressAt = now, actorId = nil,
}
tasks[aiTask.id] = aiTask
local aiIntent = Executor.GetCandidates(aiDoctor.id)[1]
T.truthy(aiIntent, "AI medic discovers same-faction abstract patient")
T.truthy(Executor.Assign(aiIntent), "AI medic claims abstract patient")
local aiLease = {
    leaseId = "lease:abstract", npcId = aiDoctor.id,
    sourceRef = aiTask.id, sourceDomain = "medical", phase = "ASSIGNED",
    lastProgressAt = now,
}
leases[aiLease.leaseId] = aiLease
T.truthy(Executor.Start(aiLease), "AI medic starts abstract care")
T.truthy(Executor.Tick(aiLease), "AI medic treats without a live body")
T.equal(lastTreatmentOptions.consumeItem, false,
    "AI faction treatment remains item-free")
T.equal(aiTask.status, Status.COMPLETED,
    "abstract patient request also closes durably")

local donorSearches = 0
PNC.Registry.ForEach = function(callback)
    donorSearches = donorSearches + 1
    callback(doctor)
    callback(patient)
end
patient.wounds = { "UpperArm_L" }
local supplyTask = {
    id = "medical:supply", patientKind = "npc", patientId = patient.id,
    status = Status.WAITING_FOR_SUPPLY, supplyRequesterId = doctor.id,
    supplyRequestId = "medical-bandage:medical:supply:1",
    policy = { requireItem = true },
}
tasks[supplyTask.id] = supplyTask
local waiting, supplyReason = Executor.RequestBandageSupport(supplyTask.id)
T.truthy(waiting, "missing bandage starts support without an exception")
T.equal(supplyReason, "waiting_for_supply")
local firstSearches = donorSearches
T.truthy(Executor.RequestBandageSupport(supplyTask.id))
T.equal(donorSearches - firstSearches, 2, "repeat checks skip the donor scan")
now = now + Executor.Internal.SUPPLY_RETRY_MS
local searchesBeforeRetry = donorSearches
T.truthy(Executor.RequestBandageSupport(supplyTask.id))
T.equal(donorSearches - searchesBeforeRetry, 3,
    "expired throttle allows another donor scan")

-- Regression: player-patient supply preflight and RequestBandageSupport must
-- route through player wound inspection rather than NPCWounds.GetTreatableWounds.
local playerPart = T.javaObject({
    getIndex = function() return 0 end,
    getType = function() return "ForeArm_L" end,
    bandaged = function() return false end,
    isBandageDirty = function() return false end,
    bleeding = function() return true end,
    getBleedingTime = function() return 5 end,
    bitten = function() return false end,
    isCut = function() return true end,
    scratched = function() return false end,
    isDeepWounded = function() return false end,
    getBurnTime = function() return 0 end,
}, "BodyPart")
local mockPlayer = T.javaObject({
    isDead = function() return false end,
    getOnlineID = function() return 7 end,
    getUsername = function() return "tester" end,
    getBodyDamage = function()
        return T.javaObject({
            getBodyParts = function()
                return T.javaObject({
                    size = function() return 1 end,
                    get = function(_, idx) return idx == 0 and playerPart or nil end,
                }, "ArrayList")
            end,
        }, "BodyDamage")
    end,
}, "IsoPlayer")
T.equal(type(mockPlayer), "userdata", "Kahlua Java mock reports userdata type")
local writeOk = pcall(function() mockPlayer.health = {} end)
T.falsy(writeOk, "Kahlua Java mock rejects field writes like IsoPlayer")
PNC.Core.ForEachPlayer = function(fn) fn(mockPlayer) end
local origGetTreatableWounds = PNC.NPCWounds.GetTreatableWounds
PNC.NPCWounds.GetTreatableWounds = function(target)
    T.truthy(target ~= mockPlayer,
        "player patient must never be passed to NPCWounds.GetTreatableWounds")
    return origGetTreatableWounds(target)
end
doctor.inventory.items.bandage.stack = 0
local playerTask = {
    id = "medical:player_supply", patientKind = "player", patientId = "player:7",
    status = Status.QUEUED, phase = Status.QUEUED,
    priority = 60, retryAt = 0, revision = 1, createdAt = now,
    lastProgressAt = now, policy = { requireItem = true },
}
tasks = { [playerTask.id] = playerTask }
now = now + 5000
local playerCandidates = Executor.GetCandidates(doctor.id)
T.equal(#playerCandidates, 0, "doctor without bandages does not claim player task")
T.equal(playerTask.status, Status.WAITING_FOR_SUPPLY,
    "player task transitions to WAITING_FOR_SUPPLY via preflight")
local playerWaiting, playerSupplyReason = Executor.RequestBandageSupport(playerTask.id)
T.truthy(playerWaiting, "player supply support succeeds without NPC wound lookup")
T.equal(playerSupplyReason, "waiting_for_supply")
PNC.NPCWounds.GetTreatableWounds = origGetTreatableWounds

T.finish("pnc_medical_care_executor_smoke")
