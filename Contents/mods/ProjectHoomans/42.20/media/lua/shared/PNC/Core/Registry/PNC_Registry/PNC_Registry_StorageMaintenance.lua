-- One-shot persistence maintenance for the per-NPC ModData namespace.
-- This is intentionally not a recovery path: it is used only after the
-- canonical directory version has been rejected and the old namespace must
-- not be rediscovered as if it were current data.

local Registry = PNC.Registry
local Internal = Registry.Internal
local Const = PNC.Const

local function forEachTableName(callback)
    local names = ModData and ModData.getTableNames
        and ModData.getTableNames() or nil
    if not names or type(callback) ~= "function" then return end
    if names.size and names.get then
        for index = 0, names:size() - 1 do
            callback(tostring(names:get(index)))
        end
        return
    end
    for _, name in pairs(names) do callback(tostring(name)) end
end

function Internal.ForEachTableName(callback)
    forEachTableName(callback)
end

function Internal.ClearPersistedNPCNamespace()
    local prefix = tostring(Const.MODDATA_NPC_PREFIX or "PNC_NPC_")
    local removed = 0
    forEachTableName(function(key)
        if string.sub(key, 1, #prefix) == prefix
            and ModData and ModData.remove
        then
            ModData.remove(key)
            removed = removed + 1
        end
    end)
    return removed
end

function Internal.ClearUnreferencedPersistedNPCRecords(directory)
    local prefix = tostring(Const.MODDATA_NPC_PREFIX or "PNC_NPC_")
    local referenced = {}
    local removed = 0
    for _, entry in pairs(directory and directory.records or {}) do
        if type(entry) == "table" and entry.storageKey then
            referenced[tostring(entry.storageKey)] = true
        end
    end
    forEachTableName(function(key)
        if string.sub(key, 1, #prefix) == prefix
            and not referenced[key]
            and ModData and ModData.remove
        then
            ModData.remove(key)
            removed = removed + 1
        end
    end)
    return removed
end

return Internal
