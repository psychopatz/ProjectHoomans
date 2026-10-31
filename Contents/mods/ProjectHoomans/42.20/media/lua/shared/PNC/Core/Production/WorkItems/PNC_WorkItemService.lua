-- Shared work-item capability and primary-slot orchestration.
--
-- Job modules register semantic validators. This service owns selection and
-- equipment intent, while Inventory remains authoritative for item state.

PNC = PNC or {}
PNC.WorkItemService = PNC.WorkItemService or {}

local Service = PNC.WorkItemService
local Validators = Service.Validators or {}
Service.Validators = Validators

local function operationKey(operation)
    return string.upper(tostring(operation or ""))
end

local function fullType(item)
    return tostring(item and (item.type or item.fullType) or "")
end

local function conditionUsable(item)
    return not item or item.cond == nil or tonumber(item.cond) == nil
        or tonumber(item.cond) > 0
end

local function itemID(item, id)
    if type(item) ~= "table" then return nil end
    item.id = item.id or id
    return item.id
end

local function candidateType(candidate)
    return tostring(candidate or "")
end

local function candidateAllowed(item, requirement, record, body)
    if type(item) ~= "table" or not conditionUsable(item) then
        return false, "item_broken"
    end
    local validator = Validators[tostring(requirement.validator or "")]
    if validator then
        local ok, valid, reason, details = pcall(
            validator, record, item, body, requirement)
        if not ok then return false, "validator_exception" end
        if valid ~= true then return false, reason or "validator_rejected" end
        return true, nil, details
    end
    return true
end

local function sortedItemIDs(items)
    local ids = {}
    for id in pairs(items or {}) do ids[#ids + 1] = id end
    table.sort(ids, function(left, right)
        return tostring(left) < tostring(right)
    end)
    return ids
end

local function findRequirementItem(record, body, requirement, cachedID)
    local inventory = record and record.inventory
    local items = inventory and inventory.items
    if type(items) ~= "table" then return nil, "inventory_items_missing" end
    local candidates = requirement.candidates or {}
    local candidateSet = {}
    for index = 1, #candidates do
        candidateSet[candidateType(candidates[index])] = index
    end

    local function inspect(id, item)
        local full = fullType(item)
        if candidateSet[full] == nil then return nil end
        local valid, reason, details = candidateAllowed(
            item, requirement, record, body)
        if not valid then return nil, reason end
        return {
            id = itemID(item, id), item = item, fullType = full,
            candidateIndex = candidateSet[full], details = details,
        }
    end

    local cached = cachedID and items[cachedID] or nil
    if cached then
        local selected = inspect(cachedID, cached)
        if selected then return selected end
    end

    local primaryID = inventory.equipped and inventory.equipped.primary
    local primary = primaryID and items[primaryID] or nil
    if primary then
        local selected = inspect(primaryID, primary)
        if selected then return selected end
    end

    local best
    for _, id in ipairs(sortedItemIDs(items)) do
        if id ~= cachedID and id ~= primaryID then
            local selected = inspect(id, items[id])
            if selected and (not best
                or selected.candidateIndex < best.candidateIndex
                or selected.candidateIndex == best.candidateIndex
                    and tostring(selected.id) < tostring(best.id))
            then
                best = selected
            end
        end
    end
    return best, best and nil or "no_valid_candidate"
end

function Service.RegisterValidator(id, validator)
    id = tostring(id or "")
    if id == "" or type(validator) ~= "function" then return false end
    Validators[id] = validator
    return true
end

function Service.Check(record, operation, body, preferredID)
    local key = operationKey(operation)
    local registry = PNC.JobRequirements
    local requirements = registry and registry.GetRequirements
        and registry.GetRequirements(key) or nil
    local report = {
        operation = key, ok = true, state = "READY", requirements = {},
        inventoryRevision = record and record.inventory
            and record.inventory.revision or nil,
    }
    if type(requirements) ~= "table" or #requirements == 0 then
        return report
    end

    local runtime = record and record.runtime or nil
    local cached = runtime and runtime.workItems
        and runtime.workItems[key] or nil
    local cachedID = preferredID or cached and cached.itemID or nil
    for index = 1, #requirements do
        local requirement = requirements[index]
        local selected, reason = findRequirementItem(
            record, body, requirement, cachedID)
        local row = {
            role = requirement.role, equipSlot = requirement.equipSlot,
            labelKey = requirement.labelKey,
            candidates = requirement.candidates,
            selected = selected and {
                itemID = selected.id, fullType = selected.fullType,
            } or nil, reason = reason,
        }
        report.requirements[index] = row
        if not selected then
            report.ok = false
            report.state = "WAITING_FOR_WORK_ITEM"
            report.reason = reason or "no_valid_candidate"
            report.role = requirement.role
            return report
        end
        if not report.primary and requirement.equipSlot == "primary" then
            report.primary = selected
        end
    end
    report.selected = report.primary
    return report
end

function Service.Ensure(record, operation, body, options)
    options = type(options) == "table" and options or {}
    local key = operationKey(operation)
    local report = Service.Check(record, key, body, options.itemID)
    if not report.ok then return false, report.reason, report end
    local primary = report.primary
    local owner = tostring(options.owner or ("work:" .. key))
    report.handReady = body == nil
    report.handReason = body == nil and "body_not_materialized" or nil
    if primary and PNC.Equipment
        and type(PNC.Equipment.AcquirePrimaryLease) == "function"
    then
        local acquired, reason = PNC.Equipment.AcquirePrimaryLease(
            record, owner, primary.id, {
                priority = options.priority or "WORK",
                reason = options.reason or ("work_item:" .. key),
            })
        if not acquired then
            report.ok = false
            report.state = "WAITING_FOR_WORK_ITEM"
            report.reason = reason or "primary_lease_unavailable"
            return false, report.reason, report
        end
        if body and options.applyHands ~= false
            and (PNC.Equipment.EnsureWorkHands
                or PNC.Equipment.EnsureCombatHands)
        then
            local ensureHands = PNC.Equipment.EnsureWorkHands
                or PNC.Equipment.EnsureCombatHands
            local handReady, handReason = ensureHands(body, record, {
                forceHeld = options.forceHeld ~= false,
                owner = owner,
            })
            report.handReady = handReady == true
            report.handReason = handReason
        end
    end
    record.runtime = record.runtime or {}
    record.runtime.workItems = record.runtime.workItems or {}
    local previous = record.runtime.workItems[key] or {}
    record.runtime.workItems[key] = {
        operation = key, owner = owner,
        itemID = primary and primary.id or nil,
        fullType = primary and primary.fullType or nil,
        inventoryRevision = report.inventoryRevision, state = "HELD",
        sourceStorageID = previous.sourceStorageID,
        sourceReservationID = previous.sourceReservationID,
        sourceItemIDs = previous.sourceItemIDs,
        sourceRecords = previous.sourceRecords,
        sourceBaseID = previous.sourceBaseID,
        returnPolicy = previous.returnPolicy,
        returnOrderID = previous.returnOrderID,
    }
    report.owner, report.state = owner, "HELD"
    return true, "work_item_ready", report
end

function Service.SetSource(record, operation, details)
    details = type(details) == "table" and details or {}
    local key = operationKey(operation)
    record.runtime = record.runtime or {}
    record.runtime.workItems = record.runtime.workItems or {}
    local lease = record.runtime.workItems[key]
        or { operation = key, owner = "work:" .. key, state = "HELD" }
    for field, value in pairs(details) do lease[field] = value end
    record.runtime.workItems[key] = lease
    return lease
end

function Service.GetLease(record, operation)
    local key = operationKey(operation)
    local runtime = record and record.runtime or nil
    return runtime and runtime.workItems and runtime.workItems[key] or nil
end

function Service.Release(record, operation, body, options)
    options = type(options) == "table" and options or {}
    local key = operationKey(operation)
    local owner = tostring(options.owner or ("work:" .. key))
    local runtime = record and record.runtime or nil
    local held = runtime and runtime.workItems
        and runtime.workItems[key] or nil
    local released, reason = true, "work_item_already_released"
    if PNC.Equipment
        and type(PNC.Equipment.ReleasePrimaryLease) == "function"
    then
        released, reason = PNC.Equipment.ReleasePrimaryLease(record, owner, {
            reason = options.reason or ("work_item_release:" .. key),
        })
    end
    if released and held and options.returnToStorage ~= false
        and type(Service.ReturnToStorage) == "function"
    then
        local returned, returnReason = Service.ReturnToStorage(
            record, key, held, options)
        if returned == false then return false, returnReason end
    end
    if released then
        if runtime and runtime.workItems then runtime.workItems[key] = nil end
        if body and PNC.Equipment and PNC.Equipment.ApplyCombatState then
            PNC.Equipment.ApplyCombatState(body, record, false, true)
        end
    end
    return released, reason
end

function Service.Status(record, operation)
    local key = operationKey(operation)
    local runtime = record and record.runtime or nil
    local held = runtime and runtime.workItems
        and runtime.workItems[key] or nil
    return held and PNC.Core and PNC.Core.DeepCopy
        and PNC.Core.DeepCopy(held) or held
end

return Service
