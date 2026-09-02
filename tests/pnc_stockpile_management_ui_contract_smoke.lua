local T = require "tests/support/test"

local tabs = T.read("ProjectHoomans", "client",
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Tabs.lua")
local actions = T.read("ProjectHoomans", "client",
    "PNC/UI/Communities/ColonyManagement/SettlementManagement/"
    .. "PNC_SettlementManagement_Actions.lua")
local tab = T.read("ProjectHoomans", "client",
    "PNC/UI/Communities/ColonyManagement/SettlementManagement/"
    .. "PNC_SettlementManagement_Tab.lua")
local storageWindow = T.read("ProjectHoomans", "client",
    "PNC/UI/Storage/PNC_StorageWindow.lua")
local storageController = T.read("ProjectHoomans", "client",
    "PNC/UI/Storage/PNC_StorageController.lua")
local storageClient = T.read("ProjectHoomans", "client",
    "PNC/UI/Storage/PNC_StorageClient.lua")
local storageLayout = T.read("ProjectHoomans", "client",
    "PNC/UI/Storage/PNC_StorageLayout.lua")
local context = T.read("ProjectHoomans", "client",
    "PNC/UI/Context/PNC_StockpileAccessContext.lua")
local definitions = T.read("ProjectHoomans", "shared",
    "PNC/Core/Settlement/PNC_FacilityDefinitions/"
    .. "PNC_FacilityDefinitions_Core.lua")

T.falsy(string.find(tabs, 'id = "storage"', 1, true),
    "colony management no longer registers a storage tab")
T.falsy(string.find(tabs, "PNC_ColonyManagementStorageTabs", 1, true),
    "colony management no longer loads the legacy storage panel")
T.contains(actions, 'action.kind == "open_stockpile"',
    "stockpile inspector owns standalone inventory access")
T.contains(actions, "PNC/UI/Storage/PNC_Storage",
    "stockpile inspector opens the full standalone storage surface")
T.falsy(string.find(actions, "access.insideBase ~= true", 1, true),
    "remote storage browsing must not be base-gated")
T.contains(actions, "window:close()",
    "opening standalone storage closes overlapping colony management")
T.contains(tab, 'facility.definitionId == "stockpile"',
    "stockpile deconstruction control has a special visibility rule")
T.contains(storageWindow, "Controller.CreateChildren",
    "storage window owns the canonical storage controller")
T.contains(storageWindow, "WidgetWindow.Install",
    "storage window supports the reusable detached widget behavior")
T.contains(storageWindow, "persistenceKey = \"PNC.CommandHub.Storage\"",
    "storage window persists its geometry independently")
T.contains(storageController, "storageActivityPane",
    "standalone storage window preserves activity logs")
T.contains(storageController, "storageDebugToggle",
    "standalone storage window preserves authorized debug tools")
T.contains(storageController, "UI_PNC_Storage_DebugForLumber",
    "storage debug exposes the lumber requirement action")
T.contains(storageController, 'debugAction = "job_requirements"',
    "lumber debug routes through the reusable requirement action")
T.contains(storageController, 'extra.operation = "LUMBER"',
    "lumber debug identifies the requested job")
T.contains(storageLayout, "access.writable == true",
    "inventory mover is writable only with authoritative base access")
T.contains(storageLayout, "setVisible(transferVisible == true)",
    "storage layout never passes nil to Java visibility methods")
T.contains(storageClient, "function Client.ReadSnapshot()",
    "storage reads through a dedicated client boundary")
T.falsy(string.find(storageWindow, "PNC_ColonyManagementStorageTabs", 1, true),
    "storage window no longer depends on the removed management tab shell")
T.falsy(string.find(storageWindow, "StorageTabs", 1, true),
    "storage window no longer carries the legacy tab shell")
T.contains(context, "findStockpileAtSquare",
    "right-click access resolves the built stockpile facility region")
T.contains(definitions,
    "media/ui/Facilities/Components/storage/stockpile.png",
    "stockpile component uses its dedicated icon")

local opened = 0
package.preload["PsychopatzCore/World/PC_GridRegion"] = function()
    return { containsPoint = function(_, x, y, z)
        return x == 4 and y == 5 and z == 0
    end }
end
PNC = {
    Network = { ClientState = { colonyManagement = {
        storage = { storageId = "storage:1", access = {
            hasStockpile = true, insideBase = false, writable = false,
        } },
        settlement = { facilities = {{
            id = "stockpile:1", definitionId = "stockpile",
            constructionState = "BUILT", components = {{
                role = "storage.stockpile", region = { levels = {} },
            }},
        }} },
    } } },
    NPCSelection = { GetWorldSquare = function()
        return { getX = function() return 4 end,
            getY = function() return 5 end,
            getZ = function() return 0 end }
    end },
    ColonyStorageUI = { Open = function() opened = opened + 1; return {} end },
}
Events = { OnFillWorldObjectContextMenu = { Add = function() end } }
getText = function(key) return key end
local Context = T.load("ProjectHoomans", "client",
    "PNC/UI/Context/PNC_StockpileAccessContext.lua")
local option
Context.OnFillWorldObjectContextMenu(0, {
    addOption = function(_, label, target, action)
        option = { label = label, target = target, action = action }
    end,
}, {}, false)
T.truthy(option, "right-clicking the built stockpile region adds access")
T.equal(option.label, "Open Colony Storage",
    "stockpile context advertises the standalone storage surface")
option.action(option.target)
T.equal(opened, 1, "remote stockpile context opens standalone storage")

T.finish("pnc_stockpile_management_ui_contract_smoke")
