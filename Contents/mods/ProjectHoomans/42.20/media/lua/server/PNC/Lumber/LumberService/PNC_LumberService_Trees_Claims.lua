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
            allowed = square:isFree(true) ~= false
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
Internal.ExpireClaims = expireClaims
Internal.EnsureTreeClaim = ensureTreeClaim
Internal.SelectClaimedTarget = selectClaimedTarget
Internal.SelectTargetDistance = distanceSq
