-- Candidate validation, approach tile resolution, and interaction animation for world items.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorldItemExecutor = PNC.WorldItemExecutor or {}
PNC.WorldItemExecutor.Internal = PNC.WorldItemExecutor.Internal or {}

local Executor = PNC.WorldItemExecutor
local Internal = Executor.Internal
local Zones = PNC.WorldItemContext.Zones
local Common = PNC.BehaviorCommon

local ACTION_SCENE = {
    rip_bandage = { id = "scavenge.rip", bump = "Making", durationMs = 1450 },
    corpse = { id = "scavenge.loot_low", bump = "LootLow", durationMs = 650 },
    floor = { id = "scavenge.loot_low", bump = "LootLow", durationMs = 650 },
    container = { id = "scavenge.loot", bump = "Loot", durationMs = 650 },
}

local function safeCall(obj, method, ...)
    if not obj or type(obj[method]) ~= "function" then return nil end
    local ok, value = pcall(obj[method], obj, ...)
    if not ok then return nil end
    return value
end

local function listContains(list, target)
    if not list or not target then return false end
    if type(list) == "table" and not list.size then
        for index = 1, #list do
            if list[index] == target then return true end
        end
        return false
    end
    if list.size and list.get then
        for index = 0, list:size() - 1 do
            if list:get(index) == target then return true end
        end
    end
    return false
end

function Internal.IsCandidateStillValid(intent)
    local cand = intent and intent.candidate or nil
    if not cand or not cand.item then return false, "candidate_missing" end
    if Zones and Zones.IsRestrictedSquare(cand.x, cand.y, cand.z, {
        allowRestrictedZones = intent.allowRestrictedZones == true,
    }) then
        return false, "restricted_zone"
    end
    if cand.sourceType == "curtain" then
        local objs = safeCall(cand.square, "getObjects")
        if objs and not listContains(objs, cand.object) then
            return false, "curtain_missing"
        end
        return cand.object ~= nil, cand.object ~= nil and nil or "curtain_missing"
    end
    if cand.sourceType == "floor" then
        local objs = safeCall(cand.square, "getWorldObjects")
        if objs and not listContains(objs, cand.worldObject) then
            return false, "floor_item_missing"
        end
        return true
    end
    if not cand.container then return false, "container_missing" end
    local items = safeCall(cand.container, "getItems")
    if items and not listContains(items, cand.item) then
        return false, "container_item_missing"
    end
    return true
end

function Internal.ApproachLocation(intent, record)
    local cand = intent and intent.candidate or nil
    if not cand then return nil, "candidate_missing" end
    if intent.approachTarget and not (intent.failedApproaches
        and intent.failedApproaches[intent.approachTarget.key])
    then
        return intent.approachTarget
    end
    local checker = PNC.PathService and PNC.PathService.IsSquareWalkable or nil
    local offsets = (cand.sourceType == "floor" or cand.sourceType == "corpse")
        and { { 0, 0 }, { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
        or { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }

    local best, bestDist
    for index = 1, #offsets do
        local tx = cand.x + offsets[index][1]
        local ty = cand.y + offsets[index][2]
        local key = tostring(tx) .. ":" .. tostring(ty) .. ":" .. tostring(cand.z)
        local walkable = not checker or checker(tx, ty, cand.z) == true
        if walkable and not (intent.failedApproaches and intent.failedApproaches[key]) then
            local dx = (tx + 0.5) - (tonumber(record.x) or (tx + 0.5))
            local dy = (ty + 0.5) - (tonumber(record.y) or (ty + 0.5))
            local distSq = dx * dx + dy * dy
            if not best or distSq < bestDist then
                best = { x = tx + 0.5, y = ty + 0.5, z = cand.z, key = key }
                bestDist = distSq
            end
        end
    end
    if not best then return nil, "approach_unreachable" end
    intent.approachTarget = best
    return best
end

function Internal.WithinInteractionRadius(record, body, cand)
    local px = body and body.getX and tonumber(body:getX()) or tonumber(record.x) or 0
    local py = body and body.getY and tonumber(body:getY()) or tonumber(record.y) or 0
    local pz = body and body.getZ and tonumber(body:getZ()) or tonumber(record.z) or 0
    if math.floor(pz) ~= math.floor(tonumber(cand.z) or 0) then return false end
    local dx = px - (cand.x + 0.5)
    local dy = py - (cand.y + 0.5)
    local radius = cand.sourceType == "container" and 1.85 or 1.35
    return dx * dx + dy * dy <= radius * radius
end

local function attachRipHandProp(intent, body, cand)
    if not body or not body.setPrimaryHandItem then return false end
    local fullType = (cand and cand.itemCtx and cand.itemCtx.fullType)
        or (cand and cand.item and safeCall(cand.item, "getFullType"))
        or "Base.RippedSheets"
    local prop = nil
    if type(instanceItem) == "function" then
        local ok, created = pcall(instanceItem, tostring(fullType))
        if ok and created then prop = created end
        if not prop then
            local okFallback, fallback = pcall(instanceItem, "Base.RippedSheets")
            if okFallback and fallback then prop = fallback end
        end
    end
    if not prop then return false end
    intent._savedHands = {
        primary = safeCall(body, "getPrimaryHandItem"),
        secondary = safeCall(body, "getSecondaryHandItem"),
    }
    pcall(body.setPrimaryHandItem, body, prop)
    if body.setSecondaryHandItem then
        pcall(body.setSecondaryHandItem, body, nil)
    end
    if body.resetEquippedHandsModels then
        pcall(body.resetEquippedHandsModels, body)
    end
    return true
end

function Internal.RestoreRipHandProp(intent, record, body)
    local saved = intent and intent._savedHands or nil
    if not saved then return false end
    intent._savedHands = nil
    if not body then return false end
    if body.setPrimaryHandItem then
        pcall(body.setPrimaryHandItem, body, saved.primary)
    end
    if body.setSecondaryHandItem then
        pcall(body.setSecondaryHandItem, body, saved.secondary)
    end
    if PNC.Equipment and type(PNC.Equipment.RefreshLiveHands) == "function" then
        pcall(PNC.Equipment.RefreshLiveHands, record, body)
    elseif body.resetEquippedHandsModels then
        pcall(body.resetEquippedHandsModels, body)
    end
    return true
end

function Internal.BeginInteract(intent, record, body, now)
    local cand = intent.candidate
    if Common and Common.HaltMovement then
        Common.HaltMovement(record, body, "world_item_interact")
    end
    if body then
        if cand.object and body.faceThisObject then
            pcall(body.faceThisObject, body, cand.object)
        elseif body.faceLocation then
            pcall(body.faceLocation, body, cand.x + 0.5, cand.y + 0.5)
        end
    end
    if intent.action == "rip_bandage" then
        attachRipHandProp(intent, body, cand)
    end
    local spec = intent.action == "rip_bandage" and ACTION_SCENE.rip_bandage
        or ACTION_SCENE[cand.sourceType] or ACTION_SCENE.container
    local scenes = PNC.AnimationScenes
    if scenes and scenes.Request then
        scenes.Request(record, body, spec.id, { reason = "world_item_" .. intent.action })
    elseif body and PNC.Animation and PNC.Animation.PlayBump then
        PNC.Animation.PlayBump(body, record, spec.bump, { leaseUntil = now + spec.durationMs })
    end
    intent.phase = "INTERACTING"
    intent.actionStartedAt = now
    intent.actionUntil = now + spec.durationMs
    intent.actionScene = spec.id
    record.activeBehavior = intent.action == "rip_bandage" and "RipClothing" or "ScavengeItem"
    record.runtime = record.runtime or {}
    record.runtime.worldItem = {
        action = intent.action,
        purpose = intent.purpose,
        phase = "INTERACTING",
        itemFullType = cand.itemCtx and cand.itemCtx.fullType or nil,
        sourceType = cand.sourceType,
    }
    if PNC.Tasking and PNC.Tasking.Commands and PNC.Tasking.Commands.SetPhase then
        PNC.Tasking.Commands.SetPhase(intent.npcId, "WORKING")
    end
end

return Executor
