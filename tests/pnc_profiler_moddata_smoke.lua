local T = require "tests/support/test"

T.addPackagePaths()

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
}, { snapshotEnabled = false, capture = {
    performance = false, moddata = true, npc = true,
} })

PNC = {
    Registry = {
        StorageKeyForID = function() return "PNC_NPC_secret_dynamic_identifier_abcdefghijklmnopqrstuvwxyz" end,
        Data = {
            npc_one = {
                name = "Alex Morgan",
                inventory = {
                    items = { item_1 = { fullType = "Base.Hammer", stack = 1 } },
                    containers = { root = { items = { "item_1" } } },
                    equipped = { primary = "item_1" },
                    worn = { Back = "item_1" },
                    attached = { Belt = "item_1" },
                },
                runtime = { inventory = { nextItemSerial = 1, opLog = { { revision = 1 } } } },
            },
        },
    },
}

local Analyzer = require "PNC/Integrations/PNC_PsychopatzModDataProfiler"
local report = Analyzer.Scan(true)
local Content = require "PNC/Integrations/PNC_PsychopatzModDataContent"
local npcReport = Content.Scan()
T.equal(report.persisted.modDataTables, 2, "only PNC ModData stores counted")
T.equal(report.runtimeRecords.recordCount, 1, "runtime record count")
T.equal(report.inventories.itemCount, 1, "inventory item count")
T.equal(report.inventories.operationLogEntries, 1, "inventory op-log count")
T.equal(npcReport.records[1].name, "Alex Morgan", "NPC display name")
T.equal(npcReport.records[1].wornItems, 1, "NPC worn item count")
T.equal(npcReport.records[1].equippedItems, 1, "NPC equipped item count")
T.equal(npcReport.records[1].attachedItems, 1, "NPC attached item count")
T.equal(npcReport.records[1].inventoryContainers, 1, "NPC container count")
T.truthy(npcReport.records[1].runtimeContent.inventory, "runtime content missing")
T.truthy(npcReport.records[1].persistedContent.inventory, "persisted content missing")
T.truthy(report.persisted.estimatedBytes > 0, "persisted estimate missing")
T.truthy(report.inventories.estimatedBytes > 0, "inventory estimate missing")
T.equal(report.valuesRedacted, true, "report must redact values")
T.equal(npcReport.limits.maxNPCs, 12,
    "periodic profiler NPC content limit")
T.equal(npcReport.limits.maxNodesPerView, 120,
    "periodic profiler record node limit")
Bootstrap.captureConfig = {
    mode = "DETAILED", enabled = { moddata = true, npc = true },
    npcScope = "selected", npcIDs = { "npc_one" },
    npcIntervalMs = 5000, modDataIntervalMs = 60000,
}
require "PNC/Integrations/PNC_PsychopatzNPCProfiler"
local snapshot = Profiler.BuildSnapshot()
T.truthy(snapshot.diagnostics["ProjectHoomans.modData"], "diagnostic missing from snapshot")
T.equal(snapshot.diagnostics["ProjectHoomans.npcData"].records[1].id, "npc_one",
    "targeted NPC diagnostic missing")
for _, item in ipairs(report.persisted.topPaths) do
    if string.find(item.path, "secret_dynamic_identifier", 1, true) then
        error("dynamic identifier leaked into diagnostic path")
    end
end

Profiler.Stop()
T.finish("pnc_profiler_moddata_smoke")

T.finish("pnc_profiler_moddata_smoke")
