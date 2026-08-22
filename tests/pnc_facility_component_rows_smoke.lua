local T = require "tests/support/test"

T.addPackagePaths()

getText = function(key) return key end
PsychopatzCore = { UI = {
    Theme = { colors = {} },
    Layout = {},
} }
package.preload["PsychopatzCore/UI/PsychopatzUI"] = function()
    return PsychopatzCore.UI
end
package.preload[
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Components"
] = function() return {} end
package.preload[
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"
] = function() return {} end

PNC = { FacilityDefinitions = {
    GetLevel = function()
        return { componentLimits = {
            ["work.craft"] = {
                kind = "anchor", minCount = 1, maxCount = 1,
            },
            ["work.disassemble"] = {
                kind = "anchor", minCount = 1, maxCount = 1,
            },
        } }
    end,
} }

local Browser = require(
    "PNC/UI/Communities/ColonyManagement/SettlementManagement/"
    .. "PNC_SettlementManagement_FacilityBrowser")

local rows = Browser.BuildComponentRows({
    definitionId = "workshop", level = 1, components = {},
})
T.truthy(#rows == 2, "workshop should expose two component roles")
T.truthy(rows[1].key == "work.craft"
    and rows[1].componentAction.role == "work.craft",
    "craft station does not have its own assign action")
T.truthy(rows[2].key == "work.disassemble"
    and rows[2].componentAction.role == "work.disassemble",
    "disassembly station does not have its own assign action")

rows = Browser.BuildComponentRows({
    definitionId = "workshop", level = 1,
    components = {{
        id = "craft:1", kind = "anchor", role = "work.craft",
        x = 10, y = 11, z = 0,
    }},
})
T.truthy(#rows == 3, "placed component should add an editable child row")
T.truthy(rows[1].componentAction == nil,
    "full craft role still offered an extra assignment")
T.truthy(rows[2].componentAction.componentId == "craft:1"
    and rows[2].actionLabel == "MANAGE"
    and rows[2].secondaryAction.remove == true,
    "placed craft station does not have its own edit action")
T.truthy(rows[3].componentAction.role == "work.disassemble",
    "unplaced disassembly action disappeared after craft assignment")

PNC.FacilityDefinitions.GetLevel = function()
    return { componentLimits = {
        ["sleep.bed"] = { kind = "anchor", minCount = 1, maxCount = 4 },
    } }
end
rows = Browser.BuildComponentRows({
    definitionId = "barracks", level = 1,
    components = {
        { id = "bed:1", kind = "anchor", role = "sleep.bed",
            x = 10, y = 11, z = 0 },
        { id = "bed:2", kind = "anchor", role = "sleep.bed",
            x = 12, y = 11, z = 0 },
    },
})
T.truthy(#rows == 3,
    "barracks should expose each bed as an individual component")
T.truthy(rows[2].key == "bed:1"
    and rows[2].componentAction.componentId == "bed:1"
    and rows[2].secondaryAction.remove == true,
    "first bed does not have individual manage and deconstruct actions")
T.truthy(rows[3].key == "bed:2"
    and rows[3].componentAction.componentId == "bed:2"
    and rows[3].secondaryAction.remove == true,
    "second bed does not have individual manage and deconstruct actions")

rows = Browser.BuildComponentRows({
    definitionId = "stockpile", level = 1,
    components = {{
        id = "stockpile:1", kind = "region", role = "storage.stockpile",
        width = 2, height = 2, tileCount = 4,
    }},
}, {
    storageId = "storage:1", capacity = 200,
    usedWeight = 25, freeWeight = 175,
    access = { hasStockpile = true, insideBase = true },
})
T.truthy(#rows == 2, "stockpile inspector should show capacity and area")
T.truthy(rows[1].componentAction.kind == "open_stockpile"
    and rows[1].actionLabel == "OPEN STORAGE",
    "built in-base stockpile does not expose storage management")
T.truthy(rows[2].componentAction.kind == "stockpile_move"
    and rows[2].actionLabel == "MOVE"
    and rows[2].secondaryAction == nil,
    "stockpile area must only expose move")

rows = Browser.BuildComponentRows({
    definitionId = "stockpile", level = 1,
    components = {{ id = "stockpile:1", kind = "region",
        role = "storage.stockpile", tileCount = 1 }},
}, {
    storageId = "storage:1", capacity = 200,
    usedWeight = 0.9899999778717756,
    freeWeight = 199.01000002212822,
    access = { hasStockpile = true, insideBase = false, writable = false },
})
T.truthy(rows[1].componentAction.kind == "open_stockpile",
    "remote walkie-talkie view must remain accessible")
T.truthy(rows[1].detail == "1.0 / 200.0 | 199.0 FREE | REMOTE VIEW",
    "stockpile summary is not rounded or remote state is unclear")
T.finish("pnc_facility_component_rows_smoke")

T.finish("pnc_facility_component_rows_smoke")
