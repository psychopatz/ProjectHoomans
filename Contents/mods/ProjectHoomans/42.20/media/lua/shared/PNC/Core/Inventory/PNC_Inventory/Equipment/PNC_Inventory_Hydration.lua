-- PNC inventory record hydration and normalization.

PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}

require "PNC/Core/Inventory/PNC_Inventory/Equipment/PNC_Inventory_HydrationItems"

local Inventory = PNC.Inventory
local Internal = Inventory.Internal

local function restorePersistedInventory(record, options)
    if type(record.inventory) == "table"
        or type(record.persistedInventory) ~= "table"
    then
        return false, nil
    end
    local persisted = record.persistedInventory
    local persistedTemplate = persisted.template
        or (tonumber(persisted[1]) == 2 and persisted[4])
    local persistedGenerator = persistedTemplate
        and tonumber(persistedTemplate.generatorVersion) or nil
    local currentGenerator = PNC.Const and tonumber(PNC.Const.GENERATOR_VERSION) or 1
    record.persistedInventory = nil
    local hydrated = Inventory.Deserialize(record, persisted, options)
    if persistedGenerator ~= currentGenerator and PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "inventory_rebase")
    end
    return true, hydrated
end

local function inventoryAuditEnabled()
    local diagnostics = PNC.PerformanceScalingDiagnostics
    return diagnostics
        and diagnostics.InventoryAuditEnabled == true
        and type(diagnostics.LogInventoryAudit) == "function"
end

local function logInventoryHydration(
    record,
    itemCountBefore,
    containerCountBefore,
    stateChanged,
    structureChanged,
    containerMembershipChanged,
    dirtyReason,
    dirtyMarked,
    waterReconciled
)
    local diagnostics = PNC.PerformanceScalingDiagnostics
    if not diagnostics
        or diagnostics.InventoryAuditEnabled ~= true
        or type(diagnostics.LogInventoryAudit) ~= "function"
        or not (stateChanged or structureChanged)
    then
        return false
    end
    local recordID = Internal.normalizeString(record.id) or "unknown"
    if #recordID > 64 then recordID = string.sub(recordID, 1, 64) end
    diagnostics.LogInventoryAudit("record_hydrated", {
        "npc=" .. recordID,
        "items_before=" .. tostring(itemCountBefore or 0),
        "items_after=" .. tostring(Internal.countMapEntries(record.inventory.items)),
        "containers_before=" .. tostring(containerCountBefore or 0),
        "containers_after=" .. tostring(Internal.countMapEntries(record.inventory.containers)),
        "state_changed=" .. tostring(stateChanged == true),
        "structure_changed=" .. tostring(structureChanged == true),
        "membership_changed=" .. tostring(containerMembershipChanged == true),
        "dirty_reason=" .. tostring(dirtyReason or "none"),
        "dirty_marked=" .. tostring(dirtyMarked == true),
        "equipment_sync=complete",
        "cache_rebuild=complete",
        "water_reconcile=" .. (waterReconciled and "complete" or "skipped"),
    })
    return true
end

local function finalizeRecordInventory(
    record,
    inv,
    generatorVersion,
    currentGenerator,
    options,
    stateChanged,
    structureChanged,
    auditEnabled,
    itemCountBefore,
    containerCountBefore,
    containerMembershipChanged
)
    local dirtyReason
    local dirtyMarked = false
    local waterReconciled = false
    local identityCard
    local identityCardChanged
    local factionDogTag
    local factionDogTagChanged
    Internal.normalizeLegacyBagSlot(inv)
    Internal.getRuntimeState(record)
    Internal.refreshNextItemSerial(record, inv)
    identityCard, identityCardChanged = Internal.ensureIdentityCard(
        record,
        inv
    )
    if identityCardChanged then
        structureChanged = true
    end
    if generatorVersion < 3 then
        inv.template = inv.template or {}
        inv.template.generatorVersion = currentGenerator
        structureChanged = true
    end
    if generatorVersion < 4 then
        factionDogTag, factionDogTagChanged =
            Internal.ensureFactionDogTag(record, inv)
        if factionDogTagChanged then
            structureChanged = true
        end
        inv.template = inv.template or {}
        inv.template.generatorVersion = currentGenerator
        structureChanged = true
    end
    if stateChanged then
        dirtyReason = "inventory_state_normalized"
    elseif structureChanged then
        dirtyReason = "inventory_structure_normalized"
    end
    if dirtyReason and PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, dirtyReason)
        dirtyMarked = true
    end
    Inventory.SyncEquipmentFromInventory(record)
    Inventory.RebuildCaches(record)
    if options.reconcileWaterContainer ~= false
        and Inventory.ReconcileWaterContainer
    then
        Inventory.ReconcileWaterContainer(record)
        waterReconciled = true
    end
    if auditEnabled then
        logInventoryHydration(
            record,
            itemCountBefore,
            containerCountBefore,
            stateChanged,
            structureChanged,
            containerMembershipChanged,
            dirtyReason,
            dirtyMarked,
            waterReconciled
        )
    end
    return record.inventory
end

function Inventory.EnsureRecordInventory(record, options)
    options = type(options) == "table" and options or {}
    if not record then return nil end
    local persistedHandled
    local persistedInventory
    persistedHandled, persistedInventory = restorePersistedInventory(record, options)
    if persistedHandled then return persistedInventory end
    if type(record.inventory) ~= "table"
        or not record.inventory.items
        or not record.inventory.containers
    then
        return Inventory.CreateFromTemplate(record, options)
    end
    local inv = record.inventory
    local structureChanged = false
    local rawItems
    local auditEnabled = inventoryAuditEnabled()
    local itemCountBefore
    local containerCountBefore
    local containerMembershipChanged
    local generatorVersion = inv.template
        and tonumber(inv.template.generatorVersion) or 0
    local currentGenerator = PNC.Const and tonumber(PNC.Const.GENERATOR_VERSION) or 1
    if type(inv.items) == "table" then
        rawItems = inv.items
    else
        rawItems = {}
        structureChanged = true
    end
    if auditEnabled then
        itemCountBefore = 0
        if type(inv.containers) == "table" then
            containerCountBefore = Internal.countMapEntries(inv.containers)
        else
            containerCountBefore = 0
        end
    end
    inv.revision = math.max(0, math.floor(tonumber(inv.revision) or 0))
    inv.cachedWeight = tonumber(inv.cachedWeight) or 0
    inv.rootMaxWeight = Internal.buildBaseCarryWeight(record)
    inv.maxWeight = tonumber(inv.maxWeight) or inv.rootMaxWeight
    if type(inv.equipped) ~= "table" then
        inv.equipped = {
            primary = nil, secondary = nil, bag = nil,
            waterContainer = nil,
        }
        structureChanged = true
    end
    if type(inv.worn) ~= "table" then
        inv.worn = {}
        structureChanged = true
    end
    if type(inv.attached) ~= "table" then
        inv.attached = {}
        structureChanged = true
    end
    local stateChanged
    local itemsChanged
    stateChanged, itemsChanged, itemCountBefore =
        Internal.normalizeHydrationItems(inv, rawItems, auditEnabled)
    if itemsChanged then structureChanged = true end
    containerMembershipChanged = Internal.rebuildContainerMembership(inv)
    if containerMembershipChanged then
        structureChanged = true
    end
    return finalizeRecordInventory(
        record,
        inv,
        generatorVersion,
        currentGenerator,
        options,
        stateChanged,
        structureChanged,
        auditEnabled,
        itemCountBefore,
        containerCountBefore,
        containerMembershipChanged
    )
end

function Inventory.GetWeightState(record)
    local inv = Inventory.EnsureRecordInventory(record)
    local encumbrance = inv and Inventory.GetEncumbranceState(record) or nil
    return inv and {
        usedWeight = tonumber(inv.cachedWeight) or 0,
        maxWeight = tonumber(inv.maxWeight) or 0,
        remainingWeight = tonumber(inv.remainingWeight)
            or math.max(0, (tonumber(inv.maxWeight) or 0) - (tonumber(inv.cachedWeight) or 0)),
        ratio = encumbrance and encumbrance.ratio or 0,
        level = encumbrance and encumbrance.level or "normal",
    } or nil
end
