if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local CoreInventory = require "PsychopatzCore/Inventory/PsychopatzInventory"
local InventoryConstants = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local WorldLoot = require "PsychopatzCore/WorldLoot/PsychopatzWorldLoot"
require "PNC/Core/Behaviors/PNC_Behavior_Common"

PNC = PNC or {}
PNC.ScavengeExecutor = PNC.ScavengeExecutor or {}

local Executor = PNC.ScavengeExecutor
local Service = PNC.ScavengeService
local Const = PNC.Const
local Common = PNC.BehaviorCommon

local function sessionForNPC(npcId)
    return Service.Internal.SessionForNPC(npcId)
end

local function liveRecord(npcId)
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(tostring(npcId or "")) or nil
    local body = record and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    if not record or not body then return nil, nil, "npc_not_live" end
    return record, body
end

local function resetPath(record, body, reason)
    if PNC.PathService and PNC.PathService.Commands
        and PNC.PathService.Commands.Reset
    then
        PNC.PathService.Commands.Reset(record, body, reason or "scavenge")
    elseif PNC.PathService and PNC.PathService.Reset then
        PNC.PathService.Reset(body, record)
    end
end

local function laneBlocked(record)
    local lane = record and record.runtime and record.runtime.pathing or nil
    return lane and lane.phase == "blocked",
        lane and (lane.blockReason or lane.cancelReason) or nil
end

local function approachKey(value)
    return string.format("%.2f:%.2f:%d", tonumber(value.x) or 0,
        tonumber(value.y) or 0, math.floor(tonumber(value.z) or 0))
end

local function approachLocation(session, source, location, record, excluded)
    session.approachBySource = session.approachBySource or {}
    local cacheKey = tostring(source.sourceToken) .. "\31"
        .. tostring(record and record.id or "npc")
    local cached = session.approachBySource[cacheKey]
    if cached and not (excluded and excluded[approachKey(cached)]) then
        return cached
    end
    local baseX, baseY = tonumber(location.x), tonumber(location.y)
    local baseZ = tonumber(location.z) or 0
    if not baseX or not baseY then return nil, "source_location_invalid" end
    local checker = PNC.PathService and PNC.PathService.Internal
        and PNC.PathService.Internal.isSquareWalkable or nil
    local exactSquare = source.sourceType == "floor"
        or source.sourceType == "corpse"
    -- Containers occupy their source square. Target an adjacent interaction
    -- tile so native pathing does not run forever against the container while
    -- trying to reach its otherwise-valid square center.
    local offsets = exactSquare and { { 0, 0 } }
        or { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 },
            { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }
    local best, bestDistance
    for _, offset in ipairs(offsets) do
        local x, y = baseX + offset[1], baseY + offset[2]
        local walkable = not checker or checker(x, y, baseZ) == true
        local candidate = { x = x + 0.5, y = y + 0.5, z = baseZ }
        if walkable and not (excluded and excluded[approachKey(candidate)]) then
            local dx = x - (tonumber(record.x) or x)
            local dy = y - (tonumber(record.y) or y)
            local distance = dx * dx + dy * dy
            if not best or distance < bestDistance then
                best = candidate
                bestDistance = distance
            end
        end
    end
    if not best then return nil, "source_interaction_unreachable" end
    session.approachBySource[cacheKey] = best
    return best
end

local function withinInteractionRadius(record, body, location, sourceType)
    local x = body and body.getX and body:getX() or tonumber(record.x)
    local y = body and body.getY and body:getY() or tonumber(record.y)
    local z = body and body.getZ and body:getZ() or tonumber(record.z)
    local targetX = tonumber(location.x)
    local targetY = tonumber(location.y)
    local targetZ = tonumber(location.z) or 0
    if not x or not y or not z or not targetX or not targetY
        or math.floor(z) ~= math.floor(targetZ)
    then return false end
    local dx = x - (targetX + 0.5)
    local dy = y - (targetY + 0.5)
    local radius = sourceType == "container" and 1.85 or 1.35
    return dx * dx + dy * dy <= radius * radius
end

local function completeLease(lease, reason)
    if lease and PNC.TaskLeaseService.Get(lease.leaseId) then
        PNC.Tasking.Commands.Complete(lease.leaseId, reason)
    end
end

local function recordItemQuantity(record, fullType)
    local total = 0
    local items = record and record.inventory and record.inventory.items or {}
    for _, item in pairs(items) do
        if tostring(item.type or "") == tostring(fullType or "") then
            total = total + math.max(1,
                math.floor(tonumber(item.stack) or 1))
        end
    end
    return total
end

local function destinationStore(record, body)
    local container = body and body.getInventory and body:getInventory() or nil
    if not container then return nil, "npc_inventory_unavailable" end
    local physical, reason = CoreInventory.wrapPhysicalInventory(container, {
        recursive = false, syncOnMutation = true,
    })
    if not physical then return nil, reason end
    local destination = { physical = physical }

    function destination:add(itemRecord, quantity)
        local fullType = CoreInventory.getItemFullType(
            itemRecord and itemRecord[InventoryConstants.TYPE_ID])
        if not fullType then return false, "item_type_unknown" end
        local expectedQuantity = math.max(1, math.floor(tonumber(quantity)
            or tonumber(itemRecord[InventoryConstants.QUANTITY]) or 1))
        local canAccept, acceptReason = PNC.Inventory.CanAccept(record, {
            { type = fullType, stack = expectedQuantity },
        })
        if not canAccept then return false, acceptReason end
        local modelCountBefore = recordItemQuantity(record, fullType)
        local physicalCountBefore = physical:count(fullType)
        local ok, added = physical:add(itemRecord, quantity)
        if not ok then return false, added end
        local captured, captureReason = PNC.Inventory.CaptureLooseInventory(
            record, body)
        local physicalCountAfter = physical:count(fullType)
        local modelCountAfter = recordItemQuantity(record, fullType)
        if not captured
            or physicalCountAfter < physicalCountBefore + expectedQuantity
            or modelCountAfter < modelCountBefore + expectedQuantity
        then
            for index = #added, 1, -1 do
                physical:_nativeRemove(added[index])
            end
            PNC.Inventory.CaptureLooseInventory(record, body)
            return false, captureReason or "npc_inventory_commit_unverified"
        end
        return true, added
    end

    function destination:_nativeRemove(item)
        local removed = physical:_nativeRemove(item)
        PNC.Inventory.CaptureLooseInventory(record, body)
        return removed
    end

    return destination
end

local LOOT_SCENE_DURATION_MS = 650

Executor.Internal = Executor.Internal or {}
local Internal = Executor.Internal
Internal.SessionForNPC = sessionForNPC
Internal.LiveRecord = liveRecord
Internal.ResetPath = resetPath
Internal.LaneBlocked = laneBlocked
Internal.ApproachKey = approachKey
Internal.ApproachLocation = approachLocation
Internal.WithinInteractionRadius = withinInteractionRadius
Internal.CompleteLease = completeLease
Internal.RecordItemQuantity = recordItemQuantity
Internal.DestinationStore = destinationStore
Internal.LOOT_SCENE_DURATION_MS = LOOT_SCENE_DURATION_MS

return Executor
