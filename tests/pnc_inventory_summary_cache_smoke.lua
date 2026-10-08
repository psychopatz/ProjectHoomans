local T = require "tests/support/test"

local LUA_ROOT = T.path("ProjectHoomans", "shared", "")
T.addPackagePaths()

local FILE = LUA_ROOT
    .. "PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_Payloads.lua"

local ensureCalls = 0
local encumbranceCalls = 0

local function copy(value, seen)
    local result
    local key
    local item
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    result = {}
    seen[value] = result
    for key, item in pairs(value) do
        result[copy(key, seen)] = copy(item, seen)
    end
    return result
end

PNC = {
    Const = { GENERATOR_VERSION = 1 },
    Core = { DeepCopy = copy },
    Inventory = {
        Internal = {
            countMapEntries = function(values)
                local count = 0
                for _ in pairs(values or {}) do count = count + 1 end
                return count
            end,
        },
        EnsureRecordInventory = function(record)
            ensureCalls = ensureCalls + 1
            return record.inventory
        end,
        GetEncumbranceState = function()
            encumbranceCalls = encumbranceCalls + 1
            return {
                ratio = 0,
                level = "normal",
            }
        end,
    },
}

T.load(FILE)

local record = {
    id = "npc_cache",
    inventoryTemplateRef = "template-a",
    inventory = {
        revision = 7,
        cachedWeight = 2,
        maxWeight = 10,
        remainingWeight = 8,
        itemCount = 2,
        containerCount = 1,
        signature = "7:2:20",
    },
    runtime = {
        inventorySummaryCacheKey = "7|template-a",
        inventorySummaryCache = {
            revision = 7,
            itemCount = 2,
        },
    },
}

local cached = PNC.Inventory.BuildSummaryPayload(record)
T.equal(cached.revision, 7, "cached summary returned")
T.equal(ensureCalls, 0, "cache hit did not re-enter inventory hydration")
T.equal(encumbranceCalls, 0, "cache hit did not recalculate encumbrance")
T.truthy(cached ~= record.runtime.inventorySummaryCache,
    "cached summary is copied for callers")

record.inventory.revision = 8
local rebuilt = PNC.Inventory.BuildSummaryPayload(record)
T.equal(ensureCalls, 1, "revision change re-entered inventory hydration")
T.equal(encumbranceCalls, 1, "revision change rebuilt the summary")
T.equal(rebuilt.revision, 8, "rebuilt summary uses current inventory revision")

record.inventory.revision = 9
record.runtime.inventorySummaryCacheKey = "9|template-a"
record.runtime.inventorySummaryCache = {
    revision = 9,
    itemCount = 2,
}
record.persistedInventory = { pending = true }
PNC.Inventory.BuildSummaryPayload(record)
T.equal(ensureCalls, 2,
    "pending persisted inventory was not bypassed by the read cache")

T.finish("pnc_inventory_summary_cache_smoke")
