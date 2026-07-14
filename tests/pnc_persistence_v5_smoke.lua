local ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

local tables = {}
ModData = {
    getOrCreate = function(key)
        tables[key] = tables[key] or {}
        return tables[key]
    end,
    get = function(key) return tables[key] end,
    add = function() error("Registry must update ModData tables in place") end,
    remove = function(key)
        local old = tables[key]
        tables[key] = nil
        return old
    end,
    getTableNames = function()
        local names = {}
        for key, _ in pairs(tables) do names[#names + 1] = key end
        return names
    end,
}

-- Project Zomboid's Kahlua environment does not expose Lua's global next().
-- Keep it absent for the complete persistence/registry smoke path.
next = nil

GlobalModData = { save = function() end }
Events = {
    OnInitGlobalModData = { Add = function() end },
    OnSave = { Add = function() end },
}

PNC = {
    Const = {
        MODDATA_KEY = "PNC_Core_Global",
        MODDATA_NPC_PREFIX = "PNC_NPC_",
        PERSISTENCE_VERSION = 5,
        STORAGE_LAYOUT_VERSION = 2,
    },
    Core = {
        IsAuthority = function() return true end,
        Now = function() return 1000 end,
        TableSize = function(value)
            local count = 0
            for _, _ in pairs(value or {}) do count = count + 1 end
            return count
        end,
        LogInfo = function() end,
        LogWarn = function() end,
    },
    Persistence = {
        SerializeRecord = function(record)
            return {
                schemaVersion = 5,
                recordRevision = record.recordRevision,
                id = record.id,
                persistedInventory = record.persistedInventory,
            }
        end,
        DeserializeRecord = function(raw, fallbackID)
            if raw.invalid then return nil end
            return {
                id = tostring(raw.id or fallbackID),
                recordRevision = tonumber(raw.recordRevision) or 0,
                persist = raw.persist ~= false,
                persistedInventory = raw.persistedInventory,
                runtime = {},
            }
        end,
    },
}

dofile(ROOT .. "Registry/PNC_Registry.lua")

PNC.Registry.Load()
for i = 1, 500 do
    PNC.Registry.AddRecord({
        id = "npc_" .. tostring(i),
        recordRevision = 0,
        persist = true,
        persistedInventory = { revision = 0, summary = { revision = 0 } },
        runtime = {},
    })
end

assertEqual(PNC.Registry.FlushDirty(), 500, "initial dirty flush")
assertEqual(PNC.Core.TableSize(tables.PNC_Core_Global.records), 500, "directory pointer count")
assertEqual(tables.PNC_Core_Global.NPCs, nil, "directory contains no record bodies")
assert(tables.PNC_NPC_npc_1 and tables.PNC_NPC_npc_500, "per-NPC tables missing")

PNC.Registry.MarkDirty("npc_10", "health")
PNC.Registry.MarkDirty("npc_20", "inventory")
PNC.Registry.MarkDirty("npc_30", "position")
assertEqual(PNC.Registry.FlushDirty(), 3, "incremental dirty flush")
assertEqual(PNC.Registry.Get("npc_10").inventory, nil, "inventory hydrated unexpectedly")

PNC.Registry.RemoveRecord("npc_20")
assertEqual(tables.PNC_Core_Global.records.npc_20, nil, "pointer not removed")
assertEqual(tables.PNC_NPC_npc_20, nil, "per-NPC table not removed")

tables = {
    PNC_Core_Global = {
        Version = 4,
        NPCs = {
            old_a = { id = "old_a", recordRevision = 2 },
            old_b = { id = "old_b", recordRevision = 3 },
        },
    },
}
PNC.Registry.Loaded = false
PNC.Registry.Load()
assertEqual(PNC.Core.TableSize(PNC.Registry.Data), 2, "legacy migration record count")
assert(tables.PNC_Core_Global.NPCs, "legacy bodies removed before per-NPC records were written")
assertEqual(PNC.Registry.FlushDirty(), 2, "legacy migration flush count")
assertEqual(tables.PNC_Core_Global.NPCs, nil, "legacy bodies retained after migration commit")
assert(tables.PNC_NPC_old_a and tables.PNC_NPC_old_b, "legacy per-NPC tables missing")

tables = {
    PNC_Core_Global = {
        Version = 4,
        layoutVersion = 2,
        NPCs = {
            retry_a = { id = "retry_a", recordRevision = 1 },
            retry_b = { id = "retry_b", recordRevision = 1, invalid = true },
        },
    },
}
PNC.Registry.Loaded = false
PNC.Registry.Load()
assertEqual(PNC.Core.TableSize(PNC.Registry.Data), 1, "partial migration valid record count")
assertEqual(PNC.Registry.FlushDirty(), 1, "partial migration flush count")
assert(tables.PNC_Core_Global.NPCs, "partial migration removed legacy fallback")
tables.PNC_Core_Global.NPCs.retry_b.invalid = nil
PNC.Registry.Loaded = false
PNC.Registry.Load()
assertEqual(PNC.Core.TableSize(PNC.Registry.Data), 2, "partial migration retry record count")
assertEqual(PNC.Registry.FlushDirty(), 2, "partial migration retry flush count")
assertEqual(tables.PNC_Core_Global.NPCs, nil, "retried migration did not commit")

local retryRecord = PNC.Registry.Get("retry_a")
local originalSerialize = PNC.Persistence.SerializeRecord
PNC.Persistence.SerializeRecord = function(record)
    if record.id == "retry_a" then error("intentional serialization failure") end
    return originalSerialize(record)
end
PNC.Registry.MarkDirty(retryRecord, "failure_test")
assertEqual(PNC.Registry.FlushDirty(), 0, "failed serialization counted as flushed")
assert(PNC.Registry.DirtyByID.retry_a, "failed serialization was removed from dirty set")
PNC.Persistence.SerializeRecord = originalSerialize
assertEqual(PNC.Registry.FlushDirty(), 1, "retained dirty record did not retry")

tables.PNC_NPC_orphan = { id = "orphan", recordRevision = 7 }
PNC.Registry.Loaded = false
PNC.Registry.Load()
assert(PNC.Registry.Get("orphan"), "valid orphan was not recovered")
assertEqual(tables.PNC_Core_Global.records.orphan.storageKey, "PNC_NPC_orphan", "orphan pointer")

print("pnc_persistence_v5_smoke: ok")
