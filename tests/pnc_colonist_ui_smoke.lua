local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "client" },
    { "ProjectHoomans", "shared" },
})

PNC = {}
local Registry = T.load("ProjectHoomans", "client",
    "PNC/UI/Colonist/PNC_ColonistRegistry.lua")

local late = Registry.Register({ id = "future", order = 30 })
local first = Registry.Register({ id = "needs", order = 10 })
local middle = Registry.Register({ id = "skills", order = 20 })
T.truthy(late, "future colonist tab registration failed")
T.truthy(first, "needs colonist tab registration failed")
T.truthy(middle, "second colonist tab registration failed")
T.falsy(Registry.Register({ id = "needs", order = 5 }),
    "duplicate colonist tab registration was accepted")
T.equal(Registry.All()[1].id, "needs", "colonist tabs ignore explicit order")
T.equal(Registry.All()[2].id, "skills", "colonist tabs are not sorted")
T.equal(Registry.All()[3].id, "future", "colonist tab order is unstable")
T.equal(Registry.Get("skills"), Registry.All()[2],
    "colonist tab lookup is not canonical")
T.truthy(PNC.ColonistUI.RegisterTab,
    "colonist injection API is not exposed")

local registrySource = T.read("ProjectHoomans", "client",
    "PNC/UI/Colonist/PNC_ColonistRegistry.lua")
local tabsSource = T.read("ProjectHoomans", "client",
    "PNC/UI/Colonist/PNC_ColonistTabs.lua")
local controllerSource = T.read("ProjectHoomans", "client",
    "PNC/UI/Colonist/PNC_ColonistController.lua")
local selectorSource = T.read("ProjectHoomans", "client",
    "PNC/UI/Colonist/PNC_ColonistSelector.lua")
local windowSource = T.read("ProjectHoomans", "client",
    "PNC/UI/Colonist/PNC_ColonistWindow.lua")
local compositionSource = T.read("ProjectHoomans", "client",
    "PNC/Composition/PNC_ClientComposition.lua")
T.contains(registrySource, "Registry.Revision",
    "colonist registry has no dynamic injection revision")
T.contains(controllerSource, "Selector.Create",
    "colonist shell has no reusable roster selector")
T.contains(selectorSource, "ActivityPresentation.Current",
    "colonist selector does not use canonical activity information")
T.contains(selectorSource, "PNC_ColonistActivityPresentation",
    "colonist selector does not import the activity formatter")
T.contains(controllerSource, "SyncTabComponents",
    "colonist shell cannot initialize injected tab components")
T.contains(tabsSource, "Presentation.BuildNeeds",
    "colonist needs tab does not use the tested needs presentation")
T.contains(tabsSource, 'id = "activities"',
    "colonist activities tab is not registered")
T.contains(tabsSource, 'id = "task"',
    "colonist task tab is not registered in the target UI")
T.contains(tabsSource, "PNC/UI/Colonist/PNC_ColonistTask",
    "colonist task tab imports the wrong presentation path")
T.contains(controllerSource, "selectedPersonID",
    "colonist selection identity is not persisted")
T.contains(controllerSource, "Options.ApplySurfaceOpacity",
    "colonist panes do not follow command-hub content opacity")
T.contains(windowSource, "WidgetWindow.Install",
    "colonist window has no reusable widget lifecycle")
T.contains(windowSource, "Client.HasUpdate",
    "colonist window bypasses the snapshot update boundary")
T.contains(windowSource, "taskBrainNpcID",
    "colonist task tab does not request the selected NPC brain")
T.contains(windowSource, "persistenceKey = \"PNC.CommandHub.Colonist\"",
    "colonist window geometry is not persisted")
T.contains(compositionSource, "PNC/UI/Colonist/PNC_Colonist",
    "colonist menu is missing from client composition")

T.finish("pnc_colonist_ui_smoke")
