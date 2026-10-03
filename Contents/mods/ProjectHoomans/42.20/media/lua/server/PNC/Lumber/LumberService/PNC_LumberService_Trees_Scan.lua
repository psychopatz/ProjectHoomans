if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.LumberService
local Internal = Service.Internal
local integer = Internal.Integer
local zoneContains = Internal.ZoneContains
local zoneBounds = Internal.ZoneBounds
local ensureZoneRuntime = Internal.EnsureZoneRuntime
local markDirty = Internal.MarkDirty
local now = Internal.Now

local treeSignature = Internal.TreeSignature
local treeHealth = Internal.TreeHealth
local treeYield = Internal.TreeYield
local reconcileAbstractTree = Internal.ReconcileAbstractTree

local function upsertTree(zone, x, y, z, tree)
    local key = tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)
    local signature = treeSignature(tree)
    local health = treeHealth(tree)
    local existing = Service.Data.trees[key]
    if not existing then
        existing = {
            key = key, x = x, y = y, z = z,
            signature = signature, maxWork = health,
            remainingWork = health, logYield = treeYield(tree),
            status = "DISCOVERED", revision = 1, discoveredAt = now(),
        }
        Service.Data.trees[key] = existing
    elseif existing.signature ~= signature
        and existing.status ~= "IN_PROGRESS"
    then
        existing.signature = signature
        existing.maxWork = health
        existing.remainingWork = health
        existing.logYield = treeYield(tree)
        existing.status = "DISCOVERED"
        existing.revision = (tonumber(existing.revision) or 0) + 1
    elseif existing.status == "DISCOVERED"
        and tonumber(existing.remainingWork) <= 0
    then
        existing.maxWork = health
        existing.remainingWork = health
    end
    ensureZoneRuntime(zone)
    if not zone.treeIndex[key] then
        zone.treeIndex[key] = true
        zone.treeKeys[#zone.treeKeys + 1] = key
    end
    return existing
end

local function advanceScan(zone)
    local scan = zone.scan
    local bounds = zoneBounds(zone)
    if not bounds then scan.complete = true; return end
    if scan.x < bounds.maxX then
        scan.x = scan.x + 1
        return
    end
    scan.x = bounds.minX
    if scan.y < bounds.maxY then
        scan.y = scan.y + 1
        return
    end
    scan.y = bounds.minY
    if scan.z < bounds.maxZ then
        scan.z = scan.z + 1
        return
    end
    scan.complete = true
end

function Service.ScanZone(zoneId, budget)
    local zone = Service.GetZone(zoneId)
    if not zone then return false, "zone_not_found" end
    ensureZoneRuntime(zone)
    budget = math.max(1, math.floor(tonumber(budget)
        or Service.SCAN_TILES_PER_PUMP))
    local scan = zone.scan
    if scan.phase == "RETRY_UNLOADED" then
        local unresolved = scan.unresolved
        local processed = 0
        while processed < budget and #unresolved > 0 do
            local index = math.min(scan.retryCursor, #unresolved)
            local entry = unresolved[index]
            local tree
            local square
            if type(entry) == "table" then
                tree, square = Service.GetTreeAt(entry.x, entry.y, entry.z)
            end
            scan.scannedTiles = scan.scannedTiles + 1
            if square then
                scan.loadedTiles = scan.loadedTiles + 1
                if tree then
                    local key = tostring(entry.x) .. ":"
                        .. tostring(entry.y) .. ":" .. tostring(entry.z)
                    local existing = Service.Data.trees[key]
                    if not reconcileAbstractTree(existing, tree, square) then
                        upsertTree(zone, entry.x, entry.y, entry.z, tree)
                    end
                end
                local key = tostring(entry.x) .. ":" .. tostring(entry.y)
                    .. ":" .. tostring(entry.z)
                scan.unresolvedSeen[key] = nil
                unresolved[index] = unresolved[#unresolved]
                unresolved[#unresolved] = nil
                scan.retryCursor = index > #unresolved and 1 or index
            else
                scan.retryCursor = index + 1
                if scan.retryCursor > #unresolved then
                    scan.retryCursor = 1
                end
            end
            processed = processed + 1
        end
        scan.complete = #unresolved <= 0
        if scan.complete then scan.phase = "COMPLETE" end
        if processed > 0 then markDirty() end
        return true, processed, scan.complete
    end
    local processed = 0
    while processed < budget and not scan.complete do
        local x, y, z = scan.x, scan.y, scan.z
        if zoneContains(zone, x, y, z) then
            local tree, square = Service.GetTreeAt(x, y, z)
            scan.scannedTiles = scan.scannedTiles + 1
            if square then
                scan.loadedTiles = scan.loadedTiles + 1
            else
                scan.unloadedTiles = scan.unloadedTiles + 1
                local key = tostring(x) .. ":" .. tostring(y) .. ":"
                    .. tostring(z)
                if not scan.unresolvedSeen[key] then
                    scan.unresolvedSeen[key] = true
                    scan.unresolved[#scan.unresolved + 1] = {
                        x = x, y = y, z = z,
                    }
                end
            end
            if tree then
                local key = tostring(x) .. ":" .. tostring(y) .. ":"
                    .. tostring(z)
                local existing = Service.Data.trees[key]
                if not reconcileAbstractTree(existing, tree, square) then
                    upsertTree(zone, x, y, z, tree)
                end
            end
        end
        processed = processed + 1
        advanceScan(zone)
    end
    if scan.complete then
        if #scan.unresolved > 0 then
            scan.complete = false
            scan.phase = "RETRY_UNLOADED"
            scan.retryCursor = 1
        else
            scan.phase = "COMPLETE"
        end
    end
    if processed > 0 then markDirty() end
    return true, processed, scan.complete
end

