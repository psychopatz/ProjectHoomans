package.path = table.concat({
    "Contents/mods/ProjectHoomans/42.20/media/lua/client/?.lua",
    package.path,
}, ";")

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
assert(#rows == 2, "workshop should expose two component roles")
assert(rows[1].key == "work.craft"
    and rows[1].componentAction.role == "work.craft",
    "craft station does not have its own assign action")
assert(rows[2].key == "work.disassemble"
    and rows[2].componentAction.role == "work.disassemble",
    "disassembly station does not have its own assign action")

rows = Browser.BuildComponentRows({
    definitionId = "workshop", level = 1,
    components = {{
        id = "craft:1", kind = "anchor", role = "work.craft",
        x = 10, y = 11, z = 0,
    }},
})
assert(#rows == 3, "placed component should add an editable child row")
assert(rows[1].componentAction == nil,
    "full craft role still offered an extra assignment")
assert(rows[2].componentAction.componentId == "craft:1"
    and rows[2].actionLabel == "EDIT",
    "placed craft station does not have its own edit action")
assert(rows[3].componentAction.role == "work.disassemble",
    "unplaced disassembly action disappeared after craft assignment")

PNC.FacilityDefinitions.GetLevel = function()
    return { componentLimits = {
        ["sleep.area"] = { kind = "region", minCount = 1, maxCount = 1 },
        ["sleep.bed"] = { kind = "anchor", minCount = 1, maxCount = 4 },
    } }
end
rows = Browser.BuildComponentRows({
    definitionId = "barracks", level = 1,
    components = {
        { id = "area:1", kind = "region", role = "sleep.area",
            tileCount = 12 },
        { id = "bed:1", kind = "anchor", role = "sleep.bed",
            x = 10, y = 11, z = 0 },
        { id = "bed:2", kind = "anchor", role = "sleep.bed",
            x = 12, y = 11, z = 0 },
    },
})
assert(#rows == 3,
    "barracks should collapse individual beds into one sleep-spots editor")
assert(rows[3].key == "sleep.bed"
    and rows[3].componentAction.groupEdit == true
    and rows[3].actionLabel == "EDIT SPOTS",
    "barracks sleep spots are not managed as one uniform component group")

print("pnc_facility_component_rows_smoke: ok")
