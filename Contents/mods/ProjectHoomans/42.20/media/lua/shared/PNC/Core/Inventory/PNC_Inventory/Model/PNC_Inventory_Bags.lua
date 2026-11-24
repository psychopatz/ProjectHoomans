-- Equipped-container detection and smart auto-packing into worn/held bags.
PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}
PNC.Inventory.Internal = PNC.Inventory.Internal or {}

local Inventory = PNC.Inventory
local Internal = Inventory.Internal

local function isEquippedHandBag(inv, item)
    if not inv or not item or not item.bagContainer then return false end
    local slot = item.equipSlot
    if slot ~= "primary" and slot ~= "secondary" then return false end
    return inv.equipped and inv.equipped[slot] == item.id or false
end

local function isWornBag(inv, item)
    if not inv or not item or not item.bagContainer then return false end
    return item.wornSlot ~= nil
        and inv.worn ~= nil
        and inv.worn[item.wornSlot] == item.id
end

function Internal.isItemEquippedContainer(inv, item)
    return isWornBag(inv, item) or isEquippedHandBag(inv, item)
end

function Internal.isHandHeldContainer(inv, item)
    return isEquippedHandBag(inv, item)
end

function Internal.getEquippedContainers(inv)
    local output = {}
    if type(inv) ~= "table" or type(inv.items) ~= "table" then
        return output
    end
    for _, item in pairs(inv.items) do
        if type(item) == "table" and Internal.isItemEquippedContainer(inv, item) then
            local container = inv.containers and inv.containers[item.bagContainer]
            local maxWeight = math.max(
                0,
                tonumber(container and container.maxWeight)
                    or tonumber(item.maxWeight) or 0
            )
            if container and maxWeight > 0 then
                local rawWeight = Internal.getContainerRawWeight(
                    inv, item.bagContainer
                ) or 0
                output[#output + 1] = {
                    item = item,
                    containerID = item.bagContainer,
                    maxWeight = maxWeight,
                    rawWeight = rawWeight,
                    freeWeight = math.max(0, maxWeight - rawWeight),
                    weightReduction = Internal.normalizeItemWeightReduction(
                        item.weightReduction
                    ),
                    worn = isWornBag(inv, item),
                }
            end
        end
    end
    table.sort(output, function(a, b)
        if a.weightReduction ~= b.weightReduction then
            return a.weightReduction > b.weightReduction
        end
        if a.maxWeight ~= b.maxWeight then
            return a.maxWeight > b.maxWeight
        end
        return tostring(a.item.id or "") < tostring(b.item.id or "")
    end)
    return output
end

function Internal.getEquippedBagTotals(inv)
    local bags = Internal.getEquippedContainers(inv)
    local totalCapacity = 0
    local totalUsed = 0
    for i = 1, #bags do
        totalCapacity = totalCapacity + bags[i].maxWeight
        totalUsed = totalUsed + bags[i].rawWeight
    end
    return totalCapacity, totalUsed, #bags
end

local function isPackableIntoEquippedBag(spec)
    if type(spec) ~= "table" then return false end
    if spec.wornSlot or spec.attachedSlot or spec.equipSlot then return false end
    if spec.interactionLocked == true then return false end
    if tonumber(spec.maxWeight) and tonumber(spec.maxWeight) > 0 then
        return false
    end
    local profile = Internal.getContainerProfile(spec.type)
    if profile and (tonumber(profile.capacity) or 0) > 0 then
        return false
    end
    return true
end

function Internal.planContainerPlacement(inv, specs, requestedContainerID, options)
    options = type(options) == "table" and options or {}
    local requested = Internal.normalizeString(requestedContainerID) or "auto"
    local autoRoute = options.forceRoot ~= true
        and (requested == "auto" or requested == "root")
    local equipped = autoRoute and Internal.getEquippedContainers(inv) or {}
    local remaining = {}
    for i = 1, #equipped do
        remaining[i] = equipped[i].freeWeight
    end
    local assignments = {}
    local effectiveAdded = 0
    local rawAdded = 0
    local explicitReduction = 0
    local explicitMax = 0
    local explicitUsed = 0
    if not autoRoute then
        local dest = inv.containers and inv.containers[requested] or nil
        if not dest then return nil, "container_not_found" end
        explicitUsed = Internal.getContainerRawWeight(inv, requested) or 0
        explicitMax = math.max(0, tonumber(dest.maxWeight) or 0)
        for _, candidate in pairs(inv.items or {}) do
            if candidate.bagContainer == requested then
                if Internal.isItemEquippedContainer(inv, candidate) then
                    explicitReduction = Internal.normalizeItemWeightReduction(
                        candidate.weightReduction
                    )
                end
                break
            end
        end
    end
    for index = 1, #(specs or {}) do
        local spec = specs[index]
        local fullType = type(spec) == "table"
            and Internal.normalizeString(spec.type) or nil
        if not fullType then return nil, "invalid_item_spec" end
        local weight = Internal.getItemWeight(fullType)
            * math.max(1, math.floor(tonumber(spec.stack) or 1))
        rawAdded = rawAdded + weight
        if not autoRoute then
            if explicitMax <= 0 or (explicitUsed + rawAdded) > explicitMax then
                return nil, "container_full"
            end
            assignments[index] = requested
            effectiveAdded = effectiveAdded + (weight * (1 - explicitReduction))
        else
            local chosen = "root"
            local chosenReduction = 0
            if isPackableIntoEquippedBag(spec) then
                for b = 1, #equipped do
                    if remaining[b] + 0.0001 >= weight then
                        chosen = equipped[b].containerID
                        chosenReduction = equipped[b].weightReduction
                        remaining[b] = math.max(0, remaining[b] - weight)
                        break
                    end
                end
            end
            assignments[index] = chosen
            effectiveAdded = effectiveAdded + (weight * (1 - chosenReduction))
        end
    end
    return {
        assignments = assignments,
        rawAddedWeight = rawAdded,
        effectiveAddedWeight = effectiveAdded,
    }
end

return Inventory
