PNC = PNC or {}
PNC.Treatment = PNC.Treatment or {}
PNC.Treatment.Internal = PNC.Treatment.Internal or {}

local Treatment = PNC.Treatment
local Internal = Treatment.Internal
local Core = PNC.Core
local Const = PNC.Const
local Registry = PNC.Registry

local function audit(record, eventName, status, reason, partId, itemType)
    if Internal.LogDebug then
        Internal.LogDebug(record, eventName, "player", status, reason,
            nil, record and record.id, partId, itemType)
    end
end

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

function Treatment.IsPlayerInBandageRange(player, npcId)
    local record = npcId and Registry.Get(npcId) or nil
    return isPlayerInRange(player, record)
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
    local resolvedType
    if not Internal.IsAuthority() then
        audit(record, "complete", "rejected", "not_authority", partId)
        return false, "not_authority"
    end
    if not player or (player.isDead and player:isDead()) then
        audit(record, "complete", "rejected", "invalid_player", partId)
        return false, "invalid_player"
    end
    if not record or record.alive == false then
        audit(record, "complete", "rejected", "npc_missing", partId)
        return false, "npc_missing"
    end
    if not PNC.NPCWounds or not PNC.NPCWounds.Bandage then
        audit(record, "complete", "rejected", "wounds_unavailable", partId)
        return false, "wounds_unavailable"
    end
    if not isPlayerInRange(player, record) then
        audit(record, "complete", "rejected", "too_far", partId)
        return false, "too_far"
    end
    if options.consumeItem ~= false then
        item, container = Internal.FindBandage(player, options.bandageType)
        if not item then
            audit(record, "complete", "rejected", "missing_bandage",
                partId, options.bandageType)
            return false, "missing_bandage"
        end
    end
    resolvedType = options.bandageType
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
        bandageName = Treatment.GetBandageDisplayName(resolvedType, item),
        firstAidLevel = Treatment.GetPlayerFirstAidLevel(player),
        diagnosticRoute = "player",
        syncEvent = "bandaged",
        broadcast = false,
    })
    if not applied then return false, reason end
    if options.consumeItem ~= false then
        container:Remove(item)
        if sendRemoveItemFromContainer then
            sendRemoveItemFromContainer(container, item)
        end
    end
    if PNC.Network and PNC.Network.BroadcastRecord then
        PNC.Network.BroadcastRecord(record, "bandaged")
    end
    if PNC.SocialEventHooks
        and PNC.SocialEventHooks.OnTreatmentCompleted
    then
        PNC.SocialEventHooks.OnTreatmentCompleted(
            player, record, partId, socialContext)
    end
    audit(record, "complete", "applied",
        options.consumeItem == false and "debug_item_not_consumed"
            or "bandaged",
        partId, resolvedType)
    return true, options.consumeItem == false and "bandaged_debug" or "bandaged"
end

return Treatment
