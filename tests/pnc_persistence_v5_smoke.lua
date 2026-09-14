local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")

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
        MODDATA_NPC_PREFIX = "PNC_npc",
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

T.load(ROOT .. "Registry/PNC_Registry.lua")

PNC.Registry.Load()
for i = 1, 500 do
    PNC.Registry.AddRecord({
        id = "npc_" .. tostring(i),
        recordRevision = 0,
        persist = true,
        x = 0,
        y = 0,
        z = 0,
        stamina = { current = 100 },
        persistedInventory = { revision = 0, summary = { revision = 0 } },
        runtime = {},
    })
end

T.equal(PNC.Registry.FlushDirty(), 500, "initial dirty flush")
T.equal(PNC.Core.TableSize(tables.PNC_Core_Global.records), 500, "directory pointer count")
T.equal(tables.PNC_Core_Global.NPCs, nil, "directory contains no record bodies")
T.truthy(tables.PNC_npc_1 and tables.PNC_npc_500, "per-NPC tables missing")

PNC.Registry.LiveByID.npc_1 = {
    isDead = function() return false end,
    getX = function() return 4 end,
    getY = function() return 2 end,
    getZ = function() return 0 end,
}
PNC.Registry.RefreshLivePositions(false)
T.equal(PNC.Registry.DirtyByID.npc_1, nil,
    "continuous movement dirtied the record")
T.equal(PNC.Registry.FlushDirty(), 1,
    "save-time position snapshot was not persisted")
T.equal(PNC.Registry.DirtyByID.npc_1, nil,
    "position snapshot remained dirty after save")
PNC.Registry.LiveByID.npc_1 = nil

tables.PNC_npc_2.schemaVersion = 4
PNC.Registry.Loaded = false
PNC.Registry.Load()
T.equal(PNC.Registry.Data.npc_2, nil,
    "older per-NPC schema was not reset")
T.equal(tables.PNC_npc_2, nil,
    "reset per-NPC table was retained")
T.equal(tables.PNC_Core_Global.records.npc_2, nil,
    "reset per-NPC pointer was retained")
T.equal(PNC.Registry.FlushDirty(), 0,
    "per-NPC reset did not serialize a replacement record")

PNC.Registry.MarkDirty("npc_10", "health")
PNC.Registry.MarkDirty("npc_20", "inventory")
PNC.Registry.MarkDirty("npc_30", "position")
T.equal(PNC.Registry.FlushDirty(), 3, "incremental dirty flush")
T.equal(PNC.Registry.Get("npc_10").inventory, nil, "inventory hydrated unexpectedly")

PNC.Registry.RemoveRecord("npc_20")
T.equal(tables.PNC_Core_Global.records.npc_20, nil, "pointer not removed")
T.equal(tables.PNC_npc_20, nil, "per-NPC table not removed")

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
T.equal(PNC.Core.TableSize(PNC.Registry.Data), 0, "unsupported registry reset count")
T.equal(tables.PNC_Core_Global.NPCs, nil, "unsupported legacy bodies retained")
T.equal(PNC.Registry.FlushDirty(), 0, "unsupported registry reset flush count")
T.equal(tables.PNC_npc_old_a, nil, "unsupported NPC table retained")
T.equal(tables.PNC_npc_old_b, nil, "unsupported NPC table retained")

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
T.equal(PNC.Core.TableSize(PNC.Registry.Data), 0, "malformed registry reset count")
T.equal(PNC.Registry.FlushDirty(), 0, "malformed registry reset flush count")
T.equal(tables.PNC_Core_Global.NPCs, nil, "malformed legacy bodies retained")

local retryRecord = {
    id = "retry_a", recordRevision = 0, persist = true,
    x = 0, y = 0, z = 0, runtime = {},
}
T.truthy(PNC.Registry.AddRecord(retryRecord), "failure fixture record added")
T.equal(PNC.Registry.FlushDirty(), 1, "failure fixture record flushed")
local originalSerialize = PNC.Persistence.SerializeRecord
PNC.Persistence.SerializeRecord = function(record)
    if record.id == "retry_a" then error("intentional serialization failure") end
    return originalSerialize(record)
end
PNC.Registry.MarkDirty(retryRecord, "failure_test")
T.equal(PNC.Registry.FlushDirty(), 0, "failed serialization counted as flushed")
T.truthy(PNC.Registry.DirtyByID.retry_a, "failed serialization was removed from dirty set")
PNC.Persistence.SerializeRecord = originalSerialize
T.equal(PNC.Registry.FlushDirty(), 1, "retained dirty record did not retry")

tables.PNC_npc_orphan = { id = "orphan", recordRevision = 7 }
PNC.Registry.Loaded = false
PNC.Registry.Load()
T.equal(PNC.Registry.Get("orphan"), nil, "unreferenced record was recovered")
T.equal(tables.PNC_Core_Global.records.orphan, nil, "orphan pointer")
T.equal(tables.PNC_npc_orphan, nil, "unreferenced NPC table was retained")
T.finish("pnc_persistence_v5_smoke")

T.finish("pnc_persistence_v5_smoke")
