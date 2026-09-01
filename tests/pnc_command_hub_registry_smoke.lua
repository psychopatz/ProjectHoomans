local T = require "tests/support/test"

PsychopatzCore = { UI = {} }
local CoreRegistry = T.load("PsychopatzCore", "client",
    "PsychopatzCore/UI/PsychopatzCommandHubRegistry.lua")
package.preload["PsychopatzCore/UI/PsychopatzCommandHub"] = function()
    return { Registry = CoreRegistry }
end

PNC = { CommandHub = {} }

local Registry = T.load("ProjectHoomans", "client",
    "PNC/UI/CommandHub/PNC_CommandHub_Registry.lua")

T.falsy(Registry.Get("orders"),
    "obsolete Orders category was registered")
local zone = Registry.Get("zone")
T.truthy(zone, "zone category was not registered")
local categories = Registry.All()
T.equal(categories[1].id, "work", "work is not first in the manual hierarchy")
T.equal(categories[2].id, "zone", "zone is not second in the manual hierarchy")
T.equal(categories[3].id, "settings",
    "settings is not third in the manual hierarchy")
T.equal(categories[4].id, "events",
    "events is not fourth in the manual hierarchy")
for _, id in ipairs({
    "structure", "production", "furniture", "external_furniture",
    "genetics", "power", "pipe_networks", "security", "misc", "floors",
    "recreation", "ship", "temperature", "ideology", "biotech",
}) do
    T.falsy(Registry.Get(id), "placeholder category survived: " .. id)
end
T.equal(#zone.actions, 3, "zone action count changed")
T.equal(zone.actions[1].id, "lumber", "chop wood is not first")
T.equal(zone.actions[2].id, "corpse_haul", "grab corpse is not second")
T.equal(zone.actions[3].id, "fishing", "fishing is not third")
T.truthy(Registry.Get("settings").onClick,
    "settings category does not expose its settings workflow")
T.truthy(Registry.Get("work").onClick,
    "work category does not expose its authorization workflow")
T.equal(Registry.Get("events").childID, "events",
    "events category is not managed as a command-hub child")
T.truthy(Registry.IsEnabled(Registry.Get("events")),
    "events category is unexpectedly gated by radio availability")
T.truthy(PNC.CommandHub.Gates
    and PNC.CommandHub.Gates.HasBaseAndStockpile,
    "command hub does not expose the base and stockpile gate")

PNC.ColonyManagementClient = {
    ReadSnapshot = function()
        return { snapshot = {} }
    end,
}
T.falsy(Registry.IsEnabled(Registry.Get("work")),
    "work remains enabled without a base and stockpile")
T.falsy(Registry.IsEnabled(Registry.Get("zone")),
    "zone remains enabled without a base and stockpile")
PNC.ColonyManagementClient.ReadSnapshot = function()
    return {
        snapshot = { settlement = {
            facilities = { { definitionId = "stockpile", constructionState = "BUILT" } },
        } },
    }
end
T.truthy(Registry.IsEnabled(Registry.Get("work")),
    "work did not enable after a base and stockpile became available")
T.truthy(Registry.IsEnabled(Registry.Get("zone")),
    "zone did not enable after a base and stockpile became available")

local openedWork = false
local openedEvents = false
PNC.CommandHub.WorkUI = {
    Open = function()
        openedWork = true
        return true
    end,
}
local openedZones = {}
PNC.CommandHub.ZoneUI = {
    Open = function(actionID)
        openedZones[#openedZones + 1] = actionID
        return true
    end,
}
PNC.ColonyJournalButton = {
    HasRadio = function() return false end,
}
PNC.ColonyJournalUI = {
    Toggle = function()
        openedEvents = true
        return true
    end,
}
Registry.Get("work").onClick()
T.truthy(openedWork, "work category is not wired to its window")
T.truthy(Registry.IsEnabled(Registry.Get("events")),
    "events category is disabled without a radio")
Registry.Get("events").onClick()
T.truthy(openedEvents, "events category is not wired to the colony journal")
zone.actions[1].onClick()
zone.actions[2].onClick()
zone.actions[3].onClick()
T.equal(openedZones[1], "lumber", "chop wood workflow is not wired")
T.equal(openedZones[2], "corpse_haul", "grab corpse workflow is not wired")
T.equal(openedZones[3], "fishing", "fishing workflow is not wired")
PNC.CommandHub.ZoneUI.activeDefinitionID = "fishing"
PNC.CommandHub.ZoneUI.instances = {
    fishing = { getIsVisible = function() return true end },
}
T.truthy(Registry.IsSelected(zone.actions[3]),
    "active fishing zone action is not selected")
T.falsy(Registry.IsSelected(zone.actions[1]),
    "inactive zone action is selected")

local workRegistry = T.load("ProjectHoomans", "client",
    "PNC/UI/CommandHub/PNC_CommandHub_WorkRegistry.lua")
T.equal(workRegistry.Get("Lumber").titleFallback, "LUMBER",
    "work registry does not expose lumber authorization")
local workWindowSource = T.read("ProjectHoomans", "client",
    "PNC/UI/CommandHub/PNC_CommandHub_WorkWindow.lua")
T.contains(workWindowSource, "UI.CreateCheckbox",
    "work window does not create authorization checkboxes")
T.contains(workWindowSource, "authorizationPanel",
    "work window does not provide a readable authorization surface")
T.contains(workWindowSource, "job_permission_set",
    "work window does not use the server permission action")
local workLayoutSource = T.read("ProjectHoomans", "client",
    "PNC/UI/CommandHub/PNC_CommandHub_WorkWindow_Layout.lua")
T.contains(workLayoutSource, "Layout.SetBounds(self.authorizationPanel",
    "authorization surface is not responsive")
T.contains(workLayoutSource, "getContentRect({ top = 30",
    "work section headers are not padded below the title bar")
local corpseHaulSource = T.read("ProjectHoomans", "client",
    "PNC/UI/CommandHub/PNC_CommandHub_CorpseHaulUI.lua")
T.contains(corpseHaulSource, "SELECT CORPSE SOURCE AREA",
    "corpse haul source selector is missing")
T.contains(corpseHaulSource, "SELECT CORPSE DESTINATION AREA",
    "corpse haul destination selector is missing")
T.contains(corpseHaulSource, "corpse_haul_zones_set",
    "corpse haul selectors do not save their regions")
local zoneWindowSource = T.read("ProjectHoomans", "client",
    "PNC/UI/CommandHub/PNC_CommandHub_ZoneWindow.lua")
T.contains(zoneWindowSource, "ZoneUI.SyncPositions",
    "zone subwindows are not positioned as detached panels")
T.contains(zoneWindowSource, "CREATE ZONE",
    "zone subwindows do not expose create controls")
T.contains(zoneWindowSource, "DELETE ZONE",
    "zone subwindows do not expose delete controls")
T.contains(zoneWindowSource, "ZoneUI.CloseAll()",
    "zone subwindows do not close with the hidden parent")
T.contains(zoneWindowSource, "PsychopatzAttachedWindow",
    "zone subwindows do not use the shared attached-panel variant")
T.contains(zoneWindowSource, "activeDefinitionID",
    "zone subwindows do not track one active third-level child")
T.contains(zoneWindowSource, "ZoneOverlay.SetActive",
    "zone subwindows do not synchronize their world overlay")
T.contains(zoneWindowSource, "geometryTrace = true",
    "zone geometry tracing is not available")
local zoneLayoutSource = T.read("ProjectHoomans", "client",
    "PNC/UI/CommandHub/PNC_CommandHub_ZoneWindow_Layout.lua")
T.contains(zoneLayoutSource, "getContentRect({ padding = 12 })",
    "zone layout is not using the shared attached content bounds")
T.contains(zoneLayoutSource, "self:footerHeight()",
    "zone layout does not reserve the shared resize footer")
local actionSource = T.read("PsychopatzCore", "client",
    "PsychopatzCore/UI/PsychopatzCommandHubActionsWindow.lua")
T.contains(actionSource, "persistenceKey = \"PsychopatzCore.CommandHub.Actions\"",
    "action panel geometry is not persisted")
T.contains(actionSource, "Registry.IsSelected(action",
    "zone action buttons do not expose selected state")

local future = Registry.RegisterCategory({
    id = "future_category", order = 900,
    titleKey = "UI_PNC_Test_FutureCategory",
})
local action = Registry.RegisterAction("future_category", {
    id = "future_action", order = 10,
    titleKey = "UI_PNC_Test_FutureAction",
})
T.truthy(future, "future category registration failed")
T.truthy(action, "future action registration failed")
T.equal(Registry.GetAction("future_category", "future_action"), action,
    "future action could not be retrieved")

local composition = T.read("ProjectHoomans", "client",
    "PNC/Composition/PNC_ClientComposition.lua")
T.contains(composition, "PNC/UI/CommandHub/PNC_CommandHub",
    "command hub is not in the client composition")
T.falsy(string.find(composition, "PNC/UI/Orders/", 1, true),
    "legacy Orders UI is still in the client composition")

local windowSource = T.read("ProjectHoomans", "client",
    "PNC/UI/CommandHub/PNC_CommandHub_Window.lua")
T.contains(windowSource, "ChildController.Toggle",
    "command hub categories are not routed through the child controller")
T.contains(windowSource, "persistenceKey = \"PNC.CommandHub\"",
    "command hub geometry is not persisted")
T.falsy(string.find(windowSource, "PNC_CommandHub_Window_Layout", 1, true),
    "legacy command hub layout is still referenced")
T.falsy(string.find(composition, "PNC_CommandHub_ActionsWindow", 1, true),
    "legacy command hub action window is still composed")
local childControllerSource = T.read("ProjectHoomans", "client",
    "PNC/UI/CommandHub/PNC_CommandHub_ChildController.lua")
T.contains(childControllerSource, "CoreHub.Actions",
    "zone actions are not using the Core action window")
T.falsy(string.find(childControllerSource, "Hub.ActionsUI", 1, true),
    "child controller still depends on the removed PNC action window")
T.contains(childControllerSource, 'Controller.Register("events"',
    "colony journal is not managed by the child controller")
T.contains(childControllerSource, "PNC.ColonyJournalUI",
    "child controller does not manage the colony journal instance")
local zoneSource = T.read("ProjectHoomans", "client",
    "PNC/UI/CommandHub/PNC_CommandHub_ZoneWindow.lua")
T.contains(zoneSource, "CoreHub.Actions",
    "zone panels are not anchored to the Core action window")
local workSource = T.read("ProjectHoomans", "client",
    "PNC/UI/CommandHub/PNC_CommandHub_WorkWindow.lua")
T.contains(workSource, "PsychopatzCore/UI/PsychopatzCommandHubOptions",
    "work window does not consume Core options")
local settingsSource = T.read("ProjectHoomans", "client",
    "PNC/UI/CommandHub/PNC_CommandHub_SettingsWindow.lua")
T.contains(settingsSource, "PsychopatzCore/UI/PsychopatzCommandHub",
    "settings window does not consume Core services")
T.falsy(string.find(settingsSource, "PNC_CommandHub_Options", 1, true),
    "settings window still uses the removed options shim")
T.contains(settingsSource, "UI.CreateTextEntry",
    "settings window has no editable fields")
T.contains(settingsSource, "UI.CreateSlider",
    "settings window opacity is not using the shared slider")
T.contains(settingsSource, "UI.SetLabelText",
    "settings labels can move when their dynamic text changes")
T.contains(settingsSource, "SettingsUI.Open",
    "settings window is not reachable")
T.contains(settingsSource, "onBranchToggle",
    "settings window cannot toggle action panel side")
T.contains(settingsSource, "setStatus",
    "settings feedback is not routed through the status area")
local settingsLayoutSource = T.read("ProjectHoomans", "client",
    "PNC/UI/CommandHub/PNC_CommandHub_SettingsWindow_Layout.lua")
T.contains(settingsLayoutSource, "onResponsiveLayout",
    "settings controls do not have responsive layout")
T.contains(settingsLayoutSource, "Layout.SetBounds(self.statusLabel",
    "settings feedback is not positioned in the footer")
local animationSource = T.read("ProjectHoomans", "client",
    "PNC/UI/PNC_AnimationDebugWindow.lua")
T.contains(animationSource, "Layout.SetBounds(self.search",
    "animation search field bypasses shared bounds")
T.falsy(string.find(animationSource, "self.search:setX", 1, true),
    "animation search field still uses manual geometry")
local animationSceneSource = T.read("ProjectHoomans", "client",
    "PNC/UI/PNC_AnimationSceneDebugWindow.lua")
T.contains(animationSceneSource, "Layout.SetBounds(self.gapEntry",
    "animation scene field bypasses shared bounds")
T.falsy(string.find(animationSceneSource, "self.gapEntry:setX", 1, true),
    "animation scene field still uses manual geometry")
local provisionSettingsSource = T.read("ProjectHoomans", "client",
    "PNC/UI/Provision/PNC_ProvisionSettingsWindow.lua")
T.contains(provisionSettingsSource, "UI.SetLabelText(self.statusLabel",
    "provision status label can jump after text changes")
T.contains(provisionSettingsSource, "Layout.SetBounds(self.statusLabel",
    "provision status label bypasses shared bounds")
T.falsy(string.find(provisionSettingsSource, "statusLabel:setName",
    1, true), "provision settings still mutates labels unsafely")
local provisionRuleSource = T.read("ProjectHoomans", "client",
    "PNC/UI/Provision/PNC_ProvisionRulePanel.lua")
T.contains(provisionRuleSource, "UI.SetLabelText(widget",
    "provision description labels can jump after wrapping")
T.contains(provisionRuleSource, "Layout.SetBounds(row.panel",
    "provision rule panels bypass shared bounds")
T.falsy(string.find(provisionRuleSource, "widget:setName",
    1, true), "provision rules still mutate labels unsafely")
T.contains(childControllerSource, "function Controller.Toggle",
    "command hub child toggling is not centralized")
T.contains(childControllerSource, "function Controller.CloseAll",
    "command hub child cleanup is not centralized")

T.finish("pnc_command_hub_registry_smoke")
