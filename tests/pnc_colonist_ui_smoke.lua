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
local activitiesSource = T.read("ProjectHoomans", "client",
    "PNC/UI/Colonist/PNC_ColonistActivities.lua")
local selectorSource = T.read("ProjectHoomans", "client",
    "PNC/UI/Colonist/PNC_ColonistSelector.lua")
local windowSource = T.read("ProjectHoomans", "client",
    "PNC/UI/Colonist/PNC_ColonistWindow.lua")
local hubSource = T.read("ProjectHoomans", "client",
    "PNC/Integrations/PNC_PsychopatzCoreDebug.lua")
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
T.contains(controllerSource, "activeTabControlsPane",
    "colonist shell does not activate a tab-owned controls pane")
T.falsy(controllerSource:find("tabControlsPane", 1, true),
    "colonist shell still owns a shared controls pane")
T.falsy(activitiesSource:find("window.tabControlsPane", 1, true),
    "activities tab still depends on the shared controls pane")
T.contains(tabsSource, "Presentation.BuildNeeds",
    "colonist needs tab does not use the tested needs presentation")
T.contains(tabsSource, 'id = "activities"',
    "colonist activities tab is not registered")
T.contains(tabsSource, 'id = "task"',
    "colonist task tab is not registered in the target UI")
T.contains(tabsSource, 'id = "debug"',
    "colonist debug tab is not registered in the target UI")
T.contains(tabsSource, "Debug.IsAvailable",
    "colonist debug tab has no authorization gate")
T.contains(tabsSource, "PNC/UI/Colonist/PNC_ColonistTask",
    "colonist task tab imports the wrong presentation path")
T.contains(controllerSource, "selectedPersonID",
    "colonist selection identity is not persisted")
T.contains(controllerSource, "tabAvailabilitySignature",
    "colonist tabs do not react to authorization changes")
T.contains(controllerSource, "isAvailable(definition, window)",
    "colonist controller does not filter unavailable tabs")
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
T.contains(windowSource, "Controller.SyncTabs(self)",
    "colonist window does not refresh tab authorization")
T.contains(windowSource, "function ColonistUI.OpenDebug",
    "debug hub has no Colonist DEBUG opener")
T.contains(hubSource, "PNC.ColonistUI.OpenDebug",
    "debug hub still targets the removed standalone needs window")
T.falsy(hubSource:find("PNC.NeedsDebugUI.Toggle", 1, true),
    "debug hub still invokes the removed standalone needs window")
T.contains(compositionSource, "PNC/UI/Colonist/PNC_Colonist",
    "colonist menu is missing from client composition")
T.falsy(compositionSource:find("PNC/UI/Needs/PNC_NeedsDebugWindow", 1, true),
    "legacy needs debug window is still loaded in client composition")

T.finish("pnc_colonist_ui_smoke")
