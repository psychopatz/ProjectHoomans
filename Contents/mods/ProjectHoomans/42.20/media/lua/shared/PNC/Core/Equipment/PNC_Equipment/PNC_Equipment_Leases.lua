-- Primary-slot ownership and priority arbitration.
--
-- Inventory remains the authority for item identity and mutation. This
-- module only owns the short-lived intent that decides which subsystem may
-- control the primary slot at a given moment.

PNC = PNC or {}
PNC.Equipment = PNC.Equipment or {}
PNC.Equipment.Internal = PNC.Equipment.Internal or {}

local Equipment = PNC.Equipment
local Inventory = PNC.Inventory

Equipment.LEASE_PRIORITY = Equipment.LEASE_PRIORITY or {
    IDLE = 0,
    WORK = 50,
    COMBAT = 100,
    EMERGENCY = 200,
}

local function runtimeFor(record)
    if not record then return nil end
    record.runtime = record.runtime or {}
    local state = record.runtime.equipmentLeaseState
    if type(state) ~= "table" then
        state = {
            entries = {}, activeOwner = nil, baseCaptured = false,
            baseItemID = nil, baseWeaponMode = nil, revision = 0,
        }
        record.runtime.equipmentLeaseState = state
    end
    state.entries = type(state.entries) == "table" and state.entries or {}
    return state
end

local function inventoryFor(record)
    if not record or not Inventory
        or type(Inventory.EnsureRecordInventory) ~= "function"
    then return nil end
    return Inventory.EnsureRecordInventory(record)
end

local function itemExists(inventory, itemID)
    return itemID == nil
        or type(inventory) == "table"
        and type(inventory.items) == "table"
        and inventory.items[itemID] ~= nil
end

local function priorityFor(value)
    if type(value) == "number" then return value end
    local key = string.upper(tostring(value or "WORK"))
    return tonumber(Equipment.LEASE_PRIORITY[key])
        or Equipment.LEASE_PRIORITY.WORK
end

local function currentPrimary(inventory)
    return inventory and inventory.equipped
        and inventory.equipped.primary or nil
end

local function applyPrimary(record, itemID, reason)
    if not Inventory or type(Inventory.EquipPrimary) ~= "function" then
        return false, "primary_equip_unavailable"
    end
    return Inventory.EquipPrimary(record, itemID, reason)
end

local function candidateWins(candidateOwner, candidate, winnerOwner, winner)
    if not winner then return true end
    if candidate.priority ~= winner.priority then
        return candidate.priority > winner.priority
    end
    return tostring(candidateOwner) < tostring(winnerOwner)
end

local function highestEntry(state, inventory)
    local winnerOwner
    local winner
    for owner, entry in pairs(state.entries or {}) do
        if type(entry) == "table"
            and itemExists(inventory, entry.itemID)
            and candidateWins(owner, entry, winnerOwner, winner)
        then
            winnerOwner, winner = owner, entry
        end
    end
    return winnerOwner, winner
end

local function bump(state)
    state.revision = (tonumber(state.revision) or 0) + 1
end

function Equipment.GetPrimaryLease(record, owner)
    local state = runtimeFor(record)
    local entry = state and state.entries[tostring(owner or "")] or nil
    if type(entry) ~= "table" then return nil end
    return {
        owner = entry.owner, itemID = entry.itemID,
        priority = entry.priority,
        active = state.activeOwner == entry.owner,
        reason = entry.reason,
    }
end

function Equipment.GetActivePrimaryLease(record)
    local state = runtimeFor(record)
    return state and Equipment.GetPrimaryLease(record, state.activeOwner) or nil
end

function Equipment.AcquirePrimaryLease(record, owner, itemID, options)
    options = type(options) == "table" and options or {}
    owner = tostring(owner or "")
    if owner == "" then return false, "primary_lease_owner_required" end
    local state = runtimeFor(record)
    local inventory = inventoryFor(record)
    if not state or not inventory then return false, "inventory_unavailable" end
    if not itemExists(inventory, itemID) then
        return false, "primary_item_not_found"
    end

    local requestedPriority = priorityFor(options.priority)
    local activeOwner = state.activeOwner
    local active = activeOwner and state.entries[activeOwner] or nil
    if activeOwner and activeOwner ~= owner and type(active) == "table"
        and active.priority > requestedPriority
    then
        return false, "primary_lease_higher_priority"
    end
    if activeOwner and activeOwner ~= owner and type(active) == "table"
        and active.priority == requestedPriority
        and options.replaceEqual ~= true
    then
        return false, "primary_lease_equal_priority"
    end

    local existing = state.entries[owner]
    local previousPrimary = currentPrimary(inventory)
    if not existing and not activeOwner and state.baseCaptured ~= true then
        state.baseCaptured = true
        state.baseItemID = previousPrimary
        state.baseWeaponMode = record.weaponMode
    end

    if previousPrimary ~= itemID then
        local equipped, reason = applyPrimary(record, itemID,
            options.reason or ("lease:" .. owner))
        if not equipped then
            if not existing and not activeOwner then
                state.baseCaptured = false
                state.baseItemID = nil
                state.baseWeaponMode = nil
            end
            return false, reason or "primary_equip_failed"
        end
    end

    state.entries[owner] = {
        owner = owner, itemID = itemID,
        priority = requestedPriority,
        reason = tostring(options.reason or ""),
    }
    state.activeOwner = owner
    bump(state)
    record.runtime.equipmentDescribeCache = nil
    return true, previousPrimary == itemID and "primary_lease_unchanged"
        or "primary_lease_acquired"
end

function Equipment.ReleasePrimaryLease(record, owner, options)
    options = type(options) == "table" and options or {}
    owner = tostring(owner or "")
    local state = runtimeFor(record)
    local inventory = inventoryFor(record)
    if not state or not inventory then return false, "inventory_unavailable" end
    local entry = state.entries[owner]
    if not entry then return true, "primary_lease_already_released" end

    local wasActive = state.activeOwner == owner
    state.entries[owner] = nil
    if not wasActive then
        bump(state)
        return true, "primary_lease_released"
    end

    local nextOwner, nextEntry = highestEntry(state, inventory)
    local targetID = nextEntry and nextEntry.itemID or nil
    local restoreBase = not nextEntry and options.restore ~= false
    if restoreBase and state.baseCaptured then targetID = state.baseItemID end

    local current = currentPrimary(inventory)
    if current ~= targetID then
        local equipped, reason = applyPrimary(record, targetID,
            options.reason or ("release:" .. owner))
        if not equipped then
            state.entries[owner] = entry
            state.activeOwner = owner
            return false, reason or "primary_restore_failed"
        end
    end

    state.activeOwner = nextOwner
    if not nextOwner and restoreBase then
        record.weaponMode = state.baseWeaponMode
        state.baseCaptured = false
        state.baseItemID = nil
        state.baseWeaponMode = nil
    end
    bump(state)
    record.runtime.equipmentDescribeCache = nil
    return true, nextOwner and "primary_lease_reactivated"
        or "primary_lease_released"
end

function Equipment.ReleaseCombatLease(record, zombie, reason)
    local hadLease = Equipment.GetPrimaryLease(record, "combat") ~= nil
    local released, releaseReason = Equipment.ReleasePrimaryLease(
        record, "combat", { reason = reason or "combat_ended" })
    if released and hadLease and zombie and Equipment.ApplyCombatState then
        -- ReleasePrimaryLease has already selected and equipped the highest
        -- remaining lease. Re-apply the normal presentation lane so a work
        -- lease (fishing, lumber, etc.) is restored as a held tool rather
        -- than being rendered as combat state.
        Equipment.ApplyCombatState(zombie, record, false, true)
    end
    return released, releaseReason
end

function Equipment.DescribePrimaryLeases(record)
    local state = runtimeFor(record)
    local output = {
        activeOwner = state and state.activeOwner or nil,
        revision = state and state.revision or 0, entries = {},
    }
    for owner, entry in pairs(state and state.entries or {}) do
        output.entries[owner] = {
            itemID = entry.itemID, priority = entry.priority,
            active = owner == output.activeOwner, reason = entry.reason,
        }
    end
    return output
end

return Equipment
