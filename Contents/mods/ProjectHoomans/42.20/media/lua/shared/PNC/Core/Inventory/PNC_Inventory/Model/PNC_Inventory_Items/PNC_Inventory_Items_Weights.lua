local Inventory = PNC.Inventory
local Internal = Inventory.Internal

local function resolveContainerReduction(
    inv, owners, reductions, containerID, depth
)
    local cached = reductions[containerID]
    local owner
    local reduction
    if cached ~= nil then return cached end
    if depth > 12 then return 0 end
    owner = owners[containerID]
    if not owner then
        reductions[containerID] = 0
        return 0
    end
    if owner.wornSlot and inv.worn[owner.wornSlot] == owner.id then
        reduction = Internal.normalizeItemWeightReduction(
            owner.weightReduction
        )
    else
        reduction = resolveContainerReduction(
            inv,
            owners,
            reductions,
            owner.container or "root",
            depth + 1
        )
    end
    reductions[containerID] = reduction
    return reduction
end

local function mapContainerOwners(inv)
    local owners = {}
    local item
    for _, item in pairs(inv.items) do
        if item.bagContainer then owners[item.bagContainer] = item end
    end
    return owners
end

function Internal.calculateWeights(inv)
    local usedWeight = 0
    local maxWeight = tonumber(inv.rootMaxWeight)
        or tonumber(inv.maxWeight) or 0
    local owners = mapContainerOwners(inv)
    local reductions = { root = 0 }
    local item
    local itemWeight
    local reduction
    for _, item in pairs(inv.items) do
        itemWeight = Internal.getItemWeight(item.type)
            * math.max(1, tonumber(item.stack) or 1)
        reduction = resolveContainerReduction(
            inv,
            owners,
            reductions,
            item.container or "root",
            0
        )
        usedWeight = usedWeight + (itemWeight * (1 - reduction))
    end
    inv.cachedWeight = usedWeight
    inv.maxWeight = maxWeight
    return usedWeight, maxWeight
end

function Internal.getContainerRawWeight(inv, containerID)
    local container = inv and inv.containers
        and inv.containers[containerID] or nil
    local usedWeight = 0
    local item
    local i
    if not container then return nil end
    for i = 1, #(container.items or {}) do
        item = inv.items and inv.items[container.items[i]] or nil
        if item then
            usedWeight = usedWeight
                + (Internal.getItemWeight(item.type)
                    * math.max(1, tonumber(item.stack) or 1))
        end
    end
    return usedWeight
end

local function encumbranceLevel(ratio)
    if ratio >= 1.75 then
        return "severe", 0.40, 2.8, 0.20
    elseif ratio >= 1.50 then
        return "very_heavy", 0.55, 2.3, 0.40
    elseif ratio >= 1.25 then
        return "heavy", 0.75, 1.9, 0.65
    elseif ratio > 1.0 then
        return "encumbered", 0.90, 1.5, 0.85
    end
    return "normal", 1.0, 1.0, 1.0
end

function Inventory.GetEncumbranceState(record)
    local inv = Inventory.EnsureRecordInventory(record)
    local usedWeight
    local maxWeight
    local ratio
    local level
    local staminaMultiplier
    local drainMultiplier
    local recoveryMultiplier
    if not inv then return nil end
    usedWeight = tonumber(inv.cachedWeight) or 0
    maxWeight = math.max(1, tonumber(inv.maxWeight) or 1)
    ratio = usedWeight / maxWeight
    level, staminaMultiplier, drainMultiplier, recoveryMultiplier =
        encumbranceLevel(ratio)
    return {
        usedWeight = usedWeight,
        maxWeight = maxWeight,
        ratio = ratio,
        level = level,
        staminaMultiplier = staminaMultiplier,
        drainMultiplier = drainMultiplier,
        recoveryMultiplier = recoveryMultiplier,
        severe = ratio >= 1.75,
    }
end

function Internal.findItemByTemplateKey(inv, templateKey)
    local item
    if not inv or not templateKey then return nil end
    for _, item in pairs(inv.items or {}) do
        if item and (
            item.templateKey == templateKey
            or item.legacyTemplateKey == templateKey
        ) then
            return item
        end
    end
    return nil
end

function Inventory.RebuildCaches(record)
    local inv
    if not record or type(record.inventory) ~= "table" then return nil end
    inv = record.inventory
    inv.rootMaxWeight = Internal.buildBaseCarryWeight(record)
    Internal.ensureContainer(inv, "root", inv.rootMaxWeight)
    inv.containers.root.maxWeight = inv.rootMaxWeight
    Internal.calculateWeights(inv)
    inv.itemCount = Internal.countMapEntries(inv.items)
    inv.containerCount = Internal.countMapEntries(inv.containers)
    inv.remainingWeight = math.max(
        0,
        (tonumber(inv.maxWeight) or 0)
            - (tonumber(inv.cachedWeight) or 0)
    )
    inv.signature = table.concat({
        tostring(inv.revision or 0),
        tostring(inv.itemCount or 0),
        tostring(math.floor((tonumber(inv.cachedWeight) or 0) * 10)),
        tostring(record.equipment
            and record.equipment.primaryFullType or ""),
        tostring(record.equipment
            and record.equipment.secondaryFullType or ""),
    }, ":")
    -- The map is the gameplay projection; PsychopatzCore remains canonical.
    if Inventory.CoreBridge and Inventory.CoreBridge.refreshCanonical then
        Inventory.CoreBridge.refreshCanonical(record, inv)
    end
    return inv
end
