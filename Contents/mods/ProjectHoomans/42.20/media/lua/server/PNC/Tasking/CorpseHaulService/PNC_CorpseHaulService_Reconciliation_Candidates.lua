-- Corpse haul candidate discovery, identity scoring, and reservation repair.
--
-- This provider owns the physical-corpse candidate boundary used by both
-- dispatch and active reconciliation.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.CorpseHaulService
local Internal = Service.Internal
local Core = PNC.Core
local Lifecycle = PNC.BodyLifecycle
local WorkRepository = PNC.WorkRepository

local function same(value, expected)
    if value == nil or expected == nil then return false end
    return tostring(value) == tostring(expected)
end

local function pointMatches(candidate, x, y, z)
    return candidate
        and tonumber(candidate.x) == math.floor(tonumber(x) or 0)
        and tonumber(candidate.y) == math.floor(tonumber(y) or 0)
        and tonumber(candidate.z) == math.floor(tonumber(z) or 0)
end

local function describeCorpse(corpse, fallbackX, fallbackY, fallbackZ)
    if not corpse or not Service.IsEligibleCorpse(corpse) then return nil end
    local data = corpse.getModData and corpse:getModData() or nil
    local x = corpse.getX and tonumber(corpse:getX()) or tonumber(fallbackX)
    local y = corpse.getY and tonumber(corpse:getY()) or tonumber(fallbackY)
    local z = corpse.getZ and tonumber(corpse:getZ()) or tonumber(fallbackZ)
    local token = Service.GetCorpseToken(corpse, false)
    local fallbackSquare = fallbackX and fallbackY and fallbackZ
        and Internal.squareAt(fallbackX, fallbackY, fallbackZ) or nil
    local corpseSquare = corpse.getSquare and corpse:getSquare() or nil
    if fallbackSquare and corpseSquare == fallbackSquare
        and (math.floor(x or 0) ~= math.floor(tonumber(fallbackX) or 0)
            or math.floor(y or 0) ~= math.floor(tonumber(fallbackY) or 0)
            or math.floor(z or 0) ~= math.floor(tonumber(fallbackZ) or 0))
    then
        -- The engine can briefly retain an object in one square while its
        -- floating coordinates still point at the previous tile. Membership
        -- is the recoverable authority in that case.
        x, y, z = tonumber(fallbackX), tonumber(fallbackY), tonumber(fallbackZ)
    end
    return {
        corpse = corpse, x = math.floor(x or 0), y = math.floor(y or 0),
        z = math.floor(z or 0),
        token = token, originalToken = token,
        taskId = data and data.PNC_CorpseHaulTaskId or nil,
        carriedBy = data and data.PNC_CorpseHaulCarriedBy or nil,
        deathMarkerId = data and (data.PNC_DeathMarkerID
            or data.PNC_UUID) or nil,
    }
end

local function addCandidate(candidates, seen, corpse, x, y, z)
    if not corpse or seen[corpse] then return end
    local candidate = describeCorpse(corpse, x, y, z)
    if candidate then
        seen[corpse] = true
        candidates[#candidates + 1] = candidate
    end
end

local function addSquareCandidates(candidates, seen, x, y, z)
    local square = Internal.squareAt(x, y, z)
    if not square or not Lifecycle or not Lifecycle.Internal
        or not Lifecycle.Internal.forEachCorpse
    then return end
    Lifecycle.Internal.forEachCorpse(square, function(corpse)
        addCandidate(candidates, seen, corpse, x, y, z)
    end)
end

local function addPoint(points, seen, x, y, z)
    x, y, z = tonumber(x), tonumber(y), tonumber(z)
    if not x or not y or not z then return end
    local key = Internal.pointKey(x, y, z)
    if seen[key] then return end
    seen[key] = true
    points[#points + 1] = { x = x, y = y, z = z }
end

local function candidatesForOrder(order, baseCandidates)
    local candidates, seen = {}, {}
    local payload = order and order.payload or {}
    local task = Service.Runtime.byTask[tostring(order and order.id or "")]
    local points, pointSeen = {}, {}
    local body
    local radius
    local dx
    local dy
    for _, candidate in ipairs(baseCandidates or {}) do
        addCandidate(candidates, seen, candidate.corpse,
            candidate.squareX or candidate.x,
            candidate.squareY or candidate.y,
            candidate.squareZ or candidate.z)
    end
    addPoint(points, pointSeen, payload.sourceX, payload.sourceY,
        payload.sourceZ)
    addPoint(points, pointSeen, payload.dropX, payload.dropY, payload.dropZ)
    addPoint(points, pointSeen, payload.carryX, payload.carryY, payload.carryZ)
    addPoint(points, pointSeen, task and task.carryX, task and task.carryY,
        task and task.carryZ)
    if payload.sourceX and payload.sourceY and payload.sourceZ then
        for radius = 0, 2 do
            for dx = -radius, radius do
                for dy = -radius, radius do
                    addPoint(points, pointSeen,
                        math.floor(tonumber(payload.sourceX)) + dx,
                        math.floor(tonumber(payload.sourceY)) + dy,
                        payload.sourceZ)
                end
            end
        end
    end
    if task and task.corpse then addCandidate(candidates, seen, task.corpse) end
    if tostring(order and order.phase or "") == "CARRYING"
        and order.workerId and PNC.Registry
        and PNC.Registry.GetLiveZombie
    then
        body = PNC.Registry.GetLiveZombie(order.workerId)
        if body and body.getX and body.getY and body.getZ then
            for radius = 0, 2 do
                for dx = -radius, radius do
                    for dy = -radius, radius do
                        addPoint(points, pointSeen,
                            math.floor(body:getX()) + dx,
                            math.floor(body:getY()) + dy, body:getZ())
                    end
                end
            end
        end
    end
    for _, point in ipairs(points) do
        addSquareCandidates(candidates, seen, point.x, point.y, point.z)
    end
    return candidates
end

local function tokenOwner(token, baseId, orderId)
    if not token or tostring(token) == "" then return nil end
    local owner = Internal.workOrderForToken(token, baseId)
    if owner and tostring(owner.id or "") ~= tostring(orderId or "") then
        return owner
    end
    local runtimeTask = Service.Runtime.byToken[tostring(token)]
    if runtimeTask and tostring(runtimeTask) ~= tostring(orderId or "") then
        return { id = runtimeTask }
    end
    return nil
end

local function candidateScore(candidate, order, task)
    local payload = order and order.payload or {}
    local score = 0
    local phase = tostring(order and order.phase or "")
    if task and task.corpse == candidate.corpse then score = score + 250 end
    if same(candidate.carriedBy, order and order.id) then score = score + 220 end
    if same(candidate.taskId, order and order.id) then score = score + 150 end
    if same(candidate.deathMarkerId, payload.deathMarkerId
        or payload.corpseId)
    then score = score + 100 end
    if same(candidate.token, payload.haulToken) then score = score + 80 end
    if phase ~= "CARRYING" and pointMatches(candidate, payload.sourceX,
        payload.sourceY, payload.sourceZ)
    then score = score + 20 end
    return score
end

local function chooseCandidate(candidates, order, task)
    local payload = order and order.payload or {}
    local expectedToken = payload.haulToken
    local best
    local bestScore = 0
    for _, candidate in ipairs(candidates or {}) do
        local score = candidateScore(candidate, order, task)
        local conflict = same(candidate.token, expectedToken)
            and tokenOwner(candidate.token, order.baseId, order.id)
        if conflict and not same(candidate.taskId, order.id)
            and not same(candidate.carriedBy, order.id)
        then
            score = 0
        end
        if score > bestScore then best, bestScore = candidate, score end
    end
    return best, bestScore
end

local function stampReservation(candidate, order)
    local corpse = candidate and candidate.corpse
    local data = corpse and corpse.getModData and corpse:getModData() or nil
    local payload = order and order.payload
    local changed = false
    local token = candidate and candidate.token
        or payload and payload.haulToken
    if not corpse or not data or not payload then return false end
    if tokenOwner(token, order.baseId, order.id) then
        data.PNC_CorpseHaulToken = nil
        Internal.transmit(corpse)
        token = Service.GetCorpseToken(corpse, true)
        changed = true
    elseif not token or tostring(token) == "" then
        token = Service.GetCorpseToken(corpse, true)
        changed = true
    end
    if token and tostring(payload.haulToken or "") ~= tostring(token) then
        payload.haulToken = tostring(token)
        changed = true
    end
    if token and tostring(data.PNC_CorpseHaulToken or "")
        ~= tostring(token)
    then
        data.PNC_CorpseHaulToken = tostring(token)
        changed = true
    end
    if tostring(data.PNC_CorpseHaulTaskId or "")
        ~= tostring(order.id or "")
    then
        data.PNC_CorpseHaulTaskId = order.id
        changed = true
    end
    if candidate.deathMarkerId
        and tostring(payload.deathMarkerId or payload.corpseId or "")
            ~= tostring(candidate.deathMarkerId)
    then
        payload.deathMarkerId = candidate.deathMarkerId
        payload.corpseId = nil
        changed = true
    elseif not candidate.deathMarkerId
        and (payload.deathMarkerId or payload.corpseId)
    then
        payload.deathMarkerId = nil
        payload.corpseId = nil
        changed = true
    end
    if changed then Internal.transmit(corpse) end
    return changed
end

local function rebindOrder(order, candidate, task, now)
    local payload = order and order.payload
    local phase = tostring(order and order.phase or "")
    local changed = stampReservation(candidate, order)
    if payload and candidate then
        candidate.token = payload.haulToken
        candidate.taskId = order.id
    end
    if not payload then return changed end
    if phase == "CARRYING" or task and task.carrying
        or same(candidate.carriedBy, order.id)
    then
        if tonumber(payload.carryX) ~= tonumber(candidate.x)
            or tonumber(payload.carryY) ~= tonumber(candidate.y)
            or tonumber(payload.carryZ) ~= tonumber(candidate.z)
        then
            payload.carryX, payload.carryY, payload.carryZ = candidate.x,
                candidate.y, candidate.z
            if task then
                task.carryX, task.carryY, task.carryZ = candidate.x,
                    candidate.y, candidate.z
            end
            changed = true
        end
    elseif tonumber(payload.sourceX) ~= tonumber(candidate.x)
        or tonumber(payload.sourceY) ~= tonumber(candidate.y)
        or tonumber(payload.sourceZ) ~= tonumber(candidate.z)
    then
        payload.sourceX, payload.sourceY, payload.sourceZ = candidate.x,
            candidate.y, candidate.z
        payload.interactionX, payload.interactionY, payload.interactionZ =
            candidate.x, candidate.y, candidate.z
        changed = true
    end
    if changed then
        order.corpseReconcileAt = now
        order.corpseReconcileReason = "REBOUND"
        order.corpseReconcileMissingAt = nil
        order.updatedAt = now
        order.revision = (tonumber(order.revision) or 0) + 1
        if WorkRepository and WorkRepository.MarkDirty then
            WorkRepository.MarkDirty()
        end
    elseif order.corpseReconcileMissingAt then
        order.corpseReconcileMissingAt = nil
        if WorkRepository and WorkRepository.MarkDirty then
            WorkRepository.MarkDirty()
        end
    end
    return changed
end

local function removeDuplicateCorpses(candidates, canonical, order)
    local removed = 0
    local marker = canonical and canonical.deathMarkerId
    local token = canonical and canonical.token
    local originalToken = canonical and (canonical.originalToken or token)
    if not canonical or not Lifecycle or not Lifecycle.Internal
        or not Lifecycle.Internal.removeCorpse
    then return removed end
    for _, candidate in ipairs(candidates or {}) do
        local duplicate = candidate ~= canonical
            and ((marker and same(candidate.deathMarkerId, marker))
                or (token and same(candidate.token, token))
                or (originalToken and same(candidate.token, originalToken)))
        if duplicate and (same(candidate.taskId, order.id)
            or same(candidate.deathMarkerId, marker)
            or same(candidate.token, token)
            or same(candidate.token, originalToken))
        then
            if Lifecycle.Internal.removeCorpse(candidate.corpse) then
                removed = removed + 1
            end
        end
    end
    return removed
end

local function clearReservationMarkers(order, candidates)
    local payload = order and order.payload or {}
    local orderId = tostring(order and order.id or "")
    local token = payload and payload.haulToken
    local marker = payload and (payload.deathMarkerId or payload.corpseId)
    local changed = false
    for _, candidate in ipairs(candidates or {}) do
        local data = candidate.corpse and candidate.corpse.getModData
            and candidate.corpse:getModData() or nil
        local owns = data and (same(data.PNC_CorpseHaulTaskId, orderId)
            or same(data.PNC_CorpseHaulCarriedBy, orderId)
            or same(candidate.token, token)
            or same(candidate.deathMarkerId, marker))
        if owns and data then
            local corpseChanged = false
            if same(data.PNC_CorpseHaulTaskId, orderId) then
                data.PNC_CorpseHaulTaskId = nil
                corpseChanged = true
            end
            if same(data.PNC_CorpseHaulCarriedBy, orderId) then
                data.PNC_CorpseHaulCarriedBy = nil
                corpseChanged = true
            end
            if same(data.PNC_CorpseHaulToken, token) then
                data.PNC_CorpseHaulToken = nil
                corpseChanged = true
            end
            if corpseChanged then
                changed = true
                Internal.transmit(candidate.corpse)
            end
        end
    end
    return changed
end

Internal.sameCorpseValue = same
Internal.corpsePointMatches = pointMatches
Internal.corpseCandidatesForOrder = candidatesForOrder
Internal.chooseCorpseCandidate = chooseCandidate
Internal.rebindCorpseOrder = rebindOrder
Internal.removeDuplicateCorpses = removeDuplicateCorpses
Internal.clearCorpseReservationMarkers = clearReservationMarkers

return Service

