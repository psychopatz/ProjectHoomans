-- Server-authoritative physical corpse hauling.
--
-- Corpses are deliberately not put into ColonyStorageRepository: a corpse is
-- an engine world object and vanilla grappling temporarily replaces it with a
-- grapple-only IsoZombie. The service reserves by a persistent corpse token,
-- not by Lua object identity, so the handoff remains valid in multiplayer.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CorpseHaulService = PNC.CorpseHaulService or {}
PNC.CorpseHaulService.Internal = PNC.CorpseHaulService.Internal or {}

local Service = PNC.CorpseHaulService
local Internal = Service.Internal
local Core = PNC.Core
local Registry = PNC.Registry
local Lifecycle = PNC.BodyLifecycle
local Stockpile = PNC.StockpileAccessService
local Work = PNC.WorkService
local WorkRepository = PNC.WorkRepository
local Status = PNC.WorkDefinitions and PNC.WorkDefinitions.STATUS or {}
local Zones = require "PsychopatzCore/World/PC_ZoneRegistry"
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"

Service.SCAN_INTERVAL_MS = 2000
Service.ACTION_TIMEOUT_MS = 10000
Service.Runtime = Service.Runtime or {
    byTask = {}, byToken = {}, byDrop = {}, nextScanAt = 0,
}
Service.Runtime.byTask = Service.Runtime.byTask or {}
Service.Runtime.byToken = Service.Runtime.byToken or {}
Service.Runtime.byDrop = Service.Runtime.byDrop or {}
Service.MAX_CONFIGURED_REGION_TILES = 100000

local function pointKey(x, y, z)
    return tostring(math.floor(tonumber(x) or 0)) .. ":"
        .. tostring(math.floor(tonumber(y) or 0)) .. ":"
        .. tostring(math.floor(tonumber(z) or 0))
end

local function squareAt(x, y, z)
    local cell = getCell and getCell() or nil
    if not cell or not cell.getGridSquare then return nil end
    return cell:getGridSquare(math.floor(tonumber(x) or 0),
        math.floor(tonumber(y) or 0), math.floor(tonumber(z) or 0))
end

local function squareState(x, y, z)
    local square = squareAt(x, y, z)
    local pathInternal = PNC.PathService and PNC.PathService.Internal
    if not square then return "unloaded" end
    if pathInternal and pathInternal.isSquareWalkable then
        local walkable = pathInternal.isSquareWalkable(x, y, z)
        return walkable == true and "walkable" or "blocked"
    end
    if square.isSolid and square:isSolid() == true then return "blocked" end
    if square.isSolidTrans and square:isSolidTrans() == true then return "blocked" end
    if square.isFree then return square:isFree(false) and "walkable" or "blocked" end
    return "walkable"
end

local function numericKeys(source)
    local keys = {}
    for key, _ in pairs(type(source) == "table" and source or {}) do
        local value = tonumber(key)
        if value then keys[#keys + 1] = value end
    end
    table.sort(keys)
    return keys
end

local function regionRows(level)
    return type(level) == "table" and (level.rows or level) or nil
end

local function forEachRegionTile(region, callback)
    if type(region) ~= "table" or type(callback) ~= "function" then return end
    local levels = region.levels or {}
    for _, z in ipairs(numericKeys(levels)) do
        local rows = regionRows(levels[z]) or {}
        for _, y in ipairs(numericKeys(rows)) do
            local spans = rows[y] or {}
            for index = 1, #spans, 2 do
                local first, last = tonumber(spans[index]),
                    tonumber(spans[index + 1])
                if first and last and first <= last then
                    for x = first, last do callback(x, y, z) end
                end
            end
        end
    end
end

local function terminalWorkOrder(order)
    local status = order and tostring(order.status or "") or ""
    return status == "CANCELLED" or status == "COMPLETED"
        or status == "FAILED"
end

local function workOrderForToken(token, baseId)
    if not WorkRepository or not WorkRepository.Load then return nil end
    WorkRepository.Load()
    for _, order in pairs(WorkRepository.State.byId or {}) do
        local payload = order and order.payload or nil
        if order and order.operation == "CORPSE_HAUL"
            and not terminalWorkOrder(order)
            and (baseId == nil or tostring(order.baseId or "")
                == tostring(baseId or ""))
            and tostring(payload and payload.haulToken or "")
                == tostring(token or "")
        then
            return order
        end
    end
    return nil
end

local function dropReserved(x, y, z)
    local key = pointKey(x, y, z)
    if Service.Runtime.byDrop[key] then return true end
    if not WorkRepository or not WorkRepository.Load then return false end
    WorkRepository.Load()
    for _, order in pairs(WorkRepository.State.byId or {}) do
        local payload = order and order.payload or nil
        if order and order.operation == "CORPSE_HAUL"
            and not terminalWorkOrder(order)
            and tonumber(payload and payload.dropX) == tonumber(x)
            and tonumber(payload and payload.dropY) == tonumber(y)
            and tonumber(payload and payload.dropZ) == tonumber(z)
        then
            return true
        end
    end
    return false
end

local function configuredRegion(region)
    if type(region) ~= "table" or not GridRegion.normalize
        or not GridRegion.countTiles
    then return nil end
    local normalized = GridRegion.normalize(region)
    return GridRegion.countTiles(normalized) > 0 and normalized or nil
end

local function configurationFor(base)
    local raw = base and base.corpseHaul
    if type(raw) ~= "table" then return nil end
    return {
        sourceRegion = configuredRegion(raw.sourceRegion),
        destinationRegion = configuredRegion(raw.destinationRegion),
        revision = tonumber(raw.revision) or 0,
    }
end

function Service.GetConfiguration(baseOrId)
    local base = type(baseOrId) == "table" and baseOrId
        or PNC.BaseService and PNC.BaseService.Get
            and PNC.BaseService.Get(baseOrId) or nil
    local configuration = configurationFor(base)
    if not configuration then return nil end
    return PNC.Core and PNC.Core.DeepCopy
        and PNC.Core.DeepCopy(configuration) or configuration
end

local function validateConfiguredRegion(region)
    if not GridRegion.validate or not GridRegion.countTiles then
        return nil, "REGION_VALIDATION_UNAVAILABLE"
    end
    local valid, reason, normalized = GridRegion.validate(region)
    if not valid then return nil, reason end
    local tileCount = GridRegion.countTiles(normalized)
    if tileCount > Service.MAX_CONFIGURED_REGION_TILES then
        return nil, "REGION_CAPACITY_EXCEEDED"
    end
    if GridRegion.isConnected and not GridRegion.isConnected(normalized, 4) then
        return nil, "REGION_DISCONNECTED"
    end
    return normalized
end

function Service.SetConfiguration(player, args)
    args = type(args) == "table" and args or {}
    local base = PNC.BaseService and PNC.BaseService.Get
        and PNC.BaseService.Get(args.baseId) or nil
    local permissions = PNC.BaseValidationService
    local source, destination
    local reason
    if not base then return false, "BASE_NOT_FOUND" end
    if not permissions or not permissions.CanUse
        or permissions.CanUse(player, base) ~= true
    then return false, "NO_PERMISSION" end
    source, reason = validateConfiguredRegion(args.sourceRegion)
    if not source then return false, reason end
    destination, reason = validateConfiguredRegion(args.destinationRegion)
    if not destination then return false, reason end
    base.corpseHaul = {
        schemaVersion = 1,
        sourceRegion = source,
        destinationRegion = destination,
        revision = (tonumber(base.corpseHaul and base.corpseHaul.revision) or 0) + 1,
    }
    base.revision = (tonumber(base.revision) or 0) + 1
    if PNC.SettlementRepository and PNC.SettlementRepository.MarkDirty then
        PNC.SettlementRepository.MarkDirty()
    end
    if PNC.SettlementRepository and PNC.SettlementRepository.Save then
        PNC.SettlementRepository.Save()
    end
    return true, "CORPSE_HAUL_ZONES_SAVED", {
        baseId = base.id,
        corpseHaul = Service.GetConfiguration(base),
    }
end

function Service.ClearConfiguration(player, args)
    args = type(args) == "table" and args or {}
    local base = PNC.BaseService and PNC.BaseService.Get
        and PNC.BaseService.Get(args.baseId) or nil
    local permissions = PNC.BaseValidationService
    if not base then return false, "BASE_NOT_FOUND" end
    if not permissions or not permissions.CanUse
        or permissions.CanUse(player, base) ~= true
    then return false, "NO_PERMISSION" end
    if not base.corpseHaul then
        return false, "CORPSE_HAUL_NOT_CONFIGURED"
    end
    base.corpseHaul = nil
    base.revision = (tonumber(base.revision) or 0) + 1
    if PNC.SettlementRepository and PNC.SettlementRepository.MarkDirty then
        PNC.SettlementRepository.MarkDirty()
    end
    if PNC.SettlementRepository and PNC.SettlementRepository.Save then
        PNC.SettlementRepository.Save()
    end
    return true, "CORPSE_HAUL_ZONES_CLEARED", { baseId = base.id }
end

local function transmit(object)
    if object and object.transmitModData then object:transmitModData() end
end

function Service.GetCorpseToken(corpse, create)
    local data = corpse and corpse.getModData and corpse:getModData() or nil
    local token
    if not data then return nil end
    token = data.PNC_CorpseHaulToken or data.PNC_CorpseToken
    if token ~= nil and tostring(token) ~= "" then return tostring(token) end
    if create ~= true then return nil end
    token = Core.GenerateID("corpse_haul")
    data.PNC_CorpseHaulToken = token
    transmit(corpse)
    return token
end

function Service.IsEligibleCorpse(corpse)
    local item = corpse and corpse.getItem and corpse:getItem() or nil
    local fullType = item and item.getFullType and tostring(item:getFullType() or "") or ""
    if not corpse then return false end
    if corpse.isAnimal and corpse:isAnimal() == true then return false end
    if fullType == "Base.CorpseAnimal" then return false end
    -- forEachCorpse already restricts this object to the engine's corpse
    -- collection. The home-service check belongs to worker authorization, not
    -- corpse ownership: ordinary vanilla human corpses are valid haul targets.
    return true
end

function Service.GetCorpseAt(x, y, z, token)
    local square = squareAt(x, y, z)
    local found
    if not square or not Lifecycle or not Lifecycle.Internal
        or not Lifecycle.Internal.forEachCorpse
    then return nil end
    Lifecycle.Internal.forEachCorpse(square, function(corpse)
        local candidateToken = Service.GetCorpseToken(corpse, false)
        if not found and Service.IsEligibleCorpse(corpse)
            and (token == nil or tostring(candidateToken or "") == tostring(token))
        then
            found = corpse
        end
    end)
    return found
end

function Service.CountCorpsesInRegion(region)
    local total = 0
    local eligible = 0
    local cell = getCell and getCell() or nil
    if not cell or not cell.getGridSquare
        or not Lifecycle or not Lifecycle.Internal
        or not Lifecycle.Internal.forEachCorpse
    then
        return nil, nil
    end
    forEachRegionTile(region, function(x, y, z)
        local square = squareAt(x, y, z)
        if square then
            Lifecycle.Internal.forEachCorpse(square, function(corpse)
                total = total + 1
                if Service.IsEligibleCorpse(corpse) then
                    eligible = eligible + 1
                end
            end)
        end
    end)
    return total, eligible
end

local function hasCorpse(square)
    local result = false
    if not square or not Lifecycle or not Lifecycle.Internal
        or not Lifecycle.Internal.forEachCorpse
    then return false end
    Lifecycle.Internal.forEachCorpse(square, function() result = true end)
    return result
end

local function findDropPoint(facilityId, preferredX, preferredY, preferredZ,
    allowedRegion)
    local region = allowedRegion
    if not region then
        region = Stockpile and Stockpile.GetFacilityRegion
            and Stockpile.GetFacilityRegion(facilityId) or nil
    end
    local best
    local bestDistance
    forEachRegionTile(region, function(x, y, z)
        local square = squareAt(x, y, z)
        local state = squareState(x, y, z)
        if square and state == "walkable" and not hasCorpse(square)
            and not dropReserved(x, y, z)
        then
            local dx = x - (tonumber(preferredX) or x)
            local dy = y - (tonumber(preferredY) or y)
            local dz = z - (tonumber(preferredZ) or z)
            local distance = dx * dx + dy * dy + dz * dz
            if not best or distance < bestDistance then
                best = { x = x, y = y, z = z }
                bestDistance = distance
            end
        end
    end)
    return best
end

local function isDropPointAllowed(assignment)
    local x = assignment and assignment.dropX
    local y = assignment and assignment.dropY
    local z = assignment and assignment.dropZ
    if not assignment then return false end
    if assignment.destinationRegion then
        return GridRegion.containsPoint(assignment.destinationRegion, x, y, z)
    end
    if not Stockpile then return false end
    if Stockpile.ContainsFacilityRegionTile then
        return Stockpile.ContainsFacilityRegionTile(assignment.facilityId,
            x, y, z) == true
    end
    local region = Stockpile.GetFacilityRegion
        and Stockpile.GetFacilityRegion(assignment.facilityId) or nil
    return region ~= nil and GridRegion.containsPoint(region, x, y, z) == true
end

local function scanBaseCorpses(base)
    local configuration = configurationFor(base)
    local zone = base and base.baseZoneId and Zones.get(base.baseZoneId) or nil
    local sourceRegion = configuration and configuration.sourceRegion
        or zone and zone.geometry or nil
    local found = {}
    local seen = {}
    if not sourceRegion then return found end
    forEachRegionTile(sourceRegion, function(x, y, z)
        local square = squareAt(x, y, z)
        if square and Lifecycle and Lifecycle.Internal
            and Lifecycle.Internal.forEachCorpse
        then
            Lifecycle.Internal.forEachCorpse(square, function(corpse)
                local token
                if Service.IsEligibleCorpse(corpse) then
                    token = Service.GetCorpseToken(corpse, true)
                    if token and not seen[token] then
                        seen[token] = true
                        found[#found + 1] = {
                            corpse = corpse, token = token,
                            x = math.floor(corpse:getX()),
                            y = math.floor(corpse:getY()),
                            z = math.floor(corpse:getZ()),
                        }
                    end
                end
            end)
        end
    end)
    return found
end

local function stockpileFacilities(base)
    local output = {}
    for facilityId, present in pairs(base and base.facilityIds or {}) do
        local facility = present == true and PNC.SettlementRepository
            and PNC.SettlementRepository.GetFacility(facilityId) or nil
        if facility and facility.definitionId == "stockpile"
            and (facility.constructionState == "BUILT"
                or facility.constructionState == "RECONSTRUCTING")
            and Stockpile and Stockpile.GetFacilityRegion
            and Stockpile.GetFacilityRegion(facility.id)
        then
            output[#output + 1] = facility
        end
    end
    table.sort(output, function(a, b) return tostring(a.id) < tostring(b.id) end)
    return output
end

function Service.GetTask(taskId)
    return Service.Runtime.byTask[tostring(taskId or "")]
end

function Service.IsLifecycleProtected(taskId)
    local task = Service.GetTask(taskId)
    if task then return true end
    local order
    if WorkRepository and WorkRepository.Get then
        order = WorkRepository.Get(taskId)
    end
    return order ~= nil and order.operation == "CORPSE_HAUL"
        and not terminalWorkOrder(order)
end

function Service.IsRecordProtected(record)
    local runtime = record and record.runtime or nil
    local taskId = runtime and (runtime.corpseHaulTaskId
        or runtime.workOrderId) or nil
    return taskId ~= nil and Service.IsLifecycleProtected(taskId)
end

local function nearestPlayer(body)
    local nearest
    local nearestDistance
    if not Core or not Core.ForEachPlayer then return nil end
    Core.ForEachPlayer(function(player)
        local dx = body:getX() - player:getX()
        local dy = body:getY() - player:getY()
        local distance = dx * dx + dy * dy
        if not nearest or distance < nearestDistance then
            nearest, nearestDistance = player, distance
        end
    end)
    return nearest
end

local function actionPayload(lease, assignment, action)
    local task = Service.GetTask(lease.taskId)
    return {
        action = action, taskId = lease.taskId, npcId = lease.npcId,
        haulToken = assignment.haulToken,
        sourceX = assignment.sourceX, sourceY = assignment.sourceY,
        sourceZ = assignment.sourceZ, dropX = assignment.dropX,
        dropY = assignment.dropY, dropZ = assignment.dropZ,
        executorOnlineID = task and task.executorOnlineID or nil,
        grappleTargetOnlineID = task and task.grappleTargetOnlineID or nil,
    }
end

local function isMultiplayerSession()
    return type(isMultiplayer) == "function" and isMultiplayer() == true
end

local function sendVisualSync(lease, assignment, action)
    local task = Service.GetTask(lease.taskId)
    local record = Registry.Get(lease.npcId)
    local body = record and Registry.GetLiveZombie(record.id) or nil
    local player
    local payload
    local sent
    if not isMultiplayerSession() then return true end
    if not task or not body then return true end
    if task.executorOnlineID and Core.ResolvePlayerByOnlineID then
        player = Core.ResolvePlayerByOnlineID(task.executorOnlineID)
    end
    if not player then player = nearestPlayer(body) end
    if not player then
        task.visualSyncPending = true
        return true
    end
    if player.getOnlineID then
        task.executorOnlineID = tonumber(player:getOnlineID())
    end
    payload = actionPayload(lease, assignment, action)
    if not PNC.Network or not PNC.Network.Internal
        or not PNC.Network.Internal.SendToPlayer
    then
        task.visualSyncPending = true
        return true
    end
    local ok, result = pcall(function()
        return PNC.Network.Internal.SendToPlayer(player,
            PNC.Const.CMD_CORPSE_HAUL_ACTION, payload)
    end)
    sent = ok and result ~= false
    task.visualSyncPending = not sent
    return true
end

local function applyGrab(task, body, assignment)
    local corpse
    local target
    local ok
    if not body.isDraggingCorpse or not body.pickUpCorpse then
        return false, "GRAPPLE_UNAVAILABLE"
    end
    if body:isDraggingCorpse() then return false, "ALREADY_DRAGGING" end
    corpse = Service.GetCorpseAt(assignment.sourceX, assignment.sourceY,
        assignment.sourceZ, assignment.haulToken)
    if not corpse then return false, "CORPSE_NOT_FOUND" end
    ok = pcall(function() body:pickUpCorpse(corpse, "BwdDrag") end)
    if not ok then return false, "GRAB_CALL_FAILED" end
    if not body:isDraggingCorpse() then return false, "GRAB_REJECTED" end
    target = body.getGrapplingTarget and body:getGrapplingTarget() or nil
    task.grappleTargetOnlineID = target and target.getOnlineID
        and tonumber(target:getOnlineID()) or nil
    task.serverGrappleAppliedAt = Core.Now()
    return true
end

local function applyDrop(task, body, assignment)
    local distance
    local ok
    if not isDropPointAllowed(assignment) then
        return false, "DROP_REGION_INVALID"
    end
    distance = Core.Distance(body:getX(), body:getY(),
        assignment.dropX, assignment.dropY)
    if distance > 1.0 then return false, "DROP_TOO_FAR" end
    if not body.isDraggingCorpse or not body:isDraggingCorpse() then
        return false, "NOT_DRAGGING"
    end
    if not body.setDoGrappleLetGo then
        return false, "GRAPPLE_RELEASE_UNAVAILABLE"
    end
    ok = pcall(function() body:setDoGrappleLetGo() end)
    if not ok then return false, "DROP_CALL_FAILED" end
    task.serverGrappleReleasedAt = Core.Now()
    return true
end

function Service.SendAction(lease, assignment, action)
    local task = Service.GetTask(lease.taskId)
    local record = Registry.Get(lease.npcId)
    local body = record and Registry.GetLiveZombie(record.id) or nil
    local ok
    local reason
    if not task or not record or not body then return false, "NPC_UNAVAILABLE" end
    if action == "grab" then
        ok, reason = applyGrab(task, body, assignment)
    elseif action == "drop" then
        ok, reason = applyDrop(task, body, assignment)
    else
        return false, "UNKNOWN_CORPSE_ACTION"
    end
    if not ok then return false, reason end
    task.lastAction, task.lastActionAt = action, Core.Now()
    sendVisualSync(lease, assignment,
        action == "grab" and "sync_grab" or "sync_drop")
    return true
end

local function clearCorpseTaskMarker(x, y, z, token)
    local corpse = Service.GetCorpseAt(x, y, z, token)
    local data = corpse and corpse.getModData and corpse:getModData() or nil
    if data and tostring(data.PNC_CorpseHaulTaskId or "") ~= "" then
        data.PNC_CorpseHaulTaskId = nil
        transmit(corpse)
    end
end

-- WorkService integration -------------------------------------------------
--
-- Corpse hauling is a physical world-object operation, so it still needs
-- corpse scanning and the grapple protocol below. Assignment, ownership,
-- home gating, persistence, cancellation, and lease execution, however, all
-- belong to the same durable work pipeline as research.

local function assignmentForWorkOrder(order)
    local payload = order and order.payload or nil
    local token = tostring(payload and payload.haulToken or "")
    if token == "" then return nil end
    local sourceX = tonumber(payload.sourceX)
    local sourceY = tonumber(payload.sourceY)
    local sourceZ = tonumber(payload.sourceZ)
    local dropX = tonumber(payload.dropX)
    local dropY = tonumber(payload.dropY)
    local dropZ = tonumber(payload.dropZ)
    if not sourceX or not sourceY or not sourceZ
        or not dropX or not dropY or not dropZ
    then return nil end
    return {
        taskId = tostring(order.id), haulToken = token,
        baseId = order.baseId, facilityId = payload.facilityId,
        sourceX = sourceX, sourceY = sourceY, sourceZ = sourceZ,
        interactionX = tonumber(payload.interactionX) or sourceX,
        interactionY = tonumber(payload.interactionY) or sourceY,
        interactionZ = tonumber(payload.interactionZ) or sourceZ,
        dropX = dropX, dropY = dropY, dropZ = dropZ,
        destinationRegion = payload.destinationRegion
            and (Core.DeepCopy and Core.DeepCopy(payload.destinationRegion)
                or payload.destinationRegion) or nil,
    }
end

local function workTaskFor(order, lease, assignment)
    local taskId = tostring(order and order.id or lease and lease.taskId or "")
    local task = Service.Runtime.byTask[taskId]
    local record = Registry and Registry.Get and Registry.Get(lease.npcId) or nil
    local corpse = Service.GetCorpseAt(assignment.sourceX, assignment.sourceY,
        assignment.sourceZ, assignment.haulToken)
    if not task then
        task = {
            taskId = taskId, haulToken = assignment.haulToken,
            npcId = tostring(lease.npcId),
            dropKey = pointKey(assignment.dropX, assignment.dropY,
                assignment.dropZ),
            phase = tostring(order.phase or "SOURCE_APPROACH"),
            startedAt = Core.Now(),
        }
        Service.Runtime.byTask[taskId] = task
        Service.Runtime.byToken[assignment.haulToken] = taskId
        Service.Runtime.byDrop[task.dropKey] = taskId
    end
    if record then
        record.runtime = record.runtime or {}
        record.runtime.corpseHaulTaskId = taskId
    end
    if corpse and corpse.getModData then
        local data = corpse:getModData()
        if data then
            data.PNC_CorpseHaulTaskId = taskId
            transmit(corpse)
        end
    end
    task.assignment = assignment
    task.phase = tostring(order.phase or task.phase or "SOURCE_APPROACH")
    lease.corpseHaul = assignment
    return task
end

local function setWorkPhase(order, lease, phase, status, target)
    local record = Registry and Registry.Get and Registry.Get(order.workerId)
        or nil
    local assignment = assignmentForWorkOrder(order)
    order.phase, order.status = phase, status
    order.livePhase = phase
    order.updatedAt, order.lastProgressAt = Core.Now(), Core.Now()
    order.revision = (tonumber(order.revision) or 0) + 1
    if target then order.stationTarget = {
        x = target.x, y = target.y, z = target.z,
    } end
    if lease then
        local task = Service.Runtime.byTask[tostring(order.id)]
        if task then task.phase = phase end
        if PNC.TaskLeaseService and PNC.TaskLeaseService.SetPhase then
            local leasePhase
            if phase == "GRAB_PENDING" then
                leasePhase = "WAITING"
            elseif phase == "DROP_PENDING" then
                leasePhase = "ATOMIC_COMMIT"
            elseif phase == "SOURCE_APPROACH"
                or phase == "DESTINATION_APPROACH"
            then
                leasePhase = "TRAVEL"
            else
                leasePhase = "WORKING"
            end
            PNC.TaskLeaseService.SetPhase(lease.leaseId, leasePhase)
        end
    end
    if record and assignment and target and PNC.WorkService
        and PNC.WorkService.Internal
        and PNC.WorkService.Internal.setLiveOrder
    then
        PNC.WorkService.Internal.setLiveOrder(record, order, target, phase)
    end
    if WorkRepository then WorkRepository.MarkDirty() end
end

local function clearWorkRuntime(order, releasePoint)
    local taskId = tostring(order and order.id or "")
    local task = Service.Runtime.byTask[taskId]
    local assignment = assignmentForWorkOrder(order)
    local record = order and order.workerId and Registry and Registry.Get
        and Registry.Get(order.workerId) or nil
    if releasePoint then
        clearCorpseTaskMarker(releasePoint.x, releasePoint.y, releasePoint.z,
            assignment and assignment.haulToken)
    end
    if assignment then
        clearCorpseTaskMarker(assignment.sourceX, assignment.sourceY,
            assignment.sourceZ, assignment.haulToken)
        clearCorpseTaskMarker(assignment.dropX, assignment.dropY,
            assignment.dropZ, assignment.haulToken)
        Service.Runtime.byToken[assignment.haulToken] = nil
        Service.Runtime.byDrop[pointKey(assignment.dropX, assignment.dropY,
            assignment.dropZ)] = nil
    end
    Service.Runtime.byTask[taskId] = nil
    if record and record.runtime
        and tostring(record.runtime.corpseHaulTaskId or "") == taskId
    then
        record.runtime.corpseHaulTaskId = nil
    end
    if task then task.phase = "DONE" end
end

local function workTargetProvider(order, worker, live)
    local assignment = assignmentForWorkOrder(order)
    local corpse
    local data
    if not live then return { ok = false, reason = "LIVE_WORKER_REQUIRED" } end
    if not assignment then return { ok = false, reason = "CORPSE_PAYLOAD_INVALID" } end
    corpse = Service.GetCorpseAt(assignment.sourceX, assignment.sourceY,
        assignment.sourceZ, assignment.haulToken)
    if not corpse then return { ok = false, reason = "CORPSE_NOT_FOUND" } end
    data = corpse.getModData and corpse:getModData() or nil
    if data and data.PNC_CorpseHaulTaskId
        and tostring(data.PNC_CorpseHaulTaskId) ~= tostring(order.id)
    then
        return { ok = false, reason = "CORPSE_ALREADY_RESERVED" }
    end
    return {
        ok = true, componentId = "corpse:" .. assignment.haulToken,
        claimKey = "corpse:" .. assignment.haulToken,
        targetKind = "corpse", target = {
            x = assignment.interactionX, y = assignment.interactionY,
            z = assignment.interactionZ,
        },
        phase = "SOURCE_APPROACH",
    }
end

local function completeWorkOrder(order)
    local assignment = assignmentForWorkOrder(order)
    local corpse = assignment and Service.GetCorpseAt(assignment.dropX,
        assignment.dropY, assignment.dropZ, assignment.haulToken) or nil
    local data = corpse and corpse.getModData and corpse:getModData() or nil
    if not corpse or not data then return false, "CORPSE_NOT_AT_DESTINATION" end
    data.PNC_CorpseHaulTaskId = nil
    transmit(corpse)
    local marker = data.PNC_DeathMarkerID
        and Registry.GetDeathMarker and Registry.GetDeathMarker(
            data.PNC_DeathMarkerID) or nil
    if marker and marker.alive == false and PNC.BodyLifecycle
        and PNC.BodyLifecycle.Internal
        and PNC.BodyLifecycle.Internal.stampCorpse
    then
        PNC.BodyLifecycle.Internal.stampCorpse(marker, corpse,
            assignment.haulToken)
        if PNC.BodyLifecycle.Internal.transmitCorpseState then
            PNC.BodyLifecycle.Internal.transmitCorpseState(corpse)
        end
    end
    clearWorkRuntime(order)
    return true
end

local function cancelWorkOrder(order)
    local record = order and order.workerId and Registry and Registry.Get
        and Registry.Get(order.workerId) or nil
    local body = record and Registry.GetLiveZombie
        and Registry.GetLiveZombie(record.id) or nil
    local releasePoint
    if body and body.isDraggingCorpse and body:isDraggingCorpse() then
        releasePoint = { x = body:getX(), y = body:getY(), z = body:getZ() }
        if body.setDoGrappleLetGo then body:setDoGrappleLetGo() end
    end
    clearWorkRuntime(order, releasePoint)
    return true
end

local function tickWorkOrder(order, lease)
    order = WorkRepository and WorkRepository.Get(order and order.id) or order
    local assignment = assignmentForWorkOrder(order)
    local record = order and Registry and Registry.Get
        and Registry.Get(order.workerId) or nil
    local body = record and Registry.GetLiveZombie
        and Registry.GetLiveZombie(record.id) or nil
    local task
    local now = Core.Now()
    local distance
    if not assignment or not record or not body then
        return false, "LIVE_WORKER_REQUIRED"
    end
    task = workTaskFor(order, lease, assignment)
    task.phase = tostring(order.phase or task.phase or "SOURCE_APPROACH")
    if task.phase == "SOURCE_APPROACH" then
        distance = Core.Distance(body:getX(), body:getY(),
            assignment.interactionX, assignment.interactionY)
        if distance <= 1.5 then
            setWorkPhase(order, lease, "GRAB_PENDING", Status.WORKING, {
                x = assignment.interactionX, y = assignment.interactionY,
                z = assignment.interactionZ,
            })
            local sent, reason = Service.SendAction(lease, assignment, "grab")
            if not sent then return false, reason end
            task.actionRequestedAt = now
        end
        return true
    end
    if task.phase == "GRAB_PENDING" then
        if body.isDraggingCorpse and body:isDraggingCorpse() then
            setWorkPhase(order, lease, "DESTINATION_APPROACH",
                Status.TRAVEL_TO_STATION, {
                    x = assignment.dropX, y = assignment.dropY,
                    z = assignment.dropZ,
                })
        elseif now - (tonumber(task.actionRequestedAt) or now)
            > Service.ACTION_TIMEOUT_MS
        then
            return false, "GRAB_TIMEOUT"
        end
        return true
    end
    if task.phase == "DESTINATION_APPROACH" then
        if not isDropPointAllowed(assignment) then
            return false, "DROP_REGION_INVALID"
        end
        distance = Core.Distance(body:getX(), body:getY(),
            assignment.dropX, assignment.dropY)
        if distance <= 0.8 and body.isDraggingCorpse
            and body:isDraggingCorpse()
        then
            setWorkPhase(order, lease, "DROP_PENDING", Status.WORKING, {
                x = assignment.dropX, y = assignment.dropY,
                z = assignment.dropZ,
            })
            local sent, reason = Service.SendAction(lease, assignment, "drop")
            if not sent then return false, reason end
            task.actionRequestedAt = now
        end
        return true
    end
    if task.phase == "DROP_PENDING" then
        if not body.isDraggingCorpse or not body:isDraggingCorpse() then
            if Service.GetCorpseAt(assignment.dropX, assignment.dropY,
                assignment.dropZ, assignment.haulToken)
            then
                local ok, reason = Work.Commands.AddProgress(order.id,
                    order.workerId, order.requiredWork)
                return ok == true, reason
            end
        elseif now - (tonumber(task.actionRequestedAt) or now)
            > Service.ACTION_TIMEOUT_MS
        then
            return false, "DROP_TIMEOUT"
        end
        return true
    end
    return false, "UNKNOWN_HAUL_PHASE"
end

local function findBaseAssignment(base)
    local configuration = configurationFor(base)
    local destinationRegion = configuration and configuration.destinationRegion
    local facilities = destinationRegion and {} or stockpileFacilities(base)
    local corpses = scanBaseCorpses(base)
    for _, candidate in ipairs(corpses) do
        if not workOrderForToken(candidate.token, base.id)
            and not Service.Runtime.byToken[candidate.token]
        then
            local data = candidate.corpse:getModData()
            local stale = data and data.PNC_CorpseHaulTaskId
            if stale and not Service.GetTask(stale) then
                data.PNC_CorpseHaulTaskId = nil
                transmit(candidate.corpse)
                stale = nil
            end
            if not stale then
                local destinations = destinationRegion and { {} } or facilities
                for _, facility in ipairs(destinations) do
                    local facilityId = facility and facility.id or nil
                    local drop = findDropPoint(facilityId, candidate.x,
                        candidate.y, candidate.z, destinationRegion)
                    if drop then
                        return {
                            haulToken = candidate.token,
                            baseId = base.id, facilityId = facilityId,
                            sourceX = candidate.x, sourceY = candidate.y,
                            sourceZ = candidate.z,
                            interactionX = candidate.x,
                            interactionY = candidate.y,
                            interactionZ = candidate.z,
                            dropX = drop.x, dropY = drop.y, dropZ = drop.z,
                            destinationRegion = destinationRegion
                                and (Core.DeepCopy
                                    and Core.DeepCopy(destinationRegion)
                                    or destinationRegion) or nil,
                        }
                    end
                end
            end
        end
    end
    return nil
end

local function homeBaseForRecord(record)
    local home = PNC.HomeDutyService
    local affiliation = record and record.affiliation or {}
    local colonyId = tostring(affiliation.communityID or "")
    if home and home.GetBase then
        local base = home.GetBase(record)
        if base then return base end
    end
    if colonyId ~= "" and PNC.BaseService
        and PNC.BaseService.GetForColony
    then
        local base = PNC.BaseService.GetForColony(colonyId)
        if base then return base end
    end
    return nil
end

local function currentWorkOrderFor(record)
    local runtime = record and record.runtime or nil
    local orderId = runtime and runtime.workOrderId or nil
    local order = orderId and WorkRepository and WorkRepository.Get(orderId)
        or nil
    return order and not terminalWorkOrder(order) and order or nil
end

local function markManualOrder(order, record)
    if not order or not record then return false, "CORPSE_HAUL_ORDER_INVALID" end
    if order.workerId and tostring(order.workerId) ~= tostring(record.id) then
        return false, "CORPSE_HAUL_ALREADY_ASSIGNED"
    end
    if order.requiredWorkerId
        and tostring(order.requiredWorkerId) ~= tostring(record.id)
    then
        return false, "CORPSE_HAUL_ALREADY_ASSIGNED"
    end
    order.requiredWorkerId = tostring(record.id)
    order.priority = 100
    order.manual = true
    if order.status == Status.PAUSED then
        order.status = Status.WAITING_FOR_WORKER
    end
    order.blockedReason = nil
    order.updatedAt = Core.Now()
    order.revision = (tonumber(order.revision) or 0) + 1
    if WorkRepository and WorkRepository.MarkDirty then
        WorkRepository.MarkDirty()
    end
    if Work and Work.Internal and Work.Internal.markAssignmentDirty then
        Work.Internal.markAssignmentDirty(order,
            "MANUAL_CORPSE_HAUL_REQUESTED")
    end
    return true, order
end

local function manualResult(record, ok, reason, order, details)
    if Core and Core.Log then
        local message = "manual_corpse_haul npc="
            .. tostring(record and record.id or "unknown")
            .. " result=" .. tostring(ok == true)
            .. " reason=" .. tostring(reason or "unknown")
        if order and order.id then
            message = message .. " order=" .. tostring(order.id)
        end
        if type(details) == "table" then
            for _, key in ipairs({ "corpses", "eligible" }) do
                if details[key] ~= nil then
                    message = message .. " " .. key .. "="
                        .. tostring(details[key])
                end
            end
        end
        Core.Log(ok == true and "INFO" or "WARN", message)
    end
    return ok, reason, order
end

local function findManualOrder(base, record)
    if not WorkRepository or not WorkRepository.Load then return nil end
    WorkRepository.Load()
    local orders = {}
    for _, order in pairs(WorkRepository.State.byId or {}) do
        local assignment = assignmentForWorkOrder(order)
        local status = order and order.status
        local eligibleStatus = status == Status.QUEUED
            or status == Status.WAITING_FOR_WORKER
            or status == Status.PAUSED
        if order and order.operation == "CORPSE_HAUL"
            and tostring(order.baseId or "") == tostring(base.id or "")
            and eligibleStatus and assignment
            and (not order.workerId
                or tostring(order.workerId) == tostring(record.id))
            and (not order.requiredWorkerId
                or tostring(order.requiredWorkerId) == tostring(record.id))
            and Service.GetCorpseAt(assignment.sourceX, assignment.sourceY,
                assignment.sourceZ, assignment.haulToken)
        then
            orders[#orders + 1] = order
        end
    end
    table.sort(orders, function(left, right)
        local leftCreated = tonumber(left.createdAt) or 0
        local rightCreated = tonumber(right.createdAt) or 0
        if leftCreated ~= rightCreated then return leftCreated < rightCreated end
        return tostring(left.id or "") < tostring(right.id or "")
    end)
    return orders[1]
end

local function reevaluateManualOrder(record)
    local tasking = PNC.Tasking and PNC.Tasking.Commands
    if tasking and tasking.ReevaluateNow then
        tasking.ReevaluateNow({
            npcId = tostring(record.id), source = "CorpseHaulService",
            cause = "manual_corpse_haul_requested",
        })
    end
end

function Service.RequestManual(record)
    local base
    local configuration
    local current
    local existing
    local assignment
    local order
    local reason
    local sourceCorpses
    local eligibleCorpses
    local runtime = record and record.runtime or nil
    local now = Core.Now()
    if not record or record.alive == false then
        return manualResult(record, false, "NPC_UNAVAILABLE")
    end
    if record.health and record.health.state == "incapacitated" then
        return manualResult(record, false, "NPC_INCAPACITATED")
    end
    if runtime and (runtime.attackAction or runtime.target
        or now < (tonumber(runtime.inCombatUntil) or 0))
    then
        return manualResult(record, false, "NPC_BUSY")
    end
    current = currentWorkOrderFor(record)
    if current and current.operation ~= "CORPSE_HAUL" then
        return manualResult(record, false, "NPC_BUSY")
    end
    base = homeBaseForRecord(record)
    if not base then return manualResult(record, false, "BASE_NOT_FOUND") end
    configuration = configurationFor(base)
    if not PNC.HomeDutyService or not PNC.HomeDutyService.IsAtHome then
        return manualResult(record, false, "HOME_SERVICE_UNAVAILABLE")
    end
    if not PNC.HomeDutyService.IsAtHome(record, base.id) then
        return manualResult(record, false, "NPC_NOT_AT_HOME")
    end
    if not Registry or not Registry.GetLiveZombie
        or not Registry.GetLiveZombie(record.id)
    then
        return manualResult(record, false, "LIVE_WORKER_REQUIRED")
    end
    if current then
        local accepted = markManualOrder(current, record)
        if accepted then reevaluateManualOrder(record) end
        return manualResult(record, accepted,
            accepted and "CORPSE_HAUL_ORDER_FORCED"
                or "CORPSE_HAUL_ORDER_INVALID", accepted and current or nil)
    end
    existing = findManualOrder(base, record)
    if existing then
        local accepted, acceptedReason = markManualOrder(existing, record)
        if accepted then reevaluateManualOrder(record) end
        return manualResult(record, accepted,
            accepted and "CORPSE_HAUL_ORDER_FORCED" or acceptedReason,
            accepted and existing or nil)
    end
    assignment = findBaseAssignment(base)
    if not assignment then
        sourceCorpses, eligibleCorpses = Service.CountCorpsesInRegion(
            configuration and configuration.sourceRegion)
        return manualResult(record, false, "NO_CORPSE_HAUL_AVAILABLE", nil, {
            corpses = sourceCorpses, eligible = eligibleCorpses,
        })
    end
    order, reason = Work.Commands.Queue({
        operation = "CORPSE_HAUL", colonyId = base.colonyId,
        factionId = base.factionId, baseId = base.id,
        quantity = 1, requiredWork = 1, priority = 100,
        requiredWorkerId = record.id, manual = true,
        requiresHome = true, autoReturnHome = true,
        phase = "SOURCE_APPROACH",
        payload = {
            haulToken = assignment.haulToken,
            sourceX = assignment.sourceX, sourceY = assignment.sourceY,
            sourceZ = assignment.sourceZ,
            interactionX = assignment.interactionX,
            interactionY = assignment.interactionY,
            interactionZ = assignment.interactionZ,
            dropX = assignment.dropX, dropY = assignment.dropY,
            dropZ = assignment.dropZ,
            facilityId = assignment.facilityId,
            destinationRegion = assignment.destinationRegion,
            configurationRevision = configuration and configuration.revision or 0,
        },
    })
    if not order then
        return manualResult(record, false,
            reason or "CORPSE_HAUL_ORDER_FAILED")
    end
    reevaluateManualOrder(record)
    return manualResult(record, true, "CORPSE_HAUL_ORDER_FORCED", order)
end

local function queuePendingOrders()
    local settlements = PNC.SettlementRepository
    local queued = 0
    if not Work or not Work.Commands or not Work.Commands.Queue
        or not settlements or not settlements.Load
    then return queued end
    settlements.Load()
    for _, base in pairs(settlements.State and settlements.State.bases or {}) do
        local assignment = findBaseAssignment(base)
        while assignment do
            local configuration = configurationFor(base)
            local order = Work.Commands.Queue({
                operation = "CORPSE_HAUL", colonyId = base.colonyId,
                factionId = base.factionId, baseId = base.id,
                quantity = 1, requiredWork = 1, priority = 10,
                requiresHome = true, autoReturnHome = true,
                phase = "SOURCE_APPROACH",
                payload = {
                    haulToken = assignment.haulToken,
                    sourceX = assignment.sourceX,
                    sourceY = assignment.sourceY,
                    sourceZ = assignment.sourceZ,
                    interactionX = assignment.interactionX,
                    interactionY = assignment.interactionY,
                    interactionZ = assignment.interactionZ,
                    dropX = assignment.dropX, dropY = assignment.dropY,
                    dropZ = assignment.dropZ,
                    facilityId = assignment.facilityId,
                    destinationRegion = assignment.destinationRegion,
                    configurationRevision = configuration
                        and configuration.revision or 0,
                },
            })
            if not order then break end
            queued = queued + 1
            assignment = findBaseAssignment(base)
        end
    end
    return queued
end

local function bindWorkService()
    if not Work or not Work.RegisterTargetProvider
        or not Work.RegisterExecution
        or not Work.RegisterCompletion
    then return false end
    Work.RegisterTargetProvider("CORPSE_HAUL", workTargetProvider)
    Work.RegisterExecution("CORPSE_HAUL", tickWorkOrder)
    Work.RegisterCompletion("CORPSE_HAUL", completeWorkOrder)
    Work.CancellationHandlers = Work.CancellationHandlers or {}
    Work.CancellationHandlers.CORPSE_HAUL = cancelWorkOrder
    return true
end

bindWorkService()

function Service.Pump(now)
    now = tonumber(now) or Core.Now()
    if now < (tonumber(Service.Runtime.nextScanAt) or 0) then return end
    Service.Runtime.nextScanAt = now + Service.SCAN_INTERVAL_MS
    queuePendingOrders()
end

if Events and Events.OnTick and not Service.TickHookRegistered then
    Events.OnTick.Add(function() Service.Pump() end)
    Service.TickHookRegistered = true
end

Internal.pointKey = pointKey
Internal.forEachRegionTile = forEachRegionTile
Internal.findDropPoint = findDropPoint
Internal.scanBaseCorpses = scanBaseCorpses

return Service
