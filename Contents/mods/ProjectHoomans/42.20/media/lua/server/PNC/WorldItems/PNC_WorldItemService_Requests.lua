-- Request creation, throttling, and claim management for world-item intents.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorldItemService = PNC.WorldItemService or {}

local Service = PNC.WorldItemService
local Context = PNC.WorldItemContext
local Claims = Context.Claims

Service.ActiveByNPC = Service.ActiveByNPC or {}
Service.NextIntentId = tonumber(Service.NextIntentId) or 1
Service.CooldownsByNPC = Service.CooldownsByNPC or {}

local PRIORITY = { wounded_no_bandage = 4, bandage_provision = 3, companion_scavenge = 2, food_scavenge = 1 }
local function nowMs() return PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0 end

local function cooldownsFor(npcId)
    local id = tostring(npcId or "")
    Service.CooldownsByNPC[id] = Service.CooldownsByNPC[id] or {}
    return Service.CooldownsByNPC[id]
end

local function hasScissors(record)
    for _, item in pairs(record and record.inventory and record.inventory.items or {}) do
        if type(item) == "table" and (tonumber(item.stack) or 1) > 0 then
            local t = tostring(item.type or "")
            if t == "Base.Scissors" or string.find(t, "Scissors", 1, true) ~= nil then return true end
        end
    end
    return false
end

local function hasCarryRoom(record)
    local enc = PNC.Inventory and PNC.Inventory.GetEncumbranceState
        and PNC.Inventory.GetEncumbranceState(record) or nil
    if not enc then return true end
    local maxW = tonumber(enc.maxWeight) or 0
    return maxW > 0 and (tonumber(enc.usedWeight) or 0) < maxW * 1.15
end

local function notifyTasking(npcId, eventType, source)
    if PNC.Tasking and PNC.Tasking.Commands and PNC.Tasking.Commands.ReevaluateNow then
        PNC.Tasking.Commands.ReevaluateNow({
            id = "wi_ev_" .. tostring(npcId) .. "_" .. tostring(nowMs()),
            type = eventType, npcId = tostring(npcId), source = source or "WorldItemService",
        })
    end
end

function Service.GetActiveIntent(npcId) return Service.ActiveByNPC[tostring(npcId or "")] end

function Service.ClearIntent(npcId, reason)
    npcId = tostring(npcId or "")
    local existing = Service.ActiveByNPC[npcId]
    if existing then
        if existing.candidate and existing.candidate.claimKey then
            Claims.Release(existing.candidate.claimKey, npcId)
        end
        Service.ActiveByNPC[npcId] = nil
    end
    Claims.ReleaseForNPC(npcId)
    if reason and PNC.Tasking and PNC.Tasking.Commands and PNC.Tasking.Commands.CancelForNPC then
        local lease = PNC.TaskLeaseService and PNC.TaskLeaseService.ForNPC
            and PNC.TaskLeaseService.ForNPC(npcId) or nil
        if lease and lease.sourceDomain == "world_item" then
            PNC.Tasking.Commands.CancelForNPC(npcId, reason)
        end
    end
    return existing ~= nil
end

Service.CancelForNPC = Service.ClearIntent

function Service.RequestIntent(record, spec, options)
    if not record or record.alive == false then return false, "npc_missing" end
    options = type(options) == "table" and options or {}
    local npcId = tostring(record.id or "")
    if npcId == "" then return false, "npc_id_missing" end
    local now = tonumber(options.now) or nowMs()
    if spec.action == "grab" and not hasCarryRoom(record) then return false, "no_carry_capacity" end

    local existing = Service.ActiveByNPC[npcId]
    if existing then
        if (PRIORITY[existing.purpose] or 0) >= (PRIORITY[spec.purpose] or 0) then
            return true, "already_queued", existing
        end
        Service.ClearIntent(npcId, "SUPERSEDED_WORLD_ITEM")
    end

    local cdMap, cdKey = cooldownsFor(npcId), tostring(spec.purpose or spec.action)
    if options.force ~= true and now < (tonumber(cdMap[cdKey]) or 0) then return false, "scan_cooldown" end
    cdMap[cdKey] = now + (tonumber(options.cooldownMs) or 3000)

    local cand, findReason = Context.FindBestCandidate(record, {
        cell = options.cell, x = options.x or record.x, y = options.y or record.y, z = options.z or record.z,
        radius = spec.radius, filter = spec.filter, sourceTypes = spec.sourceTypes,
        allowRestrictedZones = options.allowRestrictedZones == true, allowTheft = options.allowTheft == true,
        hasScissors = hasScissors(record), earlyExit = options.earlyExit ~= false,
    })
    if not cand then return false, findReason or "no_matching_item" end
    if spec.maxLeashDist and spec.ownerX and spec.ownerY then
        local dx, dy = cand.x + 0.5 - spec.ownerX, cand.y + 0.5 - spec.ownerY
        if dx * dx + dy * dy > spec.maxLeashDist * spec.maxLeashDist then
            return false, "outside_owner_leash"
        end
    end
    if not Claims.Claim(cand.claimKey, npcId, now) then return false, "claim_conflict" end

    local intentId = "wi:" .. tostring(Service.NextIntentId)
    Service.NextIntentId = Service.NextIntentId + 1
    local intent = {
        id = intentId, npcId = npcId, action = spec.action, purpose = spec.purpose,
        precedence = spec.precedence, urgency = spec.urgency, filter = spec.filter,
        sourceTypes = spec.sourceTypes,
        allowRestrictedZones = options.allowRestrictedZones == true or options.allowTheft == true,
        targetCount = math.max(1, math.floor(tonumber(options.targetCount) or 1)),
        collectedCount = 0, urgent = options.urgent == true, radius = spec.radius,
        ownerKey = spec.ownerKey, ownerX = spec.ownerX, ownerY = spec.ownerY, ownerZ = spec.ownerZ,
        maxLeashDist = spec.maxLeashDist, candidate = cand, phase = "READY",
        createdAt = now, updatedAt = now, revision = 1,
    }
    Service.ActiveByNPC[npcId] = intent
    notifyTasking(npcId, "WORLD_ITEM_QUEUED", spec.purpose)
    return true, "queued", intent
end

function Service.RequestBandageRip(record, options)
    options = type(options) == "table" and options or {}
    local urgent = options.urgent == true
    return Service.RequestIntent(record, {
        action = "rip_bandage", purpose = urgent and "wounded_no_bandage" or "bandage_provision",
        precedence = urgent and "CRITICAL_NEED" or "NORMAL_NEED", urgency = urgent and 0.92 or 0.72,
        radius = tonumber(options.radius) or (urgent and 12 or 10),
        filter = { mode = "rip_bandage" },
        sourceTypes = options.sourceTypes or { corpses = true, containers = true, floorItems = true },
    }, options)
end

function Service.RequestFoodScavenge(record, options)
    options = type(options) == "table" and options or {}
    return Service.RequestIntent(record, {
        action = "grab", purpose = "food_scavenge",
        precedence = options.urgent == true and "NORMAL_NEED" or "OPTIONAL",
        urgency = options.urgent == true and 0.78 or 0.55,
        radius = tonumber(options.radius) or 10,
        filter = { categories = { food = true }, excludeUnsafe = true },
        sourceTypes = options.sourceTypes or { containers = true, floorItems = true, corpses = false },
    }, options)
end

return Service
