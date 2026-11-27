-- Staggered, CPU-budgeted, zero-ModData spatial scanner for opportunistic looting.
-- Prevents NPCs from fighting over the same target (transient claim table) and
-- skips already-empty containers (transient cache).

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

require "PNC/Scavenge/PNC_WorldLoot_Policy"

PNC = PNC or {}
PNC.WorldLoot = PNC.WorldLoot or {}

local WorldLoot = PNC.WorldLoot

local DEFAULT_SCAN_RADIUS = 5
local DEFAULT_SCAN_COOLDOWN_MS = 4500
local DEFAULT_CLAIM_TTL_MS = 12000
local MAX_SCANS_PER_TICK = 2
local DEFAULT_ROOT_CAPACITY = 10.0
local MAX_AI_LOOT_ITEMS = 12

-- Transient runtime state (never persisted to ModData)
local claimedTargets = {}
local emptyContainers = {}
local lastScanByNpc = {}
local tickScanState = { stamp = -1, count = 0 }

function WorldLoot.ResetScannerRuntime()
    claimedTargets = {}
    emptyContainers = {}
    lastScanByNpc = {}
    tickScanState = { stamp = -1, count = 0 }
end

local function readMethod(obj, method)
    if type(obj) ~= "table" and type(obj) ~= "userdata" then return nil end
    local fn = obj[method]
    if type(fn) ~= "function" then return nil end
    local ok, val = pcall(fn, obj)
    return ok and val or nil
end

local function itemWeight(item)
    local w = tonumber(readMethod(item, "getActualWeight")
        or readMethod(item, "getWeight")
        or (type(item) == "table" and (item.actualWeight or item.weight)))
    return math.max(0.05, w or 0.5)
end

local function itemFullType(item)
    return tostring(readMethod(item, "getFullType")
        or (type(item) == "table" and item.fullType) or "")
end

-- Computes remaining carry weight & slot headroom from unified PNC.Inventory + backpack.
function WorldLoot.GetRemainingCapacity(record)
    if type(record) ~= "table" then return 0, 0 end
    local inv = type(record.inventory) == "table" and record.inventory or nil
    local maxWeight = DEFAULT_ROOT_CAPACITY
    local usedWeight = 0
    local itemCount = 0

    if inv then
        if tonumber(inv.rootMaxWeight) and tonumber(inv.rootMaxWeight) > 0 then
            maxWeight = tonumber(inv.rootMaxWeight)
        end
        if type(inv.containers) == "table" then
            local totalCap = 0
            for _, c in pairs(inv.containers) do
                if type(c) == "table" and tonumber(c.maxWeight) and tonumber(c.maxWeight) > 0 then
                    totalCap = totalCap + tonumber(c.maxWeight)
                end
            end
            if totalCap > 0 then maxWeight = totalCap end
        end
        if type(inv.items) == "table" then
            for _, it in pairs(inv.items) do
                if type(it) == "table" then
                    itemCount = itemCount + 1
                    usedWeight = usedWeight + math.max(0.05, tonumber(it.weight) or 0.5)
                end
            end
        end
    end

    -- Include equipped backpack capacity if not already accounted for in inv.containers
    local back = record.equipment and record.equipment.back or nil
    if type(back) == "table" and tonumber(back.capacity) and tonumber(back.capacity) > 0 then
        if not (inv and inv.containers and inv.containers.back) then
            maxWeight = maxWeight + tonumber(back.capacity)
        end
    end

    -- Soft ModData descriptor cap for non-colonists
    local isColonist = record.recruited == true or record.ownerId ~= nil or record.ownerKey ~= nil
    if not isColonist and itemCount >= MAX_AI_LOOT_ITEMS then
        return 0, itemCount
    end
    return math.max(0, maxWeight - usedWeight), itemCount
end

function WorldLoot.IsTargetClaimedByOther(targetKey, npcId, nowMs)
    local entry = claimedTargets[targetKey]
    if not entry then return false end
    if (tonumber(nowMs) or 0) >= (tonumber(entry.expiresAt) or 0) then
        claimedTargets[targetKey] = nil
        return false
    end
    return tostring(entry.npcId) ~= tostring(npcId)
end

function WorldLoot.ClaimTarget(targetKey, npcId, nowMs, ttlMs)
    if not targetKey or not npcId then return false end
    if WorldLoot.IsTargetClaimedByOther(targetKey, npcId, nowMs) then
        return false
    end
    claimedTargets[targetKey] = {
        npcId = tostring(npcId),
        expiresAt = (tonumber(nowMs) or 0) + (tonumber(ttlMs) or DEFAULT_CLAIM_TTL_MS),
    }
    return true
end

function WorldLoot.ReleaseClaim(targetKey, npcId)
    local entry = claimedTargets[targetKey]
    if entry and (npcId == nil or tostring(entry.npcId) == tostring(npcId)) then
        claimedTargets[targetKey] = nil
    end
end

local function iterateJavaList(list, fn)
    if not list then return end
    if type(list) == "table" then
        for i = 1, #list do
            if fn(list[i], i) == true then return end
        end
        return
    end
    local size = readMethod(list, "size")
    if type(size) == "number" and size > 0 then
        for i = 0, size - 1 do
            local ok, elem = pcall(list.get, list, i)
            if ok and elem and fn(elem, i + 1) == true then return end
        end
    end
end

-- Scans nearby loaded tiles within opportunistic radius for the closest valid item.
function WorldLoot.ScanNearbyTarget(record, nowMs, opts)
    if type(record) ~= "table" or record.alive == false then return nil end
    opts = type(opts) == "table" and opts or {}
    nowMs = tonumber(nowMs) or (PNC.Core and PNC.Core.Now and PNC.Core.Now()) or 0

    local npcId = tostring(record.id or "")
    local policy = opts.policy or WorldLoot.ResolvePolicy(record, opts.ownerPlayer)
    if not policy or policy.enabled ~= true then return nil, "policy_disabled" end

    local remCap = WorldLoot.GetRemainingCapacity(record)
    if remCap <= 0.1 then return nil, "inventory_full" end

    -- Per-NPC scan cooldown & global per-tick budget
    local cooldown = tonumber(opts.cooldownMs) or DEFAULT_SCAN_COOLDOWN_MS
    if not opts.bypassCooldown and lastScanByNpc[npcId]
        and (nowMs - lastScanByNpc[npcId]) < cooldown
    then
        return nil, "cooldown"
    end
    local tickStamp = math.floor(nowMs / 50)
    if tickScanState.stamp ~= tickStamp then
        tickScanState.stamp = tickStamp
        tickScanState.count = 0
    end
    if not opts.bypassBudget and tickScanState.count >= MAX_SCANS_PER_TICK then
        return nil, "tick_budget"
    end
    tickScanState.count = tickScanState.count + 1
    lastScanByNpc[npcId] = nowMs

    local cell = opts.cell or (getCell and getCell()) or nil
    if not cell or type(cell.getGridSquare) ~= "function" then return nil, "no_cell" end

    local rx = math.floor(tonumber(record.x) or 0)
    local ry = math.floor(tonumber(record.y) or 0)
    local rz = math.floor(tonumber(record.z) or 0)
    local radius = math.max(1, math.min(10, math.floor(tonumber(opts.radius) or DEFAULT_SCAN_RADIUS)))
    local prefs = policy.preferences or {}

    local best = nil
    local bestDistSq = math.huge

    local function consider(candidate)
        local dx = candidate.x - rx
        local dy = candidate.y - ry
        local dSq = dx * dx + dy * dy
        if dSq < bestDistSq then
            bestDistSq = dSq
            best = candidate
        end
    end

    for dx = -radius, radius do
        for dy = -radius, radius do
            if (dx * dx + dy * dy) <= (radius * radius) then
                local sx, sy = rx + dx, ry + dy
                local sq = cell:getGridSquare(sx, sy, rz)
                if sq and WorldLoot.CanLootAt(record, sx, sy, rz, policy) then
                    -- 1. Floor items
                    if prefs.floorItems ~= false then
                        iterateJavaList(readMethod(sq, "getWorldObjects"), function(wObj, idx)
                            local item = readMethod(wObj, "getItem") or (type(wObj) == "table" and wObj.item)
                            if item then
                                local okM, cat = WorldLoot.MatchesPolicy(item, policy)
                                local w = itemWeight(item)
                                local key = string.format("floor:%d:%d:%d:%d", sx, sy, rz, idx)
                                if okM and w <= remCap and not WorldLoot.IsTargetClaimedByOther(key, npcId, nowMs) then
                                    consider({
                                        kind = "floor",
                                        x = sx, y = sy, z = rz,
                                        item = item,
                                        worldObject = wObj,
                                        square = sq,
                                        fullType = itemFullType(item),
                                        category = cat,
                                        weight = w,
                                        targetKey = key,
                                    })
                                    return true
                                end
                            end
                        end)
                    end

                    -- 2. Containers (shelves, fridges, crates, counters)
                    if prefs.containers ~= false then
                        iterateJavaList(readMethod(sq, "getObjects"), function(obj, oIdx)
                            local cont = readMethod(obj, "getContainer") or (type(obj) == "table" and obj.container)
                            if cont then
                                local cKey = string.format("cont:%d:%d:%d:%d", sx, sy, rz, oIdx)
                                if not emptyContainers[cKey] then
                                    local foundAny = false
                                    iterateJavaList(readMethod(cont, "getItems"), function(item, iIdx)
                                        foundAny = true
                                        local okM, cat = WorldLoot.MatchesPolicy(item, policy)
                                        local w = itemWeight(item)
                                        local key = cKey .. ":" .. tostring(iIdx)
                                        if okM and w <= remCap and not WorldLoot.IsTargetClaimedByOther(key, npcId, nowMs) then
                                            consider({
                                                kind = "container",
                                                x = sx, y = sy, z = rz,
                                                item = item,
                                                container = cont,
                                                square = sq,
                                                fullType = itemFullType(item),
                                                category = cat,
                                                weight = w,
                                                targetKey = key,
                                                containerKey = cKey,
                                            })
                                            return true
                                        end
                                    end)
                                    if not foundAny then
                                        emptyContainers[cKey] = nowMs
                                    end
                                end
                            end
                        end)
                    end

                    -- 3. Corpses
                    if prefs.corpses ~= false then
                        iterateJavaList(readMethod(sq, "getDeadBodys"), function(corpse, cIdx)
                            local cont = readMethod(corpse, "getContainer") or (type(corpse) == "table" and corpse.container)
                            if cont then
                                local cKey = string.format("corpse:%d:%d:%d:%d", sx, sy, rz, cIdx)
                                iterateJavaList(readMethod(cont, "getItems"), function(item, iIdx)
                                    local okM, cat = WorldLoot.MatchesPolicy(item, policy)
                                    local w = itemWeight(item)
                                    local key = cKey .. ":" .. tostring(iIdx)
                                    if okM and w <= remCap and not WorldLoot.IsTargetClaimedByOther(key, npcId, nowMs) then
                                        consider({
                                            kind = "corpse",
                                            x = sx, y = sy, z = rz,
                                            item = item,
                                            container = cont,
                                            square = sq,
                                            fullType = itemFullType(item),
                                            category = cat,
                                            weight = w,
                                            targetKey = key,
                                        })
                                        return true
                                    end
                                end)
                            end
                        end)
                    end
                end
            end
        end
    end

    if best then
        WorldLoot.ClaimTarget(best.targetKey, npcId, nowMs)
        if WorldLoot.IsAuditEnabled() then
            WorldLoot.Audit("target_claimed", {
                "npc=" .. npcId,
                "kind=" .. tostring(best.kind),
                "item=" .. tostring(best.fullType),
                "cat=" .. tostring(best.category),
                string.format("pos=%d,%d,%d", best.x, best.y, best.z),
                string.format("remCap=%.1f", remCap),
            })
        end
        return best
    end
    return nil, "no_target"
end

return WorldLoot
