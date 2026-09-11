local T = require "tests/support/test"

PsychopatzCore = { UI = {} }
local CoreRegistry = T.load("PsychopatzCore", "client",
    "PsychopatzCore/UI/PsychopatzCommandHubRegistry.lua")
package.preload["PsychopatzCore/UI/PsychopatzCommandHub"] = function()
    return { Registry = CoreRegistry }
end

local carriedMoney = 0
local playerInventory = {
    getItemsFromType = function(_, fullType)
        if fullType ~= "Base.Money" then
            return { size = function() return 0 end }
        end
        return { size = function() return carriedMoney end }
    end,
}
local player = {
    getInventory = function() return playerInventory end,
}
function getSpecificPlayer()
    return player
end

PNC = {
    CommandHub = {},
    FacilityDefinitions = {
        Get = function(id)
            if id ~= "stockpile" then return nil end
            return {
                buildCosts = {
                    { fullType = "Base.Money", amount = 1 },
                },
            }
        end,
    },
}

local Registry = T.load("ProjectHoomans", "client",
    "PNC/UI/CommandHub/PNC_CommandHub_Registry.lua")
local Colony = T.load("ProjectHoomans", "client",
    "PNC/UI/CommandHub/PNC_CommandHub_Colony.lua")
local Workshop = T.load("ProjectHoomans", "client",
    "PNC/UI/CommandHub/PNC_CommandHub_Workshop.lua")

T.falsy(Registry.Get("orders"),
    "obsolete Orders category was registered")
local zone = Registry.Get("zone")
T.truthy(zone, "zone category was not registered")
local categories = Registry.All()
T.equal(categories[1].id, "work", "work is not first in the manual hierarchy")
T.equal(categories[2].id, "workshop",
    "workshop is not second in the manual hierarchy")
T.equal(categories[3].id, "zone", "zone is not third in the manual hierarchy")
T.equal(categories[4].id, "colony",
    "colony is not fourth in the manual hierarchy")
T.equal(categories[5].id, "events",
    "events is not fifth in the manual hierarchy")
T.equal(categories[6].id, "colonist",
    "colonist is not sixth in the manual hierarchy")
T.equal(categories[7].id, "storage",
    "storage is not seventh in the manual hierarchy")
T.equal(categories[8].id, "research",
    "research is not eighth in the manual hierarchy")
T.equal(categories[9].id, "stockpile",
    "stockpile bootstrap is not ninth in the manual hierarchy")
T.equal(categories[10].id, "base",
    "base is not tenth in the manual hierarchy")
for _, id in ipairs({
    "structure", "production", "furniture", "external_furniture",
    "genetics", "power", "pipe_networks", "security", "misc", "floors",
    "recreation", "ship", "temperature", "ideology", "biotech",
}) do
    T.falsy(Registry.Get(id), "placeholder category survived: " .. id)
end
T.equal(#zone.actions, 4, "zone action count changed")
T.equal(zone.actions[1].id, "base_zone", "base zone is not first")
T.equal(zone.actions[2].id, "lumber", "chop wood is not second")
T.equal(zone.actions[3].id, "corpse_haul", "grab corpse is not third")
T.equal(zone.actions[4].id, "fishing", "fishing is not fourth")
T.falsy(Registry.Get("settings"),
    "settings remains registered as a root category")
local colony = Registry.Get("colony")
T.truthy(colony, "colony category was not registered")
T.equal(colony.childID, "colony",
    "colony category is not managed as a command-hub child")
T.equal(#colony.actions, 3, "colony action count changed")
T.equal(colony.actions[1].id, "provision_settings",
    "provision settings is not the first colony action")
T.equal(colony.actions[2].id, "change_name",
    "change name is not the second colony action")
T.equal(colony.actions[3].id, "change_emblem",
    "change emblem is not the third colony action")
T.truthy(Colony.Register, "colony provider does not expose action registration")
local workshop = Registry.Get("workshop")
T.truthy(workshop, "workshop category was not registered")
T.equal(workshop.childID, "workshop",
    "workshop category is not managed as a command-hub child")
T.truthy(Workshop, "workshop provider did not load")
T.truthy(Registry.Get("work").onClick,
    "work category does not expose its authorization workflow")
T.equal(Registry.Get("events").childID, "events",
    "events category is not managed as a command-hub child")
T.truthy(Registry.IsEnabled(Registry.Get("events")),
    "events category is unexpectedly gated by radio availability")
T.truthy(PNC.CommandHub.Gates
    and PNC.CommandHub.Gates.HasBaseAndStockpile,
    "command hub does not expose the base and stockpile gate")
T.truthy(PNC.CommandHub.Gates.HasColony,
    "command hub does not expose the colony gate for Base")
T.truthy(PNC.CommandHub.Gates.HasBase,
    "command hub does not expose the base gate for Base Zone")
T.truthy(Registry.Get("storage").onClick,
    "storage category does not expose its standalone workflow")
T.truthy(Registry.Get("research").onClick,
    "research category does not expose its standalone workflow")
T.truthy(Registry.Get("stockpile").onClick,
    "stockpile category does not expose its bootstrap workflow")
T.truthy(Registry.Get("base").onClick,
    "base category does not expose its standalone workflow")

PNC.ColonyManagementClient = {
    ReadSnapshot = function()
        return { snapshot = {} }
    end,
}
local disabledTooltip = colony.actions[2].disabledTooltip(colony.actions[2])
T.falsy(Registry.IsEnabled(colony.actions[2]),
    "change name enabled without faction data")
T.equal(disabledTooltip.key, "UI_PNC_CommandHub_Disabled_ColonyName",
    "missing faction reason is not exposed for change name")
disabledTooltip = colony.actions[3].disabledTooltip(colony.actions[3])
T.equal(disabledTooltip.key, "UI_PNC_CommandHub_Disabled_ColonyEmblem",
    "missing faction reason is not exposed for change emblem")
local gateStatus = PNC.CommandHub.Gates.GetBaseAndStockpileStatus()
T.falsy(gateStatus.hasBase, "empty snapshot incorrectly reports a base")
T.falsy(gateStatus.hasStockpile,
    "empty snapshot incorrectly reports a stockpile")
disabledTooltip = Registry.Get("work").disabledTooltip(
    Registry.Get("work"))
T.equal(disabledTooltip.key,
    "UI_PNC_CommandHub_Disabled_NoBaseOrStockpile",
    "missing base and stockpile reason is not exposed")
T.equal(disabledTooltip.fallback,
    "Requires a colony base and a completed stockpile.",
    "missing base and stockpile tooltip fallback changed")
T.falsy(Registry.IsEnabled(Registry.Get("work")),
    "work remains enabled without a base and stockpile")
T.falsy(Registry.IsEnabled(Registry.Get("zone")),
    "zone remains enabled without a base and stockpile")
T.falsy(Registry.IsEnabled(Registry.Get("stockpile")),
    "stockpile bootstrap remains enabled without a base")
T.falsy(Registry.IsEnabled(Registry.Get("base")),
    "base remains enabled without a colony")
PNC.Network = { ClientState = {} }
T.falsy(Registry.IsEnabled(Registry.Get("base")),
    "Base remains enabled while the multiplayer snapshot is pending")
PNC.Network = nil
PNC.ColonyManagementClient.ReadSnapshot = function()
    return { snapshot = {
        colony = { id = "colony-1" },
        settlement = { facilities = {} },
    } }
end
disabledTooltip = Registry.Get("work").disabledTooltip(Registry.Get("work"))
T.equal(disabledTooltip.key, "UI_PNC_CommandHub_Disabled_NoStockpile",
    "missing stockpile reason is not exposed")
T.equal(disabledTooltip.fallback,
    "Requires a completed stockpile in your colony base.",
    "missing stockpile tooltip fallback changed")
T.falsy(Registry.IsEnabled(Registry.Get("work")),
    "work enabled without a stockpile")
T.falsy(Registry.IsEnabled(Registry.Get("stockpile")),
    "stockpile bootstrap enabled without its required material")
disabledTooltip = Registry.Get("stockpile").disabledTooltip(
    Registry.Get("stockpile"))
T.equal(disabledTooltip.key,
    "UI_PNC_CommandHub_Disabled_NoStockpileMaterials",
    "missing stockpile material reason is not exposed")
carriedMoney = 1
T.truthy(Registry.IsEnabled(Registry.Get("stockpile")),
    "stockpile bootstrap did not enable with its required material")
T.truthy(Registry.IsEnabled(Registry.Get("base")),
    "Base remained blocked before a stockpile existed")
PNC.ColonyManagementClient.ReadSnapshot = function()
    return {
        snapshot = {
            colony = { id = "colony-1" },
            settlement = {
                facilities = { { definitionId = "stockpile", constructionState = "BUILT" } },
            },
        },
    }
end
gateStatus = PNC.CommandHub.Gates.GetBaseAndStockpileStatus()
T.truthy(gateStatus.hasBase, "settlement incorrectly reports no base")
T.truthy(gateStatus.hasStockpile, "built stockpile was not detected")
T.truthy(Registry.IsEnabled(Registry.Get("work")),
    "work did not enable after a base and stockpile became available")
T.truthy(Registry.IsEnabled(Registry.Get("zone")),
    "zone did not enable after a base and stockpile became available")

local openedWork = false
local openedWorkshop = false
local openedColony = false
local openedProvision = false
local provisionOwner
local openedChangeName = false
local changeNameOptions
local openedChangeEmblem = false
local emblemOptions
local savedEmblem
local openedEvents = false
local openedColonist = false
local openedStorage = false
local openedResearch = false
local openedBase = false
PNC.CommandHub.WorkUI = {
    Open = function()
        openedWork = true
        return true
    end,
}
PNC.CommandHub.ChildController = {
    Toggle = function(id, owner)
        if id == "colony" then openedColony = true end
        if id == "work" and PNC.CommandHub.WorkUI
            and PNC.CommandHub.WorkUI.Open
        then
            PNC.CommandHub.WorkUI.Open(owner)
        end
        if id == "workshop" then openedWorkshop = true end
        if id == "events" and PNC.ColonyJournalUI
            and PNC.ColonyJournalUI.Toggle
        then
            PNC.ColonyJournalUI.Toggle(owner)
        end
        if id == "colonist" and PNC.ColonistUI
            and PNC.ColonistUI.Open
        then
            PNC.ColonistUI.Open(owner)
        end
        if id == "storage" and PNC.ColonyStorageUI
            and PNC.ColonyStorageUI.Open
        then
            PNC.ColonyStorageUI.Open(owner)
        end
        if id == "research" and PNC.ResearchUI
            and PNC.ResearchUI.Open
        then
            PNC.ResearchUI.Open(owner)
        end
        if id == "base" and PNC.BuildingUI
            and PNC.BuildingUI.Open
        then
            openedBase = true
            PNC.BuildingUI.Open(owner)
        end
        return true
    end,
    IsOpen = function() return false end,
}
PNC.ProvisionSettingsUI = {
    Open = function(owner)
        openedProvision = true
        provisionOwner = owner
        return true
    end,
}
PNC.ColonyNamePrompt = {
    Open = function(options)
        openedChangeName = true
        changeNameOptions = options
        return true
    end,
}
PNC.FactionEmblemEditor = {
    Open = function(options)
        openedChangeEmblem = true
        emblemOptions = options
        return true
    end,
}
PNC.Client = {
    SetFactionEmblem = function(emblem)
        savedEmblem = emblem
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
PNC.ColonistUI = {
    Open = function()
        openedColonist = true
        return true
    end,
}
PNC.ColonyStorageUI = {
    Open = function()
        openedStorage = true
        return true
    end,
}
PNC.ResearchUI = {
    Open = function()
        openedResearch = true
        return true
    end,
}
PNC.BuildingUI = {
    Open = function()
        openedBuilding = true
        return true
    end,
}
Registry.Get("work").onClick()
T.truthy(openedWork, "work category is not wired to its window")
Registry.Get("workshop").onClick()
T.truthy(openedWorkshop, "workshop category is not wired to its window")
Registry.Get("colony").onClick(nil, {})
T.truthy(openedColony, "colony category is not wired to its child branch")
Registry.Get("colony").actions[1].onClick(nil, {})
T.truthy(openedProvision, "provision settings action is not wired")
T.truthy(provisionOwner, "provision settings did not receive its hub owner")
PNC.ColonyManagementClient.ReadSnapshot = function()
    return { snapshot = {
        faction = {
            id = "faction-player", name = "Morgan Clan",
            archetypeID = "settler", emblem = { backgroundColorID = "blue" },
        },
    } }
end
T.truthy(Registry.IsEnabled(Registry.Get("colony").actions[2]),
    "change name remains disabled with an established faction")
Registry.Get("colony").actions[2].onClick(nil, {})
T.truthy(openedChangeName, "change name action is not wired")
T.equal(changeNameOptions.mode, "rename",
    "change name action did not request rename mode")
T.equal(changeNameOptions.snapshot.faction.name, "Morgan Clan",
    "change name action did not pass the current faction snapshot")
Registry.Get("colony").actions[3].onClick(nil, {})
T.truthy(openedChangeEmblem, "change emblem action is not wired")
T.equal(emblemOptions.archetypeID, "settler",
    "change emblem action did not pass the faction archetype")
T.equal(emblemOptions.seed, "faction-player",
    "change emblem action did not pass the faction seed")
T.equal(emblemOptions.emblem.backgroundColorID, "blue",
    "change emblem action did not pass the current emblem")
emblemOptions.onSave({ backgroundColorID = "red" })
T.equal(savedEmblem.backgroundColorID, "red",
    "change emblem action did not preserve the authoritative save callback")
T.truthy(Registry.IsEnabled(Registry.Get("events")),
    "events category is disabled without a radio")
Registry.Get("events").onClick()
T.truthy(openedEvents, "events category is not wired to the colony journal")
Registry.Get("colonist").onClick()
T.truthy(openedColonist, "colonist category is not wired to its window")
Registry.Get("storage").onClick()
T.truthy(openedStorage, "storage category is not wired to its window")
Registry.Get("research").onClick()
T.truthy(openedResearch, "research category is not wired to its window")
Registry.Get("base").onClick()
T.truthy(openedBase, "base category is not wired to its window")
zone.actions[1].onClick()
zone.actions[2].onClick()
zone.actions[3].onClick()
zone.actions[4].onClick()
T.equal(openedZones[1], "base_zone", "base zone workflow is not wired")
T.equal(openedZones[2], "lumber", "chop wood workflow is not wired")
T.equal(openedZones[3], "corpse_haul", "grab corpse workflow is not wired")
T.equal(openedZones[4], "fishing", "fishing workflow is not wired")
PNC.CommandHub.ZoneUI.activeDefinitionID = "fishing"
PNC.CommandHub.ZoneUI.instances = {
    fishing = { getIsVisible = function() return true end },
}
T.truthy(Registry.IsSelected(zone.actions[4]),
    "active fishing zone action is not selected")
T.falsy(Registry.IsSelected(zone.actions[1]),
    "inactive zone action is selected")

local workRegistry = T.load("ProjectHoomans", "client",
    "PNC/UI/CommandHub/PNC_CommandHub_WorkRegistry.lua")
T.equal(workRegistry.Get("Lumber").titleFallback, "LUMBER",
    "work registry does not expose lumber authorization")
T.truthy(workRegistry.Get("Provisioner"),
    "work registry does not expose provisioner authorization")
T.truthy(workRegistry.Get("MedicalCare"),
    "work registry does not expose medical-care authorization")
local workWindowSource = T.read("ProjectHoomans", "client",
    "PNC/UI/CommandHub/PNC_CommandHub_WorkWindow.lua")
local settingsWindowSource = T.read("ProjectHoomans", "client",
    "PNC/UI/CommandHub/PNC_CommandHub_SettingsWindow.lua")
local displaySettingsSource = T.read("ProjectHoomans", "client",
    "PNC/UI/Nameplates/PNC_NameplateDisplaySettings.lua")
T.contains(settingsWindowSource, "GetSurfaceOpacityLift",
    "settings does not expose surface opacity lift")
T.contains(settingsWindowSource, "GetDetailOpacityLift",
    "settings does not expose detail opacity lift")
T.contains(settingsWindowSource, "GetTitlebarControlScale",
    "settings does not expose title-bar control scale")
T.contains(settingsWindowSource, "PNC_NameplateDisplaySettings",
    "settings does not expose the Hoomans relationship display adapter")
T.contains(settingsWindowSource, "relationshipFeedbackScale",
    "settings does not expose relationship feedback size")
T.contains(settingsWindowSource, "nameplateTextScale",
    "settings does not expose nameplate text size")
T.contains(settingsWindowSource, "nameplateBarScale",
    "settings does not expose nameplate bar size")
T.contains(displaySettingsSource, "PNC.SettingsStore",
    "relationship display settings do not use the Hoomans settings store")
T.falsy(string.find(displaySettingsSource, "PsychopatzCore_CommandHub", 1, true),
    "relationship display settings leaked into the Core command-hub store")
T.contains(settingsWindowSource, "slider = row.control",
    "settings lift fields do not expose their slider contract")
T.contains(settingsWindowSource, "ApplyRegisteredToolbarScale",
    "settings does not refresh title-bar controls")
T.contains(settingsWindowSource, "Theme.GetPresetIDs",
    "settings does not expose theme presets")
T.contains(workWindowSource, "UI.CreateCheckbox",
    "work window does not create authorization checkboxes")
T.contains(workWindowSource, "authorizationPanel",
    "work window does not provide a readable authorization surface")
T.contains(workWindowSource, "job_permission_set",
    "work window does not use the server permission action")
T.contains(workWindowSource, "pendingPermissions",
    "work window does not reconcile asynchronous permission changes")
T.contains(workWindowSource, "onPriorityChanged",
    "work window does not expose numeric work priorities")
T.contains(workWindowSource, "GetContentOpacitySignature",
    "work content styling does not track appearance changes")
T.falsy(string.find(workWindowSource, "ApplySurfaceOpacity(self.peopleList, 0.04",
    1, true), "work list keeps a hardcoded opacity lift")
for _, subject in ipairs({
    "PNC/UI/Colonist/PNC_ColonistController.lua",
    "PNC/UI/Storage/PNC_StorageController.lua",
    "PNC/UI/Communities/PNC_ColonyJournalWindow.lua",
}) do
    local source = T.read("ProjectHoomans", "client", subject)
    T.contains(source, "GetContentOpacitySignature",
        subject .. " does not track appearance changes")
    T.falsy(string.find(source, "0.04", 1, true),
        subject .. " keeps a hardcoded opacity lift")
end
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
local workshopWindowSource = T.read("ProjectHoomans", "client",
    "PNC/UI/Workshop/PNC_WorkshopWindow.lua")
local workshopControllerSource = T.read("ProjectHoomans", "client",
    "PNC/UI/Workshop/PNC_WorkshopController.lua")
T.contains(workshopWindowSource, "WidgetWindow.Install",
    "workshop window does not support detachable widgets")
T.contains(workshopWindowSource, "pnc-command-hub-workshop-widget",
    "workshop window does not have a stable widget control id")
T.contains(workshopWindowSource, "PNC.CommandHub.Workshop",
    "workshop window does not persist its geometry independently")
T.contains(workshopWindowSource, "PNC.ColonyManagementClient.HasUpdate",
    "workshop window does not consume colony-management updates")
T.contains(workshopControllerSource, "Workshop.Rebuild",
    "workshop controller does not delegate its production surface")
T.contains(workshopControllerSource, "ApplyResponsiveLayout",
    "workshop controller does not expose responsive layout")
local legacyWorkshopSource = T.read("ProjectHoomans", "client",
    "PNC/UI/Communities/PNC_ColonyManagementWorkshopTab.lua")
T.contains(legacyWorkshopSource, "onclick = window.onWorkshopControl",
    "workshop controls are not compatible with the standalone window")
local workshopCommandSource = T.read("ProjectHoomans", "client",
    "PNC/UI/CommandHub/PNC_CommandHub_Workshop.lua")
T.contains(workshopCommandSource, 'childID = "workshop"',
    "workshop command provider does not identify its child branch")
T.contains(workshopCommandSource, "HasBaseAndStockpile",
    "workshop command provider lost its production gate")
T.contains(workshopCommandSource, "UI_PNC_CommandHub_WorkshopHelp",
    "workshop command provider lost its tooltip key")
T.contains(composition, "PNC/UI/CommandHub/PNC_CommandHub",
    "command hub is not in the client composition")
T.contains(composition, "PNC/UI/Research/PNC_ResearchWindow",
    "research widget is not in the client composition")
T.contains(composition, "PNC/UI/Workshop/PNC_Workshop",
    "workshop widget is not in the client composition")
T.contains(composition, "PNC/UI/Building/PNC_Building",
    "building widget is not in the client composition")
T.falsy(string.find(composition, "PNC/UI/Orders/", 1, true),
    "legacy Orders UI is still in the client composition")

local windowSource = T.read("ProjectHoomans", "client",
    "PNC/UI/CommandHub/PNC_CommandHub_Window.lua")
T.contains(windowSource, "ChildController.Toggle",
    "command hub categories are not routed through the child controller")
local coreWindowSource = T.read("PsychopatzCore", "client",
    "PsychopatzCore/UI/PsychopatzCommandHubWindow.lua")
T.contains(coreWindowSource, "syncButtonStates()",
    "command hub does not refresh disabled tooltip state")
local tooltipSource = T.read("PsychopatzCore", "client",
    "PsychopatzCore/UI/PsychopatzCommandHubTooltip.lua")
T.contains(tooltipSource, "disabledTooltip",
    "command hub does not resolve disabled tooltip reasons")
local Tooltip = T.load("PsychopatzCore", "client",
    "PsychopatzCore/UI/PsychopatzCommandHubTooltip.lua")
T.equal(Tooltip.For({ tooltipFallback = "Normal help",
    disabledTooltip = { fallback = "Disabled reason" } }, nil, false),
    "Disabled reason", "shared tooltip resolver ignores disabled reason")
T.contains(windowSource, "persistenceKey = \"PNC.CommandHub\"",
    "command hub geometry is not persisted")
T.falsy(string.find(windowSource, "PNC_CommandHub_Window_Layout", 1, true),
    "legacy command hub layout is still referenced")
T.falsy(string.find(composition, "PNC_CommandHub_ActionsWindow", 1, true),
    "legacy command hub action window is still composed")
local commandHubSource = T.read("ProjectHoomans", "client",
    "PNC/UI/CommandHub/PNC_CommandHub.lua")
local colonySource = T.read("ProjectHoomans", "client",
    "PNC/UI/CommandHub/PNC_CommandHub_Colony.lua")
T.contains(commandHubSource, "pnc-command-hub-settings-toolbar",
    "colony settings were not moved to the title toolbar")
T.contains(commandHubSource, "media/ui/MP/mp_ui_mods.png",
    "colony settings toolbar does not use the gear icon")
T.contains(commandHubSource, "Toolbar.Sync(window)",
    "colony settings toolbar is not synchronized after installation")
T.contains(commandHubSource, "PNC_CommandHub_Colony",
    "colony command provider is not in the command-hub composition")
T.contains(colonySource, 'id = "colony"',
    "colony command provider does not register its root category")
T.contains(colonySource, 'id = "provision_settings"',
    "colony command provider does not register provision settings")
T.contains(colonySource, 'id = "change_name"',
    "colony command provider does not register change name")
T.contains(colonySource, "PNC_ColonyNamePrompt",
    "change name does not use the shared colony name prompt")
T.contains(colonySource, 'mode = "rename"',
    "change name does not open the prompt in rename mode")
T.contains(colonySource, 'id = "change_emblem"',
    "colony command provider does not register change emblem")
T.contains(colonySource, "PNC_FactionEmblemEditor",
    "change emblem does not use the shared faction emblem editor")
T.contains(colonySource, "SetFactionEmblem",
    "change emblem does not preserve the authoritative save request")
T.contains(colonySource, "function Colony.Register",
    "colony command provider has no extension point for future settings")
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
T.contains(childControllerSource, 'Controller.Register("colonist"',
    "colonist window is not managed by the child controller")
T.contains(childControllerSource, "PNC.ColonistUI",
    "child controller does not manage the colonist instance")
T.contains(childControllerSource, 'Controller.Register("storage"',
    "storage window is not managed by the child controller")
T.contains(childControllerSource, "PNC.ColonyStorageUI",
    "child controller does not manage the storage instance")
T.contains(childControllerSource, 'Controller.Register("base"',
    "base window is not managed by the child controller")
T.contains(childControllerSource, "PNC.BuildingUI",
    "child controller does not manage the building instance")
T.contains(childControllerSource, 'Controller.Register("colony"',
    "colony branch is not managed by the child controller")
T.contains(childControllerSource, "PNC.ProvisionSettingsUI",
    "colony branch does not manage provision settings")
local zoneSource = T.read("ProjectHoomans", "client",
    "PNC/UI/CommandHub/PNC_CommandHub_ZoneWindow.lua")
T.contains(zoneSource, "CoreHub.Actions",
    "zone panels are not anchored to the Core action window")
local workSource = T.read("ProjectHoomans", "client",
    "PNC/UI/CommandHub/PNC_CommandHub_WorkWindow.lua")
local buildingWindowSource = T.read("ProjectHoomans", "client",
    "PNC/UI/Building/PNC_BuildingWindow.lua")
T.contains(buildingWindowSource, "WidgetWindow.Install",
    "building window does not support detached widgets")
T.contains(buildingWindowSource, "pnc-command-hub-building-widget",
    "building window does not have a stable widget control id")
T.contains(buildingWindowSource, "PNC.CommandHub.Building",
    "building window does not persist its geometry independently")
local buildingTabSource = T.read("ProjectHoomans", "client",
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagementBuildingTab.lua")
T.contains(buildingTabSource, "building_debug_get_items",
    "building surface dropped its debug material action")
T.contains(buildingTabSource, "CanUseDebug",
    "building surface dropped its debug availability gate")
local registrySource = T.read("ProjectHoomans", "client",
    "PNC/UI/CommandHub/PNC_CommandHub_Registry.lua")
T.falsy(string.find(buildingTabSource, '"build_stockpile"', 1, true),
    "stockpile bootstrap leaked into the Building child UI")
T.contains(registrySource, 'id = "stockpile"',
    "stockpile bootstrap is not registered on the root hub")
T.contains(registrySource, 'Facility.BeginBuild(owner, "stockpile")',
    "root stockpile bootstrap bypasses the facility build protocol")
T.contains(registrySource, "stockpileBootstrapVisible",
    "root stockpile bootstrap does not own one-time visibility")
T.contains(workSource, "PsychopatzCore/UI/PsychopatzCommandHubOptions",
    "work window does not consume Core options")
local settingsSource = T.read("ProjectHoomans", "client",
    "PNC/UI/CommandHub/PNC_CommandHub_SettingsWindow.lua")
T.contains(settingsSource, "PsychopatzCore/UI/PsychopatzCommandHub",
    "settings window does not consume Core services")
T.falsy(string.find(settingsSource, "PNC_CommandHub_Options", 1, true),
    "settings window still uses the removed options shim")
T.falsy(string.find(settingsSource, "UI.CreateTextEntry", 1, true),
    "settings window still exposes redundant geometry fields")
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
T.falsy(string.find(settingsSource, "ApplyGeometry", 1, true),
    "settings window still owns geometry application")
T.falsy(string.find(settingsSource, "ResetGeometry", 1, true),
    "settings reset still owns geometry reset")
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
local provisionSettingsLayoutSource = T.read("ProjectHoomans", "client",
    "PNC/UI/Provision/PNC_ProvisionSettingsWindow_Layout.lua")
T.contains(provisionSettingsSource, "WidgetWindow.Install",
    "provision settings does not support detachable widgets")
T.contains(provisionSettingsSource, "owner = owner or window.owner",
    "provision settings does not retain its command-hub owner")
T.contains(provisionSettingsLayoutSource, "Layout.Pixels",
    "provision settings layout is not scale-aware")
T.contains(provisionSettingsSource, "UI.SetLabelText(self.statusLabel",
    "provision status label can jump after text changes")
T.contains(provisionSettingsLayoutSource, "Layout.SetBounds(self.statusLabel",
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
local legacyTabsSource = T.read("ProjectHoomans", "client",
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Tabs.lua")
T.falsy(string.find(legacyTabsSource, 'id = "provision"', 1, true),
    "legacy Colony Management still exposes Provision Settings")
local legacySettingsSource = T.read("ProjectHoomans", "client",
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_SettingsTab.lua")
T.falsy(string.find(legacySettingsSource, "factionNameEntry", 1, true),
    "legacy Colony Management still exposes the inline faction name field")
T.falsy(string.find(legacySettingsSource, "factionEmblemButton", 1, true),
    "legacy Colony Management still exposes the inline faction emblem button")
T.falsy(string.find(legacyTabsSource, 'id = "workshop"', 1, true),
    "legacy Colony Management still exposes Workshop")
T.contains(childControllerSource, "function Controller.Toggle",
    "command hub child toggling is not centralized")
T.contains(childControllerSource, "function Controller.CloseAll",
    "command hub child cleanup is not centralized")

T.finish("pnc_command_hub_registry_smoke")
