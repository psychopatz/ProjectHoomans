-- Physical-world tree access, persistent ledger reconciliation, and claims.
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

local function getCell()
    local engineGetCell = _G and _G.getCell or nil
    if type(engineGetCell) == "function" then
        local ok, cell = pcall(engineGetCell)
        if ok and cell then return cell end
    end
    if IsoWorld and IsoWorld.instance then
        return IsoWorld.instance.currentCell
    end
    return nil
end

function Service.GetSquare(x, y, z)
    local cell = getCell()
    if not cell or type(cell.getGridSquare) ~= "function" then return nil end
    local ok, square = pcall(cell.getGridSquare, cell, x, y, z)
    return ok and square or nil
end

function Service.GetTreeAt(x, y, z)
    local square = Service.GetSquare(x, y, z)
    if not square or type(square.getTree) ~= "function" then
        return nil, square
    end
    local ok, tree = pcall(square.getTree, square)
    return ok and tree or nil, square
end

local function treeSignature(tree)
    local size = 0
    local yield = 0
    if tree and type(tree.getSize) == "function" then
        local ok, value = pcall(tree.getSize, tree)
        if ok then size = tonumber(value) or 0 end
    end
    if tree and type(tree.getLogYield) == "function" then
        local ok, value = pcall(tree.getLogYield, tree)
        if ok then yield = tonumber(value) or 0 end
    end
    return tostring(size) .. ":" .. tostring(yield)
end

local function treeHealth(tree)
    if tree and type(tree.getHealth) == "function" then
        local ok, value = pcall(tree.getHealth, tree)
        if ok and tonumber(value) then return math.max(1, tonumber(value)) end
    end
    return 100
end

local function treeYield(tree)
    if tree and type(tree.getLogYield) == "function" then
        local ok, value = pcall(tree.getLogYield, tree)
        if ok and tonumber(value) then return math.max(1, math.floor(value)) end
    end
    return 1
end

local function reconcileAbstractTree(tree, actual, square)
    if not tree or tree.status ~= "DEPLETED"
        or tree.completedMode ~= "abstract" or not actual or not square
    then return false end
    if tree.signature ~= treeSignature(actual) then
        tree.status = "INVALID"
        tree.invalidReason = "abstract_tree_replaced"
        markDirty()
        return false
    end
    if type(square.transmitRemoveItemFromSquare) ~= "function" then
        return false
    end
    local ok, result = pcall(square.transmitRemoveItemFromSquare,
        square, actual)
    if not ok or result == -1 then return false end
    tree.worldReconciledAt = now()
    markDirty()
    return true
end

local function reconcileLoadedSquare(square)
    if not square then return end
    local x = square.getX and square:getX() or square.x
    local y = square.getY and square:getY() or square.y
    local z = square.getZ and square:getZ() or square.z or 0
    if x == nil or y == nil then return end
    local tree = square.getTree and square:getTree() or nil
    if not tree then return end
    local key = tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)
    reconcileAbstractTree(Service.Data and Service.Data.trees[key],
        tree, square)
end

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

local function expireClaims(at)
    for key, claim in pairs(Service.Runtime.claims) do
        if at >= (tonumber(claim.expiresAt) or 0) then
            local tree = Service.Data.trees[key]
            if tree and tree.status ~= "DEPLETED"
                and tree.status ~= "INVALID"
            then tree.status = "DISCOVERED" end
            Service.Runtime.claims[key] = nil
            markDirty()
        end
    end
end

function Service.ClaimTree(treeKey, npcId, at)
    local key = tostring(treeKey or "")
    local tree = Service.GetTree(key)
    npcId = tostring(npcId or "")
    at = tonumber(at) or now()
    if not tree or tree.status == "DEPLETED" or tree.status == "INVALID" then
        return false, "tree_unavailable"
    end
    local current = Service.Runtime.claims[key]
    if current and at < (tonumber(current.expiresAt) or 0)
        and tostring(current.npcId) ~= npcId
    then return false, "tree_claimed" end
    Service.Runtime.claims[key] = {
        npcId = npcId, claimedAt = at,
        expiresAt = at + Service.CLAIM_TTL_MS,
    }
    tree.status = "IN_PROGRESS"
    tree.revision = (tonumber(tree.revision) or 0) + 1
    markDirty()
    return true, current and "claim_renewed" or "claimed"
end

function Service.RenewTreeClaim(treeKey, npcId, at)
    local claim = Service.Runtime.claims[tostring(treeKey or "")]
    if not claim or tostring(claim.npcId) ~= tostring(npcId or "") then
        return false, "claim_missing"
    end
    claim.expiresAt = (tonumber(at) or now()) + Service.CLAIM_TTL_MS
    return true
end

local function ensureTreeClaim(treeKey, npcId, at)
    local claim = Service.Runtime.claims[tostring(treeKey or "")]
    if claim and tostring(claim.npcId) == tostring(npcId or "")
        and (tonumber(at) or now()) < (tonumber(claim.expiresAt) or 0)
    then
        return Service.RenewTreeClaim(treeKey, npcId, at)
    end
    return Service.ClaimTree(treeKey, npcId, at)
end

local function selectClaimedTarget(npcId, at)
    for _ = 1, 4 do
        local tree = Service.SelectTarget(npcId)
        if not tree then return nil end
        if ensureTreeClaim(tree.key, npcId, at) then return tree end
    end
    return nil
end

function Service.ReleaseTree(treeKey, reason)
    local key = tostring(treeKey or "")
    if key == "" then return true end
    local tree = Service.GetTree(key)
    Service.Runtime.claims[key] = nil
    if tree and tree.status ~= "DEPLETED" and tree.status ~= "INVALID" then
        tree.status = "DISCOVERED"
        tree.revision = (tonumber(tree.revision) or 0) + 1
    end
    markDirty()
    return true, reason or "released"
end

function Service.CompleteTree(treeKey, mode)
    local tree = Service.GetTree(treeKey)
    if not tree then return false, "tree_not_found" end
    tree.remainingWork = 0
    tree.status = "DEPLETED"
    tree.completedMode = tostring(mode or "abstract")
    tree.completedAt = now()
    tree.revision = (tonumber(tree.revision) or 0) + 1
    Service.Runtime.claims[tostring(treeKey)] = nil
    markDirty()
    return true, "depleted"
end

local function distanceSq(record, x, y)
    local rx = tonumber(record and record.x) or 0
    local ry = tonumber(record and record.y) or 0
    local dx, dy = rx - x, ry - y
    return dx * dx + dy * dy
end

function Service.SelectTarget(npcId)
    local job = Service.GetJob(npcId)
    local zone = job and Service.GetZone(job.zoneId) or nil
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(tostring(npcId)) or nil
    if not job or not zone or zone.enabled ~= true or not record then
        return nil, "job_unavailable"
    end
    local selected
    local selectedDistance
    for index = 1, #(zone.treeKeys or {}) do
        local key = zone.treeKeys[index]
        local tree = Service.Data.trees[key]
        local claim = Service.Runtime.claims[key]
        local available = tree and tree.x ~= nil and tree.y ~= nil
            and tree.status ~= "DEPLETED"
            and tree.status ~= "INVALID"
            and (not claim or tostring(claim.npcId) == tostring(npcId))
        if available then
            local value = distanceSq(record, tree.x, tree.y)
            if not selected or value < selectedDistance
                or (value == selectedDistance and key < selected.key)
            then selected, selectedDistance = tree, value end
        end
    end
    if not selected then return nil, "no_tree_available" end
    return selected
end

local WORK_OFFSETS = {
    { x = -1, y = 0 }, { x = 1, y = 0 },
    { x = 0, y = -1 }, { x = 0, y = 1 },
}

function Service.FindApproach(tree, record)
    if not tree then return nil, "tree_missing" end
    local selected
    local selectedDistance
    for index = 1, #WORK_OFFSETS do
        local offset = WORK_OFFSETS[index]
        local x, y, z = tree.x + offset.x, tree.y + offset.y, tree.z
        local square = Service.GetSquare(x, y, z)
        local allowed = square ~= nil
        if allowed and type(square.isFree) == "function" then
            local ok, free = pcall(square.isFree, square, true)
            allowed = ok and free ~= false
        end
        -- Abstract NPCs can travel toward an unloaded approach tile. Live
        -- chopping will revalidate the square before applying a hit.
        if allowed or not square then
            local value = distanceSq(record, x, y)
            if not selected or value < selectedDistance then
                selected = { x = x + 0.5, y = y + 0.5, z = z }
                selectedDistance = value
            end
        end
    end
    return selected, selected and nil or "no_approach_point"
end


Internal.ReconcileLoadedSquare = reconcileLoadedSquare
Internal.ExpireClaims = expireClaims
Internal.EnsureTreeClaim = ensureTreeClaim
Internal.SelectClaimedTarget = selectClaimedTarget
Internal.TreeSignature = treeSignature

return Service
