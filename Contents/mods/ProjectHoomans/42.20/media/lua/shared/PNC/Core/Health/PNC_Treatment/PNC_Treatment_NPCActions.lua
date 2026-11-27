PNC = PNC or {}
PNC.Treatment = PNC.Treatment or {}
PNC.Treatment.Internal = PNC.Treatment.Internal or {}

local Treatment = PNC.Treatment
local Internal = Treatment.Internal
local Skills = PNC.Skills

local function audit(record, eventName, route, status, reason, actorId,
    targetId, partId, itemType, mode, firstAidLevel)
    if Internal.LogDebug then
        Internal.LogDebug(record, eventName, route, status, reason,
            actorId, targetId, partId, itemType, mode, firstAidLevel)
    end
end

local function isDirtyDressingType(fullType)
    local lower = string.lower(tostring(fullType or ""))
    return string.find(lower, "dirty", 1, true) ~= nil
end

local function isCorpseObject(obj)
    if not obj then return false end
    if type(instanceof) == "function" then
        local ok, matched = pcall(instanceof, obj, "IsoDeadBody")
        if ok and matched == true then return true end
    end
    if obj.isDeadBody == true then return true end
    local nameFn = obj.getObjectName or obj.getName
    if type(nameFn) == "function" then
        local ok, name = pcall(nameFn, obj)
        local lo = ok and string.lower(tostring(name or "")) or ""
        return lo == "corpse" or lo == "isodeadbody"
    end
    return false
end

local function findNearbyCorpseContainer(actor, body, radius)
    local cell = type(getCell) == "function" and getCell() or nil
    if not cell or type(cell.getGridSquare) ~= "function" then return nil end
    local ox = body and type(body.getX) == "function" and tonumber(body:getX()) or tonumber(actor and actor.x)
    local oy = body and type(body.getY) == "function" and tonumber(body:getY()) or tonumber(actor and actor.y)
    local oz = body and type(body.getZ) == "function" and tonumber(body:getZ()) or tonumber(actor and actor.z) or 0
    if ox == nil or oy == nil then return nil end
    local bx, by, bz = math.floor(ox), math.floor(oy), math.floor(oz)
    local r = math.max(1, math.min(6, math.floor(tonumber(radius) or 4)))
    local bestContainer, bestDistSq = nil, nil

    local function checkList(list, dSq)
        if not list then return end
        local count = type(list.size) == "function" and list:size() or (type(list) == "table" and #list or 0)
        local isJava = type(list.size) == "function" and type(list.get) == "function"
        local startIdx = isJava and 0 or 1
        local endIdx = isJava and (count - 1) or count
        for i = startIdx, endIdx do
            local obj = isJava and list:get(i) or list[i]
            if isCorpseObject(obj) and type(obj.getContainer) == "function" then
                local ok, cont = pcall(obj.getContainer, obj)
                if ok and cont and type(cont.AddItem) == "function" then
                    if not bestDistSq or dSq < bestDistSq then
                        bestContainer, bestDistSq = cont, dSq
                    end
                    return
                end
            end
        end
    end

    for dx = -r, r do
        for dy = -r, r do
            local dSq = dx * dx + dy * dy
            if dSq <= r * r and (not bestDistSq or dSq < bestDistSq) then
                local sq = cell:getGridSquare(bx + dx, by + dy, bz)
                if sq then
                    if type(sq.getStaticMovingObjects) == "function" then
                        checkList(sq:getStaticMovingObjects(), dSq)
                    end
                    if not bestDistSq or dSq < bestDistSq then
                        if type(sq.getObjects) == "function" then
                            checkList(sq:getObjects(), dSq)
                        end
                    end
                end
            end
        end
    end
    return bestContainer
end

-- Unified removed-dressing handler (used by both bandage swaps and healed
-- dressing removal): disposes dirty rags/bandages onto a nearby zombie corpse
-- so PZ's corpse decay garbage-collects them automatically; falls back to NPC
-- inventory for clean items or when no corpse is nearby.
function Treatment.DisposeRemovedDressing(actor, fullType, body)
    if not actor or not fullType or tostring(fullType) == ""
        or tostring(fullType) == "PNC.AbstractMedical"
    then
        return false, "no_item"
    end
    local registry = PNC.Registry
    body = body or (registry and registry.GetLiveZombie and registry.GetLiveZombie(actor.id)) or nil
    if isDirtyDressingType(fullType) then
        local corpseCont = findNearbyCorpseContainer(actor, body, 4)
        if corpseCont then
            local okAdd, addedItem = pcall(corpseCont.AddItem, corpseCont, tostring(fullType))
            if okAdd and addedItem ~= nil then
                if type(isServer) == "function" and isServer() == true
                    and type(sendAddItemToContainer) == "function"
                then
                    pcall(sendAddItemToContainer, corpseCont, addedItem)
                end
                return true, "disposed_on_corpse"
            end
        end
    end
    local inventory = PNC.Inventory
    if not inventory or not inventory.AddItems then return false, "inventory_unavailable" end
    local ok, _, ids = inventory.AddItems(actor, { { type = fullType, stack = 1 } }, "root", "removed_dressing")
    if not ok or not ids or not ids[1] then return false, "add_failed" end
    if body and inventory.MaterializeItem then
        inventory.MaterializeItem(actor, body, ids[1])
    end
    return true, "returned_to_inventory"
end

local function returnDressing(actor, fullType)
    return Treatment.DisposeRemovedDressing(actor, fullType, nil)
end

function Treatment.TryNPCMedicalTreatment(actorRecord, targetRecord,
    partId, options)
    local policy
    local supply
    local applied
    local reason
    local consumed
    local undo
    local firstAid
    local resultLabel
    options = type(options) == "table" and options or {}
    local route = actorRecord == targetRecord and "npc_self" or "npc_assist"
    local debugRecord = targetRecord or actorRecord
    if not Internal.IsAuthority() then
        audit(debugRecord, "complete", route, "rejected", "not_authority",
            actorRecord and actorRecord.id,
            targetRecord and targetRecord.id, partId)
        return false, "not_authority"
    end
    if not actorRecord or actorRecord.alive == false then
        audit(debugRecord, "complete", route, "rejected", "actor_missing",
            actorRecord and actorRecord.id,
            targetRecord and targetRecord.id, partId)
        return false, "actor_missing"
    end
    if not targetRecord or targetRecord.alive == false then
        audit(debugRecord, "complete", route, "rejected", "target_missing",
            actorRecord.id, targetRecord and targetRecord.id, partId)
        return false, "target_missing"
    end
    policy = Treatment.GetNPCMedicalPolicy(actorRecord, options)
    if policy.requiresItem then
        supply = Internal.FindNPCBandage(actorRecord, options.bandageType)
        if not supply then
            audit(targetRecord, "complete", route, "rejected",
                "missing_bandage", actorRecord.id, targetRecord.id, partId)
            return false, "missing_bandage"
        end
        consumed, undo = Internal.ConsumeNPCBandage(
            actorRecord,
            supply,
            options.consumeReason or "npc_medical_treatment")
        if not consumed then
            audit(targetRecord, "complete", route, "rejected",
                "bandage_consumption_failed", actorRecord.id,
                targetRecord.id, partId, supply.fullType)
            return false, "bandage_consumption_failed"
        end
    end
    firstAid = Treatment.GetNPCFirstAidLevel(actorRecord)
    local returnedItem
    applied, reason, returnedItem = Treatment.ApplyBandage(targetRecord, partId, {
        bandageType = supply and supply.fullType or policy.bandageType,
        virtualDressing = not policy.requiresItem,
        bandageName = supply and supply.displayName or policy.bandageName,
        firstAidLevel = firstAid,
        diagnosticRoute = route,
        diagnosticActorId = actorRecord.id,
        syncEvent = options.syncEvent
            or (actorRecord == targetRecord and "self_bandaged"
                or "npc_treated"),
        broadcast = false,
    })
    if not applied then
        if undo then undo() end
        audit(targetRecord, "complete", route, "rejected", reason,
            actorRecord.id, targetRecord.id, partId,
            supply and supply.fullType or policy.bandageType,
            policy.mode, firstAid)
        return false, reason
    end
    if policy.requiresItem then
        returnDressing(actorRecord, returnedItem)
        if PNC.ProvisionScheduler and PNC.ProvisionScheduler.MarkDirty then
            PNC.ProvisionScheduler.MarkDirty(actorRecord, "bandage", 0)
        end
    end
    if Skills and Skills.AddXP then
        Skills.AddXP(actorRecord, "FirstAid", 1)
    end
    if PNC.Network and PNC.Network.BroadcastRecord then
        PNC.Network.BroadcastRecord(targetRecord, options.syncEvent
            or (actorRecord == targetRecord and "self_bandaged"
                or "npc_treated"))
    end
    resultLabel = supply and supply.displayName or policy.bandageName
    audit(targetRecord, "complete", route, "applied", "bandaged",
        actorRecord.id, targetRecord.id, partId,
        supply and supply.fullType or policy.bandageType,
        policy.mode, firstAid)
    return true, resultLabel
end

local Dressing = require "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Dressing"

function Treatment.GetNPCSplintPlan(record, partId)
    local body = record and record.health and record.health.body
    local wound = body and body.wounds and body.wounds[partId]
    if not wound or wound.type ~= "fracture" or wound.splinted or wound.stitched
        or partId == "Head" or partId == "Torso_Upper" or partId == "Torso_Lower" then return nil end
    local support, fabric
    for _, item in pairs(record.inventory and record.inventory.items or {}) do
        if item.id and (tonumber(item.stack) or 1) > 0 then
            if item.type == "Base.Splint" then
                return { itemID = item.id, fullType = item.type, displayName = Internal.BandageDisplayName(item.type) }
            elseif item.type == "Base.RippedSheets" then
                fabric = item.id
            elseif Dressing.IsSplintSupport(item.type) then
                support = item
            end
        end
    end
    if support and fabric then
        return {
            itemID = support.id, fullType = support.type, fabricID = fabric,
            displayName = Internal.BandageDisplayName(support.type),
        }
    end
end

function Treatment.TryNPCSplint(record, partId)
    if not Internal.IsAuthority() or not record or record.alive == false then return false, "invalid_actor" end
    local plan = Treatment.GetNPCSplintPlan(record, partId)
    if not plan then return false, "missing_splint" end
    local ok, undoSupport = Internal.ConsumeNPCBandage(record, plan, "npc_splint_support", "SPLINT")
    if not ok then return false, "splint_consumption_failed" end
    local undoFabric
    if plan.fabricID then
        ok, undoFabric = Internal.ConsumeNPCBandage(record, { itemID = plan.fabricID }, "npc_splint_fabric", "SPLINT")
        if not ok then
            if undoSupport then undoSupport() end
            return false, "splint_consumption_failed"
        end
    end
    local applied, reason = PNC.NPCWounds.Splint(record, partId, PNC.Core.Now(), {
        firstAidLevel = Treatment.GetNPCFirstAidLevel(record), splintItem = plan.fullType,
        splintType = not plan.fabricID and plan.fullType or nil,
    })
    if not applied then
        if undoFabric then undoFabric() end
        if undoSupport then undoSupport() end
        return false, reason
    end
    if PNC.Network and PNC.Network.BroadcastRecord then PNC.Network.BroadcastRecord(record, "splinted") end
    return true, reason
end

function Treatment.TryNPCBandage(record, partId, options)
    return Treatment.TryNPCMedicalTreatment(record, record, partId, options)
end

return Treatment
