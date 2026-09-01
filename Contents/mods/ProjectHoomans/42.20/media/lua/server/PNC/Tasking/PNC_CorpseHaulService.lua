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
local Zones = require "PsychopatzCore/World/PC_ZoneRegistry"
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"

Service.SCAN_INTERVAL_MS = 2000
Service.ACTION_TIMEOUT_MS = 10000
Service.RELEASE_TIMEOUT_MS = 5000
Service.Runtime = Service.Runtime or {
    byTask = {}, byToken = {}, byDrop = {}, nextScanAt = 0,
}
Service.Runtime.byTask = Service.Runtime.byTask or {}
Service.Runtime.byToken = Service.Runtime.byToken or {}
Service.Runtime.byDrop = Service.Runtime.byDrop or {}

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
    local data = corpse and corpse.getModData and corpse:getModData() or nil
    local item = corpse and corpse.getItem and corpse:getItem() or nil
    local fullType = item and item.getFullType and tostring(item:getFullType() or "") or ""
    if not corpse or not data then return false end
    if corpse.isAnimal and corpse:isAnimal() == true then return false end
    if fullType == "Base.CorpseAnimal" then return false end
    -- Hoomans-owned death markers are the default scope. An integration can
    -- opt an external human corpse in explicitly without exposing all player
    -- corpses to automatic NPC hauling.
    return data.PNC_DeathMarkerID ~= nil or data.PNC_CorpseHaulAllowed == true
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

local function hasCorpse(square)
    local result = false
    if not square or not Lifecycle or not Lifecycle.Internal
        or not Lifecycle.Internal.forEachCorpse
    then return false end
    Lifecycle.Internal.forEachCorpse(square, function() result = true end)
    return result
end

local function findDropPoint(facilityId, preferredX, preferredY, preferredZ)
    local region = Stockpile and Stockpile.GetFacilityRegion
        and Stockpile.GetFacilityRegion(facilityId) or nil
    local best
    local bestDistance
    forEachRegionTile(region, function(x, y, z)
        local square = squareAt(x, y, z)
        local state = squareState(x, y, z)
        if square and state == "walkable" and not hasCorpse(square)
            and not Service.Runtime.byDrop[pointKey(x, y, z)]
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

function Service.FindDropPoint(facilityId, preferredX, preferredY, preferredZ)
    return findDropPoint(facilityId, preferredX, preferredY, preferredZ)
end

local function isDropPointAllowed(assignment)
    local x = assignment and assignment.dropX
    local y = assignment and assignment.dropY
    local z = assignment and assignment.dropZ
    if not assignment or not Stockpile then return false end
    if Stockpile.ContainsFacilityRegionTile then
        return Stockpile.ContainsFacilityRegionTile(assignment.facilityId,
            x, y, z) == true
    end
    local region = Stockpile.GetFacilityRegion
        and Stockpile.GetFacilityRegion(assignment.facilityId) or nil
    return region ~= nil and GridRegion.containsPoint(region, x, y, z) == true
end

local function scanBaseCorpses(base)
    local zone = base and base.baseZoneId and Zones.get(base.baseZoneId) or nil
    local found = {}
    local seen = {}
    if not zone or not zone.geometry then return found end
    forEachRegionTile(zone.geometry, function(x, y, z)
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

local function isReserved(token)
    local taskId = Service.Runtime.byToken[tostring(token or "")]
    if taskId and Service.Runtime.byTask[taskId] then return true end
    return false
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

function Service.FindAssignment(record, requestedToken)
    local base = PNC.HomeDutyService and PNC.HomeDutyService.GetBase
        and PNC.HomeDutyService.GetBase(record) or nil
    local live = record and Registry and Registry.GetLiveZombie
        and Registry.GetLiveZombie(record.id) or nil
    local corpses
    local facilities
    local best
    local bestDistance
    if not base or not live then return nil end
    corpses, facilities = scanBaseCorpses(base), stockpileFacilities(base)
    for _, candidate in ipairs(corpses) do
        if (not requestedToken or tostring(candidate.token) == tostring(requestedToken))
            and not isReserved(candidate.token)
        then
            local data = candidate.corpse:getModData()
            local staleTask = data and data.PNC_CorpseHaulTaskId
            if staleTask and not Service.Runtime.byTask[tostring(staleTask)] then
                data.PNC_CorpseHaulTaskId = nil
                transmit(candidate.corpse)
                staleTask = nil
            end
            if not staleTask then
                for _, facility in ipairs(facilities) do
                    local drop = findDropPoint(facility.id, candidate.x, candidate.y, candidate.z)
                    if drop then
                        local dx = live:getX() - candidate.x
                        local dy = live:getY() - candidate.y
                        local distance = dx * dx + dy * dy
                        if not best or distance < bestDistance then
                            best = {
                                taskId = "corpse_haul:" .. tostring(candidate.token),
                                haulToken = candidate.token,
                                corpse = candidate.corpse,
                                baseId = base.id, facilityId = facility.id,
                                sourceX = candidate.x, sourceY = candidate.y,
                                sourceZ = candidate.z,
                                interactionX = candidate.x,
                                interactionY = candidate.y,
                                interactionZ = candidate.z,
                                dropX = drop.x, dropY = drop.y, dropZ = drop.z,
                            }
                            bestDistance = distance
                        end
                    end
                end
            end
        end
    end
    return best
end

function Service.Reserve(assignment, npcId)
    local token = tostring(assignment and assignment.haulToken or "")
    local taskId = tostring(assignment and assignment.taskId or "")
    local dropKey = assignment and pointKey(assignment.dropX,
        assignment.dropY, assignment.dropZ) or ""
    if token == "" or taskId == "" or Service.Runtime.byToken[token]
        or Service.Runtime.byDrop[dropKey]
    then return false, "CORPSE_ALREADY_RESERVED" end
    if not Service.GetCorpseAt(assignment.sourceX, assignment.sourceY,
        assignment.sourceZ, token)
    then return false, "CORPSE_NOT_FOUND" end
    Service.Runtime.byTask[taskId] = {
        taskId = taskId, haulToken = token, npcId = tostring(npcId),
        dropKey = dropKey, phase = "SOURCE_APPROACH", startedAt = Core.Now(),
    }
    Service.Runtime.byToken[token] = taskId
    Service.Runtime.byDrop[dropKey] = taskId
    return true
end

function Service.GetTask(taskId)
    return Service.Runtime.byTask[tostring(taskId or "")]
end

function Service.IsLifecycleProtected(taskId)
    local task = Service.GetTask(taskId)
    if not task or task.phase == "DONE" then return false end
    if task.phase == "FAILED" then
        return Core.Now() < (tonumber(task.releaseUntilAt) or 0)
    end
    return true
end

function Service.IsRecordProtected(record)
    local runtime = record and record.runtime or nil
    local taskId = runtime and runtime.corpseHaulTaskId or nil
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

function Service.SendAction(lease, assignment, action)
    local task = Service.GetTask(lease.taskId)
    local record = Registry.Get(lease.npcId)
    local body = record and Registry.GetLiveZombie(record.id) or nil
    local player = task and task.executorOnlineID
        and Core.ResolvePlayerByOnlineID(task.executorOnlineID) or nil
    local payload
    if not task or not record or not body then return false, "NPC_UNAVAILABLE" end
    if not player then player = nearestPlayer(body) end
    if not player then return false, "NO_EXECUTOR" end
    task.executorOnlineID = tonumber(player:getOnlineID())
    payload = actionPayload(lease, assignment, action)
    if (not Core.IsClientOnly or not Core.IsClientOnly())
        and PNC.CorpseHaulActions
        and PNC.CorpseHaulActions.ReceiveCommand
    then
        if PNC.CorpseHaulActions.ReceiveCommand(payload) ~= true then
            return false, "CLIENT_ACTION_REJECTED"
        end
        return true
    end
    if PNC.Network and PNC.Network.Internal
        and PNC.Network.Internal.SendToPlayer
    then
        return PNC.Network.Internal.SendToPlayer(player,
            PNC.Const.CMD_CORPSE_HAUL_ACTION, payload), nil
    end
    return false, "NETWORK_UNAVAILABLE"
end

local function setOrder(record, lease, assignment, phase)
    local task = Service.GetTask(lease.taskId)
    PNC.OrderSystem.SetOrder(record, {
        kind = "corpse_haul", taskId = lease.taskId,
        haulToken = assignment.haulToken, phase = phase,
        baseId = assignment.baseId, facilityId = assignment.facilityId,
        sourceX = assignment.sourceX, sourceY = assignment.sourceY,
        sourceZ = assignment.sourceZ, interactionX = assignment.interactionX,
        interactionY = assignment.interactionY, interactionZ = assignment.interactionZ,
        dropX = assignment.dropX, dropY = assignment.dropY, dropZ = assignment.dropZ,
        executorOnlineID = task and task.executorOnlineID or nil,
        revision = lease.revision,
    })
end

function Service.Start(lease, assignment)
    local record = Registry.Get(lease.npcId)
    local task = Service.GetTask(lease.taskId)
    local corpse = assignment and Service.GetCorpseAt(assignment.sourceX,
        assignment.sourceY, assignment.sourceZ, assignment.haulToken) or nil
    local data
    if not record or not task then return false, "NPC_UNAVAILABLE" end
    if not corpse then return false, "CORPSE_NOT_FOUND" end
    data = corpse.getModData and corpse:getModData() or nil
    if not data then return false, "CORPSE_METADATA_UNAVAILABLE" end
    lease.corpseHaul = assignment
    record.runtime = record.runtime or {}
    record.runtime.corpseHaulTaskId = lease.taskId
    data.PNC_CorpseHaulTaskId = lease.taskId
    transmit(corpse)
    task.previousOrder = Core.DeepCopy and Core.DeepCopy(record.orderSpec)
        or record.orderSpec
    task.phase = "SOURCE_APPROACH"
    task.assignment = assignment
    setOrder(record, lease, assignment, "SOURCE_APPROACH")
    return true
end

function Service.HandleClientAck(player, args)
    args = type(args) == "table" and args or {}
    local task = Service.GetTask(args.taskId)
    local lease
    local expected
    local event = tostring(args and args.event or "")
    if not task then return false, "TASK_NOT_FOUND" end
    -- The client sends the task id; the lease id is not exposed to the client
    -- as an authority token. Resolve through the runtime assignment instead.
    local foundLease
    local active = PNC.TaskLeaseService and PNC.TaskLeaseService.Active or {}
    for _, candidateLeaseId in ipairs(active) do
        local candidate = PNC.TaskLeaseService.Get(candidateLeaseId)
        if candidate and tostring(candidate.taskId) == tostring(task.taskId) then
            foundLease = candidate
            break
        end
    end
    lease = foundLease or lease
    expected = task.executorOnlineID
    if not lease or tostring(lease.npcId) ~= tostring(args.npcId or "")
        or expected and tonumber(player and player:getOnlineID()) ~= tonumber(expected)
    then return false, "ACK_NOT_AUTHORIZED" end

    if event == "grab_request" or event == "drop_request" then
        local assignment = lease.corpseHaul
        local body = Registry.GetLiveZombie(lease.npcId)
        local playerID = player and player.getOnlineID
            and tonumber(player:getOnlineID()) or nil
        local distance
        local corpse
        local target
        local sent
        if not Core.IsClientOnly or Core.IsClientOnly() ~= true then
            return false, "REQUEST_NOT_CLIENT_ONLY"
        end
        if not playerID or not expected or playerID ~= tonumber(expected) then
            return false, "REQUEST_NOT_AUTHORIZED"
        end
        if not assignment or not body then
            return false, "NPC_UNAVAILABLE"
        end
        if event == "grab_request" then
            if task.phase ~= "GRAB_PENDING" then
                return false, "GRAB_NOT_PENDING"
            end
            distance = Core.Distance(body:getX(), body:getY(),
                assignment.sourceX, assignment.sourceY)
            if distance > 1.5 then return false, "SOURCE_TOO_FAR" end
            if body.isDraggingCorpse and body:isDraggingCorpse() then
                return false, "ALREADY_DRAGGING"
            end
            corpse = Service.GetCorpseAt(assignment.sourceX,
                assignment.sourceY, assignment.sourceZ, assignment.haulToken)
            if not corpse or not body.pickUpCorpse then
                return false, "CORPSE_NOT_FOUND"
            end
            -- The client request carries no coordinates or corpse object.
            -- The server resolves the reserved assignment again, then calls
            -- the same vanilla grapple API used by ISGrabCorpseAction.
            body:pickUpCorpse(corpse, "BwdDrag")
            if not body.isDraggingCorpse or not body:isDraggingCorpse() then
                return false, "GRAB_REJECTED"
            end
            target = body.getGrapplingTarget
                and body:getGrapplingTarget() or nil
            task.grappleTargetOnlineID = target and target.getOnlineID
                and tonumber(target:getOnlineID()) or nil
            task.serverGrappleAppliedAt = Core.Now()
            task.lastAckAt, task.lastAck = Core.Now(), event
            sent = Service.SendAction(lease, assignment, "sync_grab")
            return sent == true, sent == true and nil or "SYNC_UNAVAILABLE"
        end

        if task.phase ~= "DROP_PENDING" then
            return false, "DROP_NOT_PENDING"
        end
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
        -- Release is intentionally issued on the server. Build 42 applies
        -- the resulting corpse spawn on the authoritative world object.
        body:setDoGrappleLetGo()
        task.serverGrappleReleasedAt = Core.Now()
        task.lastAckAt, task.lastAck = Core.Now(), event
        sent = Service.SendAction(lease, assignment, "sync_drop")
        return sent == true, sent == true and nil or "SYNC_UNAVAILABLE"
    end

    if event == "grab_queued" or event == "grab_complete" then
        task.lastAckAt, task.lastAck = Core.Now(), event
        return true
    end
    if event == "drop_queued" or event == "drop_complete" then
        task.lastAckAt, task.lastAck = Core.Now(), event
        return true
    end
    if event == "failed" then
        task.failedReason = tostring(args.reason or "client_action_failed")
        task.phase = "FAILED"
        return false, task.failedReason
    end
    return false, "UNKNOWN_ACK"
end

local function clearCorpseTaskMarker(x, y, z, token)
    local corpse = Service.GetCorpseAt(x, y, z, token)
    local data = corpse and corpse.getModData and corpse:getModData() or nil
    if data and tostring(data.PNC_CorpseHaulTaskId or "") ~= "" then
        data.PNC_CorpseHaulTaskId = nil
        transmit(corpse)
    end
end

local function restorePreviousOrder(record, task)
    local current = record and record.orderSpec
    local kind = current and tostring(current.kind or "") or ""
    if not record or not task or kind ~= "corpse_haul" then return end
    if PNC.OrderSystem and PNC.OrderSystem.SetOrder then
        PNC.OrderSystem.SetOrder(record, task.previousOrder)
    else
        record.orderSpec = task.previousOrder
    end
end

local function cleanupAssignment(lease, phase, retainLifecycle)
    local assignment = lease and lease.corpseHaul
    local task = assignment and Service.GetTask(lease.taskId) or nil
    if task then
        task.phase = phase
        if retainLifecycle then
            task.releaseUntilAt = Core.Now() + Service.RELEASE_TIMEOUT_MS
        end
    end
    local record = lease and Registry.Get(lease.npcId) or nil
    if not retainLifecycle and assignment then
        clearCorpseTaskMarker(assignment.sourceX, assignment.sourceY,
            assignment.sourceZ, assignment.haulToken)
        clearCorpseTaskMarker(assignment.dropX, assignment.dropY,
            assignment.dropZ, assignment.haulToken)
    end
    restorePreviousOrder(record, task)
    if assignment then
        if not retainLifecycle then
            Service.Runtime.byTask[lease.taskId] = nil
            Service.Runtime.byToken[tostring(assignment.haulToken)] = nil
            Service.Runtime.byDrop[pointKey(assignment.dropX, assignment.dropY,
                assignment.dropZ)] = nil
        end
    end
    if record and record.runtime and (not retainLifecycle
        or tostring(record.runtime.corpseHaulTaskId or "")
            == tostring(lease.taskId or ""))
    then
        if not retainLifecycle then record.runtime.corpseHaulTaskId = nil end
    end
end

function Service.Finish(lease, success)
    local assignment = lease and lease.corpseHaul
    local corpse = assignment and Service.GetCorpseAt(assignment.dropX,
        assignment.dropY, assignment.dropZ, assignment.haulToken) or nil
    if success and corpse then
        local data = corpse:getModData()
        local deadRecord = data and data.PNC_DeathMarkerID
            and (Registry.GetDeathMarker and Registry.GetDeathMarker(
                data.PNC_DeathMarkerID) or Registry.Get(data.PNC_DeathMarkerID))
            or nil
        data.PNC_CorpseHaulTaskId = nil
        transmit(corpse)
        if deadRecord and deadRecord.alive == false and PNC.BodyLifecycle
            and PNC.BodyLifecycle.Internal and PNC.BodyLifecycle.Internal.stampCorpse
        then
            PNC.BodyLifecycle.Internal.stampCorpse(deadRecord, corpse,
                assignment.haulToken)
            PNC.BodyLifecycle.Internal.transmitCorpseState(corpse)
        end
    end
    cleanupAssignment(lease, success and "DONE" or "FAILED")
    return success == true
end

local function fail(lease, reason)
    local assignment = lease.corpseHaul
    local corpse = assignment and Service.GetCorpseAt(assignment.sourceX,
        assignment.sourceY, assignment.sourceZ, assignment.haulToken) or nil
    local body = Registry.GetLiveZombie(lease.npcId)
    local wasDragging = body and body.isDraggingCorpse
        and body:isDraggingCorpse() or false
    local task = Service.GetTask(lease and lease.taskId)
    if wasDragging and task then
        task.releaseX, task.releaseY, task.releaseZ = body:getX(),
            body:getY(), body:getZ()
    end
    if wasDragging
        and body.setDoGrappleLetGo
    then
        body:setDoGrappleLetGo()
    end
    if corpse and corpse.getModData then
        corpse:getModData().PNC_CorpseHaulTaskId = nil
        transmit(corpse)
    end
    cleanupAssignment(lease, "FAILED", wasDragging)
    return PNC.Tasking.Commands.Complete(lease.leaseId, reason or "failed")
end

function Service.Tick(lease)
    local assignment = lease and lease.corpseHaul
    local record = lease and Registry.Get(lease.npcId) or nil
    local body = record and Registry.GetLiveZombie(record.id) or nil
    local task = lease and Service.GetTask(lease.taskId) or nil
    local now = Core.Now()
    local distance
    if not assignment or not record or not body or not task then
        if lease and lease.leaseId and PNC.Tasking
            and PNC.Tasking.Commands and PNC.Tasking.Commands.CancelLease
        then
            PNC.Tasking.Commands.CancelLease(lease.leaseId,
                "CORPSE_HAUL_UNAVAILABLE")
            return true
        end
        return false
    end
    if task.phase == "SOURCE_APPROACH" then
        distance = Core.Distance(body:getX(), body:getY(), assignment.interactionX,
            assignment.interactionY)
        if distance <= 1.5 then
            local executor = task.executorOnlineID and Core.ResolvePlayerByOnlineID
                and Core.ResolvePlayerByOnlineID(task.executorOnlineID) or nil
            executor = executor or nearestPlayer(body)
            task.executorOnlineID = task.executorOnlineID
                or executor and executor:getOnlineID()
            task.phase = "GRAB_PENDING"
            PNC.TaskLeaseService.SetPhase(lease.leaseId, "WAITING")
            setOrder(record, lease, assignment, "GRAB_PENDING")
            local sent, reason = Service.SendAction(lease, assignment, "grab")
            if not sent then return fail(lease, reason) end
            task.actionRequestedAt = now
        end
        return true
    end
    if task.phase == "GRAB_PENDING" then
        if body.isDraggingCorpse and body:isDraggingCorpse() then
            task.phase = "DESTINATION_APPROACH"
            PNC.TaskLeaseService.SetPhase(lease.leaseId, "TRAVEL")
            setOrder(record, lease, assignment, "DESTINATION_APPROACH")
        elseif now - (tonumber(task.actionRequestedAt) or now)
            > Service.ACTION_TIMEOUT_MS
        then
            return fail(lease, "GRAB_TIMEOUT")
        end
        return true
    end
    if task.phase == "DESTINATION_APPROACH" then
        if not isDropPointAllowed(assignment) then
            return fail(lease, "DROP_REGION_INVALID")
        end
        distance = Core.Distance(body:getX(), body:getY(), assignment.dropX,
            assignment.dropY)
        if distance <= 0.8 and body.isDraggingCorpse
            and body:isDraggingCorpse()
        then
            task.phase = "DROP_PENDING"
            PNC.TaskLeaseService.SetPhase(lease.leaseId, "ATOMIC_COMMIT")
            setOrder(record, lease, assignment, "DROP_PENDING")
            local sent, reason = Service.SendAction(lease, assignment, "drop")
            if not sent then return fail(lease, reason) end
            task.actionRequestedAt = now
        end
        return true
    end
    if task.phase == "DROP_PENDING" then
        if not body.isDraggingCorpse or not body:isDraggingCorpse() then
            if Service.GetCorpseAt(assignment.dropX, assignment.dropY,
                assignment.dropZ, assignment.haulToken)
            then
                Service.Finish(lease, true)
                return PNC.Tasking.Commands.Complete(lease.leaseId, "corpse_dropped")
            end
        elseif now - (tonumber(task.actionRequestedAt) or now)
            > Service.ACTION_TIMEOUT_MS
        then
            return fail(lease, "DROP_TIMEOUT")
        end
        return true
    end
    return fail(lease, task.failedReason or "UNKNOWN_HAUL_PHASE")
end

function Service.Cancel(lease, reason)
    local record = Registry.Get(lease and lease.npcId)
    local body = record and Registry.GetLiveZombie(record.id) or nil
    local wasDragging = body and body.isDraggingCorpse
        and body:isDraggingCorpse() or false
    local task = Service.GetTask(lease and lease.taskId)
    if wasDragging and task then
        task.releaseX, task.releaseY, task.releaseZ = body:getX(),
            body:getY(), body:getZ()
    end
    if wasDragging
        and body.setDoGrappleLetGo
    then body:setDoGrappleLetGo() end
    cleanupAssignment(lease, "FAILED", wasDragging)
    return true
end

function Service.CanContinue(lease)
    return lease and lease.corpseHaul and Service.GetTask(lease.taskId) ~= nil
end

function Service.Pump(now)
    now = tonumber(now) or Core.Now()
    if now < (tonumber(Service.Runtime.nextScanAt) or 0) then return end
    Service.Runtime.nextScanAt = now + Service.SCAN_INTERVAL_MS
    for taskId, task in pairs(Service.Runtime.byTask) do
        if task.phase == "FAILED"
            and now >= (tonumber(task.releaseUntilAt) or 0)
        then
            local record = Registry and Registry.Get and Registry.Get(task.npcId)
                or nil
            if record and record.runtime
                and tostring(record.runtime.corpseHaulTaskId or "")
                    == tostring(taskId)
            then
                record.runtime.corpseHaulTaskId = nil
                if Registry.MarkDirty then
                    Registry.MarkDirty(record, "corpse_haul")
                end
            end
            clearCorpseTaskMarker(task.sourceX, task.sourceY,
                task.sourceZ, task.haulToken)
            clearCorpseTaskMarker(task.dropX, task.dropY,
                task.dropZ, task.haulToken)
            clearCorpseTaskMarker(task.releaseX, task.releaseY,
                task.releaseZ, task.haulToken)
            Service.Runtime.byTask[taskId] = nil
            if Service.Runtime.byToken[task.haulToken] == taskId then
                Service.Runtime.byToken[task.haulToken] = nil
            end
            if Service.Runtime.byDrop[task.dropKey] == taskId then
                Service.Runtime.byDrop[task.dropKey] = nil
            end
        end
    end
    if not Registry or not Registry.ForEach or not PNC.Tasking
        or not PNC.Tasking.Events then return end
    Registry.ForEach(function(record)
        local role = record and record.affiliation
            and record.affiliation.communityRole or ""
        if record and record.alive ~= false and role == "worker"
            and (not record.allowedJobs
                or record.allowedJobs.CorpseHaul ~= false)
            and not (record.runtime and record.runtime.corpseHaulTaskId)
            and Service.FindAssignment(record)
        then
            PNC.Tasking.Events.Emit("CORPSE_HAUL_AVAILABLE", {
                record = record, source = "CorpseHaulService",
                cause = "corpse_scan",
            })
        end
    end)
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
