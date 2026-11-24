if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Executor = PNC.MedicalCareExecutor
local Internal = Executor.Internal
local Service = PNC.MedicalCareService
local Repository = PNC.MedicalCareRepository
local Status = Repository.STATUS
local Const = PNC.Const
local Types = PNC.Types
local Treatment = PNC.Treatment
local Wounds = PNC.NPCWounds
local Registry = PNC.Registry
local Common = PNC.BehaviorCommon
local Recovery = PNC.Tasking and PNC.Tasking.Commands
local WorkPolicy = PNC.WorkPolicy
    or require "PNC/Core/Production/WorkDefinition/PNC_WorkPolicy"

local LOW_PARTS = {
    Groin = true,
    UpperLeg_L = true, UpperLeg_R = true,
    LowerLeg_L = true, LowerLeg_R = true,
    Foot_L = true, Foot_R = true,
}

local HIGH_PARTS = { Head = true, Neck = true }
local SUPPLY_RETRY_MS = 1500
local SUPPLY_PREFLIGHT_MS = 2000
local SUPPLY_NOTICE_RADIUS = 24
local SUPPLY_NOTICE_REPEAT_MS = 30 * 60 * 1000
local lastSupplyAttemptAt = {}
local lastSupplyPreflightAt = {}
local supplyNoticeRecipients = {}

local function id(value)
    if value == nil then return nil end
    return tostring(value)
end

local function nonempty(value)
    value = id(value)
    return value and value ~= "" and value or nil
end

local function affiliation(record)
    return record and record.affiliation or {}
end

local function factionId(record)
    local source = affiliation(record)
    return nonempty(source.factionID or source.factionId
        or record and (record.factionID or record.factionId))
end

local function communityId(record)
    local source = affiliation(record)
    return nonempty(source.communityID or source.communityId
        or record and (record.communityID or record.communityId))
end

local function ownerKey(record)
    return nonempty(record and record.ownerOnlineID)
        or nonempty(record and record.ownerUsername)
end

local function groupKey(record)
    if type(record) ~= "table" then return nil end
    local source = affiliation(record)
    return nonempty(
        record.groupId or record.groupID
            or record.mobileGroupId or record.mobileGroupID
            or record.abstractGroupId or record.abstractGroupID
            or record.squadId or record.squadID
            or record.caravanId or record.caravanID
            or source.groupId or source.groupID
            or source.mobileGroupId or source.mobileGroupID
            or (record.orderSpec and (record.orderSpec.groupId or record.orderSpec.mobileGroupId))
    )
end

local function isPatientIncapacitated(patient)
    return type(patient) == "table"
        and type(patient.health) == "table"
        and tostring(patient.health.state or "") == "incapacitated"
end

local function isCompanionOrColonist(record)
    return (Treatment and Treatment.IsPlayerOwnedNPC and Treatment.IsPlayerOwnedNPC(record) == true)
        or (Types and Types.IsColonist and Types.IsColonist(record) == true)
        or tostring(record and record.tacticalClass or "") == tostring(Const and Const.TACTICAL_CLASS_COLONIST or "colonist")
end

local function playerFriendly(actor, player)
    local oKey = ownerKey(actor)
    local oid = player and player.getOnlineID and nonempty(player:getOnlineID()) or nil
    local uname = player and player.getUsername and nonempty(player:getUsername()) or nil
    if (oKey and (oKey == oid or oKey == uname)) or actor.recruited == true then return true end
    local pKey = PNC.PlayerCharacters and PNC.PlayerCharacters.GetEntityKey and PNC.PlayerCharacters.GetEntityKey(player) or nil
    local rel = pKey and ((PNC.Relationships and PNC.Relationships.Get and PNC.Relationships.Get(actor.id, pKey))
        or (actor.social and actor.social.relationships and actor.social.relationships[pKey])) or nil
    local st = string.lower(tostring(rel and (rel.state or rel.category) or ""))
    local app = tonumber(rel and rel.approval) or 0
    if st == "enemy" or st == "hostile" or app <= -20 then return false end
    if st == "friend" or st == "family" or st == "lover" or app >= 10 then return true end
    return Types and Types.IsColonist and Types.IsColonist(actor) == true
end

function Executor.IsDoctor(record)
    local source = affiliation(record)
    local role = string.lower(tostring(
        source.role or source.communityRole or record and record.communityRole
            or ""))
    local archetype = string.lower(tostring(record and record.archetypeID or ""))
    if not WorkPolicy.IsEnabled(record, "MedicalCare") then return false end
    local jobs = record and record.allowedJobs or nil
    if role == "medic" or role == "caregiver" or archetype == "doctor" or (jobs and jobs.MedicalCare == true) then
        return true
    end
    local fa = Treatment and Treatment.GetNPCFirstAidLevel and tonumber(Treatment.GetNPCFirstAidLevel(record)) or 0
    return fa >= (tonumber(Const and Const.MEDICAL_CARE_COMPANION_MIN_FIRST_AID) or 3)
end
Internal.IsDoctor = Executor.IsDoctor

function Executor.CanAssistPatient(actor, patient, patientKind)
    if not actor or actor.alive == false then return false, "doctor_unavailable" end
    if actor.health and actor.health.state == "incapacitated" then return false, "doctor_incapacitated" end
    if not WorkPolicy.IsEnabled(actor, "MedicalCare") then return false, "medical_care_disabled" end
    if patientKind == "player" then
        if tostring(actor.tacticalClass or "") == tostring(Const and Const.TACTICAL_CLASS_HOSTILE or "hostile") then
            return false, "hostile_actor"
        end
        if not playerFriendly(actor, patient) then return false, "player_not_friendly" end
        -- Any friendly NPC can bandage the player; First Aid skill scales
        -- bandage duration and vanilla Dressing.Life efficiency instead of gating.
        return true
    end
    if not patient or patient.alive == false then return false, "patient_unavailable" end
    if tostring(patient.id) == tostring(actor.id) then return false, "self_treatment_is_not_doctor_care" end
    if not Internal.SameCareGroup(actor, patient) then return false, "care_group_mismatch" end
    -- Any healthy teammate in the same care group can assist; First Aid skill
    -- governs speed, bandage life, and healing efficiency like vanilla PZ.
    return true
end
Internal.CanAssistPatient = Executor.CanAssistPatient

function Executor.SameCareGroup(actor, patient)
    if not actor or not patient then return false end
    local rels = PNC.Relationships
    if rels and type(rels.AreNPCsEnemies) == "function" then
        if rels.AreNPCsEnemies(actor, patient, { ignoreAttackNPCPolicy = true })
            or rels.AreNPCsEnemies(patient, actor, { ignoreAttackNPCPolicy = true })
        then
            return false
        end
    end
    local actorGroup = groupKey(actor)
    local patientGroup = groupKey(patient)
    if actorGroup and patientGroup and actorGroup == patientGroup then
        return true
    end
    local actorFaction = factionId(actor)
    local patientFaction = factionId(patient)
    if actorFaction and patientFaction then
        if actorFaction == patientFaction then return true end
        if PNC.Factions and type(PNC.Factions.AreAllied) == "function"
            and PNC.Factions.AreAllied(actorFaction, patientFaction) == true
        then
            return true
        end
    end
    local actorCommunity = communityId(actor)
    local patientCommunity = communityId(patient)
    if actorCommunity and patientCommunity then
        return actorCommunity == patientCommunity
    end
    local actorOwner = ownerKey(actor)
    local patientOwner = ownerKey(patient)
    if actorOwner and patientOwner then
        return actorOwner == patientOwner
    end
    if PNC.Perception and type(PNC.Perception.AreWarningAllies) == "function" then
        local allied = PNC.Perception.AreWarningAllies(actor, patient)
        if allied == true then return true end
    end
    return Types and Types.IsColonist
        and Types.IsColonist(actor) and Types.IsColonist(patient) or false
end
Internal.SameCareGroup = Executor.SameCareGroup

function Internal.Patient(task)
    if not task then return nil end
    if task.patientKind == "player" then
        return Internal.ResolvePlayer and Internal.ResolvePlayer(task) or nil
    end
    if task.patientKind ~= "npc" then return nil end
    return Registry and Registry.Get and Registry.Get(task.patientId) or nil
end

function Internal.Treatable(patient, task)
    if task and task.patientKind == "player" then
        local info = Internal.FindTreatablePlayerPart and Internal.FindTreatablePlayerPart(patient) or nil
        return info and { info } or {}
    end
    if not patient or not Wounds
        or not Wounds.GetTreatableWounds
    then
        return {}
    end
    return Wounds.GetTreatableWounds(patient)
end

function Executor.CurrentPart(patient, task)
    if task and task.patientKind == "player" then
        local info = Internal.FindTreatablePlayerPart and Internal.FindTreatablePlayerPart(patient) or nil
        return info and info.partId or nil, info
    end
    local entries = Internal.Treatable(patient)
    return entries[1] and tostring(entries[1].partId) or nil, entries[1]
end
Internal.CurrentPart = Executor.CurrentPart

function Internal.CanTreat(actor, task)
    local patient = Internal.Patient(task)
    local pKind = task and tostring(task.patientKind or "npc") or "npc"
    if not patient or (pKind == "npc" and patient.alive == false) then
        return false, "patient_unavailable"
    end
    local allowed, denyReason = Internal.CanAssistPatient(actor, patient, pKind)
    if not allowed then return false, denyReason end
    if task and task.actorId and tostring(task.actorId) ~= tostring(actor.id) then
        return false, "claimed_by_other_doctor"
    end
    if not Internal.CurrentPart(patient, task) then
        return false, "patient_has_no_treatable_wound"
    end
    local plan = Treatment and Treatment.GetNPCBandagePlan
        and Treatment.GetNPCBandagePlan(actor, {
            consumeItem = task and task.policy
                and task.policy.requireItem == true,
        }) or nil
    if not plan then return false, "missing_bandage" end
    return true, patient
end

function Internal.Position(record, body)
    return body and body.getX and body:getX() or tonumber(record and record.x) or 0,
        body and body.getY and body:getY() or tonumber(record and record.y) or 0,
        body and body.getZ and body:getZ() or tonumber(record and record.z) or 0
end

function Internal.InTreatmentRange(actor, actorBody, patient, patientBody)
    local ax, ay, az = Internal.Position(actor, actorBody)
    local px, py, pz = Internal.Position(patient, patientBody)
    local range = tonumber(Const and Const.BANDAGE_RANGE) or 3
    if math.abs(az - pz) >= 1 then return false end
    return (ax - px) * (ax - px) + (ay - py) * (ay - py)
        <= range * range
end

function Internal.ResolveLootPosition(patient, partId, patientBody)
    local health = patient and patient.health or {}
    local downed = tostring(health.state or "") == "incapacitated"
        or patientBody and patientBody.isOnFloor
        and patientBody:isOnFloor() == true
    partId = tostring(partId or "")
    if downed or LOW_PARTS[partId] then return "Low" end
    if HIGH_PARTS[partId] then return "High" end
    return "Mid"
end

function Internal.ResolveLootBump(lootPosition)
    if lootPosition == "Low" then return "LootLow" end
    if lootPosition == "High" then return "LootHigh" end
    return "Loot"
end

function Internal.Face(actorBody, patientBody)
    if actorBody and patientBody and actorBody.faceThisObject then
        actorBody:faceThisObject(patientBody)
    end
end

local function combatActive(record)
    local routes = PNC.NeedFacilityAwayRoutes
    if routes and type(routes.IsCombatActive) == "function" then
        return routes.IsCombatActive(record) == true
    end
    local runtime = record and record.runtime or {}
    local now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    return runtime.attackAction ~= nil or runtime.combatTarget ~= nil
        or now < (tonumber(runtime.inCombatUntil) or 0)
end

local function hasTaskBandage(record, task)
    if not record or not task or not Treatment
        or type(Treatment.GetNPCBandagePlan) ~= "function"
    then
        return false
    end
    local requireItem = task.policy
        and task.policy.requireItem == true or false
    local plan = Treatment.GetNPCBandagePlan(record, {
        consumeItem = requireItem,
    })
    return plan ~= nil and (not requireItem or plan.requiresItem == true)
end

local function isUsableDoctor(record, patient, task)
    return Internal.CanAssistPatient(record, patient, task and task.patientKind or "npc") == true
end

local function groupDoctors(task, patient)
    local output = {}
    if not patient or not Registry or type(Registry.ForEach) ~= "function" then
        return output
    end
    Registry.ForEach(function(record)
        if isUsableDoctor(record, patient, task) then
            output[#output + 1] = record
        end
    end)
    table.sort(output, function(left, right)
        local lfa = Treatment and Treatment.GetNPCFirstAidLevel and tonumber(Treatment.GetNPCFirstAidLevel(left)) or 0
        local rfa = Treatment and Treatment.GetNPCFirstAidLevel and tonumber(Treatment.GetNPCFirstAidLevel(right)) or 0
        if lfa ~= rfa then return lfa > rfa end
        return tostring(left.id) < tostring(right.id)
    end)
    return output
end


Internal.id = id
Internal.nonempty = nonempty
Internal.affiliation = affiliation
Internal.factionId = factionId
Internal.communityId = communityId
Internal.ownerKey = ownerKey
Internal.combatActive = combatActive
Internal.hasTaskBandage = hasTaskBandage
Internal.isUsableDoctor = isUsableDoctor
Internal.groupDoctors = groupDoctors
Internal.WorkPolicy = WorkPolicy
Internal.Registry = Registry
Internal.Service = Service
Internal.Status = Status
Internal.Treatment = Treatment
Internal.Const = Const
Internal.Recovery = Recovery
Internal.Wounds = Wounds
Internal.Common = Common
Internal.SupplyNoticeRecipients = supplyNoticeRecipients
Internal.LastSupplyAttemptAt = lastSupplyAttemptAt
Internal.LastSupplyPreflightAt = lastSupplyPreflightAt
Internal.SUPPLY_RETRY_MS = SUPPLY_RETRY_MS
Internal.SUPPLY_PREFLIGHT_MS = SUPPLY_PREFLIGHT_MS
Internal.SUPPLY_NOTICE_RADIUS = SUPPLY_NOTICE_RADIUS
Internal.SUPPLY_NOTICE_REPEAT_MS = SUPPLY_NOTICE_REPEAT_MS

return Executor
