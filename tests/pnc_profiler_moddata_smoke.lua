local function equal(actual, expected, message)
    if actual ~= expected then
        error((message or "mismatch") .. ": expected=" .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

local function truthy(value, message)
    if not value then error(message or "expected truthy value") end
end

package.path = table.concat({
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/?.lua",
    "../psychopatzCore/Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua",
    "../psychopatzCore/Contents/mods/PsychopatzCore/42.19/media/lua/shared/?.lua",
    package.path,
}, ";")

local now = 1000
getTimeInMillis = function() return now end
local stores = {
    PNC_Core_Global = { records = { secret_dynamic_identifier_abcdefghijklmnopqrstuvwxyz = { revision = 2 } } },
    PNC_NPC_secret_dynamic_identifier_abcdefghijklmnopqrstuvwxyz = {
        identity = { name = "redacted value" },
        inventory = { items = { item_123 = { fullType = "Base.Axe", modData = { custom = "large" } } } },
    },
    OtherMod_Data = { shouldNotAppear = true },
}
ModData = {
    getTableNames = function() return { "PNC_Core_Global", "PNC_NPC_secret_dynamic_identifier_abcdefghijklmnopqrstuvwxyz", "OtherMod_Data" } end,
    get = function(name) return stores[name] end,
}

PsychopatzCore = nil
local Bootstrap = require "PsychopatzCore/Profiler/PsychopatzProfilerBootstrap"
Bootstrap.mode = "DETAILED"
local Profiler = require "PsychopatzCore/Profiler/PsychopatzProfiler"
Profiler.Start("DETAILED", {
    nowMs = function() return now end,
    sourceType = function() return "test" end,
}, { snapshotEnabled = false })

PNC = {
    Registry = {
        StorageKeyForID = function() return "PNC_NPC_secret_dynamic_identifier_abcdefghijklmnopqrstuvwxyz" end,
        Data = {
            npc_one = {
                name = "Alex Morgan",
                inventory = {
                    items = { item_1 = { fullType = "Base.Hammer", stack = 1 } },
                    containers = { root = { items = { "item_1" } } },
                },
                runtime = { inventory = { nextItemSerial = 1, opLog = { { revision = 1 } } } },
            },
        },
    },
}

local Analyzer = require "PNC/Integrations/PNC_PsychopatzModDataProfiler"
local report = Analyzer.Scan(true)
equal(report.persisted.modDataTables, 2, "only PNC ModData stores counted")
equal(report.runtimeRecords.recordCount, 1, "runtime record count")
equal(report.inventories.itemCount, 1, "inventory item count")
equal(report.inventories.operationLogEntries, 1, "inventory op-log count")
equal(report.npcRecords.records[1].name, "Alex Morgan", "NPC display name")
truthy(report.npcRecords.records[1].runtimeContent.inventory, "runtime content missing")
truthy(report.npcRecords.records[1].persistedContent.inventory, "persisted content missing")
truthy(report.persisted.estimatedBytes > 0, "persisted estimate missing")
truthy(report.inventories.estimatedBytes > 0, "inventory estimate missing")
equal(report.valuesRedacted, true, "report must redact values")
local snapshot = Profiler.BuildSnapshot()
truthy(snapshot.diagnostics["ProjectHoomans.modData"], "diagnostic missing from snapshot")
for _, item in ipairs(report.persisted.topPaths) do
    if string.find(item.path, "secret_dynamic_identifier", 1, true) then
        error("dynamic identifier leaked into diagnostic path")
    end
end

Profiler.Stop()
print("pnc profiler ModData smoke: ok")
