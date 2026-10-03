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
        local cell = engineGetCell()
        if cell then return cell end
    end
    if IsoWorld and IsoWorld.instance then
        return IsoWorld.instance.currentCell
    end
    return nil
end

function Service.GetSquare(x, y, z)
    local cell = getCell()
    if not cell or type(cell.getGridSquare) ~= "function" then return nil end
    return cell:getGridSquare(x, y, z)
end

function Service.GetTreeAt(x, y, z)
    local square = Service.GetSquare(x, y, z)
    if not square or type(square.getTree) ~= "function" then
        return nil, square
    end
    return square:getTree(), square
end

local function treeSignature(tree)
    local size = 0
    local yield = 0
    if tree and type(tree.getSize) == "function" then
        size = tonumber(tree:getSize()) or 0
    end
    if tree and type(tree.getLogYield) == "function" then
        yield = tonumber(tree:getLogYield()) or 0
    end
    return tostring(size) .. ":" .. tostring(yield)
end

local function treeHealth(tree)
    if tree and type(tree.getHealth) == "function" then
        local value = tonumber(tree:getHealth())
        if value then return math.max(1, value) end
    end
    return 100
end

local function treeYield(tree)
    if tree and type(tree.getLogYield) == "function" then
        local value = tonumber(tree:getLogYield())
        if value then return math.max(1, math.floor(value)) end
    end
    return 1
end

function Service.ApplyDeferredTreeRemoval(tree, effect)
    if not tree or type(effect) ~= "table" then
        return false, "TREE_EFFECT_INVALID"
    end
    if tostring(effect.state or "") == "APPLIED" then
        return true, "TREE_ALREADY_APPLIED"
    end
    local actual, square = Service.GetTreeAt(effect.x or tree.x,
        effect.y or tree.y, effect.z or tree.z)
    if not square then return false, "TREE_CHUNK_LOADING" end
    if not actual then
        -- The expected tree was removed by another authoritative action. The
        -- abstract reward has already crossed its work boundary, so this is
        -- an idempotent success rather than a second reward or a retry loop.
        effect.state = "APPLIED"
        effect.appliedAt = now()
        effect.updatedAt = effect.appliedAt
        effect.lastReason = "TREE_ALREADY_REMOVED"
        tree.worldReconciledAt = effect.appliedAt
        markDirty()
        return true, "TREE_ALREADY_REMOVED"
    end
    local expected = effect.signature or effect.identity
        and effect.identity.signature or tree.signature
    if tostring(expected or "") ~= tostring(treeSignature(actual)) then
        effect.state = "CONFLICT"
        effect.conflictReason = "TREE_REPLACED"
        effect.lastReason = "TREE_REPLACED"
        effect.updatedAt = now()
        tree.status = "INVALID"
        tree.invalidReason = "abstract_tree_replaced"
        markDirty()
        return false, "TREE_REPLACED"
    end
    if type(square.transmitRemoveItemFromSquare) ~= "function" then
        return false, "TREE_REMOVE_UNAVAILABLE"
    end
    local result = square:transmitRemoveItemFromSquare(actual)
    if result == -1 then return false, "TREE_REMOVE_REJECTED" end
    effect.state = "APPLIED"
    effect.appliedAt = now()
    effect.updatedAt = effect.appliedAt
    effect.lastReason = "TREE_REMOVED"
    tree.worldReconciledAt = effect.appliedAt
    markDirty()
    return true, "TREE_REMOVED"
end

local function reconcileAbstractTree(tree, actual, square)
    if not tree or tree.status ~= "DEPLETED"
        or tree.completedMode ~= "abstract" or not square
    then return false end
    if tree.worldEffect then
        return Service.ApplyDeferredTreeRemoval(tree, tree.worldEffect)
    end
    if not actual then return false end
    if tree.signature ~= treeSignature(actual) then
        tree.status = "INVALID"
        tree.invalidReason = "abstract_tree_replaced"
        markDirty()
        return false
    end
    if type(square.transmitRemoveItemFromSquare) ~= "function" then
        return false
    end
    local result = square:transmitRemoveItemFromSquare(actual)
    if result == -1 then return false end
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
    local key = tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)
    local ledgerTree = Service.Data and Service.Data.trees[key]
    if ledgerTree and ledgerTree.worldEffect then
        Service.ApplyDeferredTreeRemoval(ledgerTree,
            ledgerTree.worldEffect)
        return
    end
    if not tree then return end
    reconcileAbstractTree(ledgerTree, tree, square)
end


Internal.TreeSignature = treeSignature
Internal.TreeHealth = treeHealth
Internal.TreeYield = treeYield
Internal.ReconcileAbstractTree = reconcileAbstractTree
Internal.ReconcileLoadedSquare = reconcileLoadedSquare
Internal.ApplyDeferredTreeRemoval = Service.ApplyDeferredTreeRemoval
