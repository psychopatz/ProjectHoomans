-- Server-authoritative treatment actions for individual NPC body parts.

PNC = PNC or {}
PNC.Treatment = PNC.Treatment or {}

local Treatment = PNC.Treatment
local Core = PNC.Core
local Const = PNC.Const
local Registry = PNC.Registry
local Inventory = PNC.Inventory
local Skills = PNC.Skills
local Types = PNC.Types

local BANDAGE_NAMES = {
    ["Base.AlcoholBandage"] = "Sterilized Bandage",
    ["Base.Bandage"] = "Bandage",
    ["Base.Bandaid"] = "Adhesive Bandage",
    ["Base.AlcoholRippedSheets"] = "Sterilized Ripped Sheets",
    ["Base.RippedSheets"] = "Ripped Sheets",
}

local function targetPosition(record)
    local body = record and Registry.GetLiveZombie(record.id) or nil
    return body and body:getX() or tonumber(record and record.x) or 0,
        body and body:getY() or tonumber(record and record.y) or 0,
        body and body:getZ() or tonumber(record and record.z) or 0
end

local function isPlayerInRange(player, record)
    local x
    local y
    local z
    if not player or not record then return false end
    x, y, z = targetPosition(record)
    if math.abs((tonumber(player:getZ()) or 0) - z) >= 1 then return false end
    return Core.DistanceSq(player:getX(), player:getY(), x, y)
        <= ((tonumber(Const.BANDAGE_RANGE) or 3) ^ 2)
end

local function bandageTypes()
    return type(Const.BANDAGE_TYPES) == "table" and Const.BANDAGE_TYPES
        or { Const.BANDAGE_TYPE or "Base.Bandage" }
end

local function isBandageType(fullType)
    local types = bandageTypes()
    local i
    if not fullType then return true end
    for i = 1, #types do
        if tostring(types[i]) == tostring(fullType) then return true end
    end
    return false
end

local function bandageDisplayName(fullType, item)
    if item and item.getDisplayName then
        return tostring(item:getDisplayName())
    end
    if item and item.getName then
        return tostring(item:getName())
    end
    return BANDAGE_NAMES[tostring(fullType or "")]
        or tostring(fullType or "Ripped Sheets")
end

local function playerFirstAidLevel(player)
    if player and player.getPerkLevel and Perks and Perks.Doctor then
        return math.max(0, math.min(10,
            math.floor(tonumber(player:getPerkLevel(Perks.Doctor)) or 0)))
    end
    return 0
end

local function isPlayerOwned(record)
    return record and (record.recruited == true
        or record.ownerOnlineID ~= nil
        or (record.ownerUsername ~= nil and tostring(record.ownerUsername) ~= ""))
        or false
end

local function findNPCBandage(record)
    local inv
    local types
    local i
    local item
    local stack
    if not record then return nil end
    inv = Inventory and Inventory.EnsureRecordInventory
        and Inventory.EnsureRecordInventory(record) or record.inventory
    types = bandageTypes()
    for i = 1, #types do
        for _, item in pairs(inv and inv.items or {}) do
            stack = item and tonumber(item.stack) or 1
            if item and tostring(item.type or "") == tostring(types[i])
                and stack > 0
            then
                return {
                    itemID = item.id,
                    fullType = item.type,
                    displayName = BANDAGE_NAMES[tostring(item.type)]
                        or tostring(item.type),
                }
            end
        end
    end
    return nil
end

local function consumeNPCBandage(record, supply, reason)
    if not record or not supply then return false, nil end
    if PNC.SupplyInventory and PNC.SupplyInventory.Consume then
        local ok, _, effect = PNC.SupplyInventory.Consume(
            record,
            supply.itemID,
            {
                resourceKind = "MEDICAL",
                treatment = "BANDAGE",
                required = {},
                source = reason or "npc_bandage",
            }
        )
        return ok, effect and effect.undo or nil
    end
    local inv = Inventory and Inventory.EnsureRecordInventory
        and Inventory.EnsureRecordInventory(record) or record.inventory
    local item = inv and inv.items and inv.items[supply.itemID] or nil
    if not item or not Inventory or not Inventory.ApplyDelta then
        return false, nil
    end
    local undo = Core.DeepCopy(inv)
    local stack = math.max(1, math.floor(tonumber(item.stack) or 1))
    local op = stack > 1
        and { op = "update", itemID = item.id, stack = stack - 1 }
        or { op = "remove", itemID = item.id }
    local applied = Inventory.ApplyDelta(record, { op }, reason or "npc_bandage") == true
    return applied, applied and function()
        record.inventory = undo
        return true
    end or nil
end

local function findBandage(player, requestedType)
    local inventory = player and player.getInventory and player:getInventory() or nil
    local types = requestedType and { requestedType } or bandageTypes()
    local i
    local found
    local item
    local container
    if not isBandageType(requestedType) then return nil, nil end
    for i = 1, #types do
        found = inventory and inventory.getAllTypeRecurse and inventory:getAllTypeRecurse(types[i]) or nil
        item = found and found.size and found:size() > 0 and found:get(0) or nil
        container = item and item.getContainer and item:getContainer() or nil
        if item and container then return item, container end
    end
    return nil, nil
end

function Treatment.FindBandage(player, requestedType)
    return findBandage(player, requestedType)
end

function Treatment.GetPlayerFirstAidLevel(player)
    return playerFirstAidLevel(player)
end

function Treatment.GetNPCFirstAidLevel(record)
    return Skills and Skills.GetLevel and Skills.GetLevel(record, "FirstAid") or 0
end

function Treatment.GetBandageDisplayName(fullType, item)
    return bandageDisplayName(fullType, item)
end

function Treatment.IsPlayerOwnedNPC(record)
    return isPlayerOwned(record)
end

-- Item consumption is an ownership/economy policy, not an execution detail.
-- Colonists represent the player-managed economy and must use a real item.
-- Abstract/non-colonist actors may resolve the same treatment without an
-- inventory item. A non-colonist caller can explicitly opt into item use,
-- but a colonist cannot silently opt out through a normal task payload.
function Treatment.RequiresNPCMedicalItem(record, options)
    options = type(options) == "table" and options or {}
    local colonist = Types and Types.IsColonist
        and Types.IsColonist(record) == true
        or tostring(record and record.tacticalClass or "")
            == tostring(Const.TACTICAL_CLASS_COLONIST or "colonist")
    if colonist then return true end
    return options.consumeItem == true
end

function Treatment.GetNPCMedicalPolicy(record, options)
    local requiresItem = Treatment.RequiresNPCMedicalItem(record, options)
    local constants = PNC.Const or {}
    return {
        mode = requiresItem and "inventory" or "abstract",
        requiresItem = requiresItem,
        bandageType = requiresItem and nil
            or constants.ABSTRACT_MEDICAL_TREATMENT_TYPE
                or "PNC.AbstractMedical",
        bandageName = requiresItem and nil
            or constants.ABSTRACT_MEDICAL_TREATMENT_NAME
                or "Abstract medical treatment",
    }
end

function Treatment.FindNPCBandage(record)
    return findNPCBandage(record)
end

function Treatment.HasNPCBandage(record)
    return findNPCBandage(record) ~= nil
end

function Treatment.GetNPCBandagePlan(record, options)
    local policy = Treatment.GetNPCMedicalPolicy(record, options)
    local supply
    if not policy.requiresItem then
        return {
            fullType = policy.bandageType,
            displayName = policy.bandageName,
            mode = policy.mode,
            requiresItem = false,
        }
    end
    supply = findNPCBandage(record)
    if not supply then return nil end
    supply.mode = policy.mode
    supply.requiresItem = true
    return supply
end

function Treatment.GetNPCBandageDuration(record)
    local skill = Treatment.GetNPCFirstAidLevel(record)
    return math.max(
        tonumber(Const.SELF_BANDAGE_MIN_DURATION_MS) or 3000,
        (tonumber(Const.SELF_BANDAGE_BASE_DURATION_MS) or 6500)
            - skill * (tonumber(Const.SELF_BANDAGE_FIRST_AID_REDUCTION_MS) or 350)
    )
end

function Treatment.ApplyBandage(record, partId, options)
    local applied
    local reason
    options = type(options) == "table" and options or {}
    if not record or record.alive == false then return false, "npc_missing" end
    if not PNC.NPCWounds or not PNC.NPCWounds.Bandage then
        return false, "wounds_unavailable"
    end
    applied, reason = PNC.NPCWounds.Bandage(record, partId, Core.Now(), {
        bandageType = options.bandageType,
        bandageName = options.bandageName,
        firstAidLevel = options.firstAidLevel,
    })
    if not applied then return false, reason end
    record.runtime = record.runtime or {}
    record.runtime.forceSyncEvent = options.syncEvent or "bandaged"
    record.runtime.bandageCompletionRevision =
        (tonumber(record.runtime.bandageCompletionRevision) or 0) + 1
    record.runtime.bandageCompletionAt = Core.Now()
    record.runtime.bandageCompletionPartId = tostring(partId)
    if Registry and Registry.MarkDirty then
        Registry.MarkDirty(record, "wounds")
    end
    if PNC.MedicalCareService
        and PNC.MedicalCareService.ResolveForPatient
    then
        PNC.MedicalCareService.ResolveForPatient(
            "npc", record.id, "patient_wound_resolved")
    end
    if options.broadcast ~= false
        and PNC.Network and PNC.Network.BroadcastRecord
    then
        PNC.Network.BroadcastRecord(record, options.syncEvent or "bandaged")
    end
    return true, "bandaged"
end

function Treatment.TryNPCMedicalTreatment(actorRecord, targetRecord, partId, options)
    local policy
    local supply
    local applied
    local reason
    local consumed
    local undo
    local firstAid
    local resultLabel
    options = type(options) == "table" and options or {}
    if not Core.IsAuthority() then return false, "not_authority" end
    if not actorRecord or actorRecord.alive == false then
        return false, "actor_missing"
    end
    if not targetRecord or targetRecord.alive == false then
        return false, "target_missing"
    end
    policy = Treatment.GetNPCMedicalPolicy(actorRecord, options)
    if policy.requiresItem then
        supply = findNPCBandage(actorRecord)
        if not supply then return false, "missing_bandage" end
        consumed, undo = consumeNPCBandage(
            actorRecord,
            supply,
            options.consumeReason or "npc_medical_treatment"
        )
        if not consumed then return false, "bandage_consumption_failed" end
    end
    firstAid = Treatment.GetNPCFirstAidLevel(actorRecord)
    applied, reason = Treatment.ApplyBandage(targetRecord, partId, {
        bandageType = supply and supply.fullType or policy.bandageType,
        bandageName = supply and supply.displayName or policy.bandageName,
        firstAidLevel = firstAid,
        syncEvent = options.syncEvent
            or (actorRecord == targetRecord and "self_bandaged"
                or "npc_treated"),
        broadcast = false,
    })
    if not applied then
        if undo then undo() end
        return false, reason
    end
    if Skills and Skills.AddXP then
        Skills.AddXP(actorRecord, "FirstAid", 1)
    end
    if Core and Core.LogRecordDebug then
        Core.LogRecordDebug(actorRecord, "NPC " .. tostring(actorRecord.id)
            .. " treated target=" .. tostring(targetRecord.id)
            .. " part=" .. tostring(partId)
            .. " mode=" .. tostring(policy.mode)
            .. " item=" .. tostring(supply and supply.fullType or "none")
            .. " firstAid=" .. tostring(firstAid))
    end
    if PNC.Network and PNC.Network.BroadcastRecord then
        PNC.Network.BroadcastRecord(targetRecord, options.syncEvent
            or (actorRecord == targetRecord and "self_bandaged"
                or "npc_treated"))
    end
    resultLabel = supply and supply.displayName or policy.bandageName
    return true, resultLabel
end

function Treatment.TryNPCBandage(record, partId, options)
    return Treatment.TryNPCMedicalTreatment(record, record, partId, options)
end

function Treatment.BuildMedicalCareSnapshot(record)
    local state = record and record.runtime
        and record.runtime.medicalCare or nil
    if type(state) ~= "table" or state.phase == nil
        or tostring(state.phase) == "idle"
    then
        return nil
    end
    return {
        phase = tostring(state.phase),
        taskId = state.taskId,
        patientId = state.patientId,
        partId = state.partId,
        bump = state.bump,
        lootPosition = state.lootPosition,
        startedAt = state.startedAt,
        finishAt = state.finishAt,
        revision = state.revision,
    }
end

function Treatment.IsPlayerInBandageRange(player, npcId)
    local record = npcId and Registry.Get(npcId) or nil
    return isPlayerInRange(player, record)
end

local function listBandages(player)
    local inventory = player and player.getInventory and player:getInventory() or nil
    local output = {}
    local types = bandageTypes()
    local i
    for i = 1, #types do
        local found = inventory and inventory.getAllTypeRecurse
            and inventory:getAllTypeRecurse(types[i]) or nil
        local count = found and found.size and tonumber(found:size()) or 0
        local item = count > 0 and found:get(0) or nil
        if count > 0 then
            output[#output + 1] = {
                fullType = types[i],
                count = count,
                item = item,
                name = bandageDisplayName(types[i], item),
            }
        end
    end
    return output
end

function Treatment.CountBandages(player)
    local count = 0
    local entries = listBandages(player)
    local i
    for i = 1, #entries do
        count = count + math.max(0, tonumber(entries[i].count) or 0)
    end
    return count
end

function Treatment.ListBandages(player)
    return listBandages(player)
end

function Treatment.TryBandage(player, npcId, partId, options)
    options = type(options) == "table" and options or {}
    local record = npcId and Registry.Get(npcId) or nil
    local item
    local container
    local applied
    local reason
    local wound
    local socialContext
    if not Core.IsAuthority() then return false, "not_authority" end
    if not player or (player.isDead and player:isDead()) then return false, "invalid_player" end
    if not record or record.alive == false then return false, "npc_missing" end
    if not PNC.NPCWounds or not PNC.NPCWounds.Bandage then return false, "wounds_unavailable" end
    if not isPlayerInRange(player, record) then return false, "too_far" end
    if options.consumeItem ~= false then
        item, container = findBandage(player, options.bandageType)
        if not item then return false, "missing_bandage" end
    end
    local resolvedType = options.bandageType
        or item and item.getFullType and item:getFullType()
        or Const.BANDAGE_TYPE
    wound = record.health
        and record.health.body
        and record.health.body.wounds
        and record.health.body.wounds[tostring(partId)] or nil
    socialContext = {
        woundType = wound and wound.type or nil,
        severity = wound and (
            tonumber(wound.damage) or tonumber(wound.severity)
        ) or nil,
    }
    applied, reason = Treatment.ApplyBandage(record, partId, {
        bandageType = resolvedType,
        bandageName = bandageDisplayName(resolvedType, item),
        firstAidLevel = playerFirstAidLevel(player),
        syncEvent = "bandaged",
        broadcast = false,
    })
    if not applied then return false, reason end
    if options.consumeItem ~= false then
        container:Remove(item)
        if sendRemoveItemFromContainer then sendRemoveItemFromContainer(container, item) end
    end
    if PNC.Network and PNC.Network.BroadcastRecord then
        PNC.Network.BroadcastRecord(record, "bandaged")
    end
    if PNC.SocialEventHooks
        and PNC.SocialEventHooks.OnTreatmentCompleted
    then
        PNC.SocialEventHooks.OnTreatmentCompleted(
            player,
            record,
            partId,
            socialContext
        )
    end
    return true, options.consumeItem == false and "bandaged_debug" or "bandaged"
end

return Treatment
