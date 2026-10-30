-- Inventory record repository: compact snapshot interop without eager item hydration.
PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}
local Inventory = PNC.Inventory

-- Record-envelope interop remains lazy: an untouched current-version snapshot
-- can be saved without hydrating items. Older payloads promote through the
-- existing domain codec before the envelope version is advanced.
Inventory.Repository = Inventory.Repository or {}
local Repository = Inventory.Repository

function Repository.SerializeRecord(record)
    if record.inventory and Inventory.Serialize then
        return Inventory.Serialize(record)
    end
    if type(record.persistedInventory) ~= "table" then
        return nil
    end
    if tonumber(record.persistenceSourceVersion)
            and tonumber(record.persistenceSourceVersion)
                < tonumber(PNC.Const.PERSISTENCE_VERSION)
        and Inventory.EnsureRecordInventory
        and Inventory.Serialize
    then
        Inventory.EnsureRecordInventory(record)
        return Inventory.Serialize(record)
    end
    return PNC.Core.DeepCopy(record.persistedInventory)
end

function Repository.RestoreRecord(record, rawInventory)
    record.inventory = nil
    record.persistedInventory = type(rawInventory) == "table"
        and PNC.Core.DeepCopy(rawInventory) or nil
    return record
end

return Repository
