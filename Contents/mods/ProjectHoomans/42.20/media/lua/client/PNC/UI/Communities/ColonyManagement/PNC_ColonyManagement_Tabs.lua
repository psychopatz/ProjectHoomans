local Registry = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Registry"
local Presentation = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Presentation"
local Workshop = require "PNC/UI/Communities/PNC_ColonyManagementWorkshopTab"
local Building = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagementBuildingTab"
local Shared = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"
local DebugTab = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_DebugTab"
local BaseTab = require "PNC/UI/Communities/ColonyManagement/SettlementManagement/PNC_SettlementManagement_Tab"
local SettingsTab = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_SettingsTab"
local JobsTab = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_JobsTab"
local ScavengeTab = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_ScavengeTab"
local TasksTab = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_TasksTab"
local UtilitiesTab = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_UtilitiesTab"

Registry.Register({
    id = "overview",
    title = "OVERVIEW",
    detailTitle = "COLONY STATUS",
    showRoster = true,
    buildRows = function(context)
        return Presentation.BuildOverview(context.snapshot)
    end,
})

Registry.Register({
    id = "people",
    title = "PEOPLE",
    detailTitle = "COMPANION DETAILS",
    showRoster = true,
    buildRows = function(context)
        return Presentation.BuildPeople(context.selectedPerson)
    end,
})

Registry.Register({
    id = "base",
    title = function()
        return Shared.Tr("UI_PNC_Base_Tab", "BASE")
    end,
    detailTitle = "SETTLEMENT & FACILITIES",
    showRoster = false,
    showDetails = false,
    create = function(window, UI)
        BaseTab.Create(window, UI)
    end,
    layout = function(window, Layout, content)
        BaseTab.Layout(window, Layout, content)
    end,
    apply = function(window, active)
        BaseTab.Apply(window, active)
    end,
    rebuild = function(window, snapshot)
        return BaseTab.Rebuild(window, snapshot)
    end,
    onControl = function(window, button)
        return BaseTab.OnControl(window, button)
    end,
})

Registry.Register({
    id = "needs",
    title = "NEEDS",
    detailTitle = "NEEDS OVERVIEW",
    showRoster = true,
    buildRows = function(context)
        return Presentation.BuildNeeds(context.selectedPerson)
    end,
})

Registry.Register({
    id = "jobs",
    title = function() return Shared.Tr("UI_PNC_Jobs_Tab", "JOBS") end,
    detailTitle = "COLONIST JOB PERMISSIONS",
    showRoster = true,
    showDetails = true,
    create = function(window) JobsTab.Create(window) end,
    layout = function(window, Layout, content)
        JobsTab.Layout(window, Layout, content)
    end,
    apply = function(window, active, Layout)
        JobsTab.Apply(window, active, Layout)
    end,
    buildRows = function(context) return JobsTab.BuildRows(context) end,
    onControl = function(window, button)
        return JobsTab.OnControl(window, button)
    end,
})

Registry.Register({
    id = "tasks",
    title = function() return Shared.Tr("UI_PNC_Tasks_Tab", "TASKS") end,
    detailTitle = "AVAILABLE COLONY TASKS",
    showRoster = false,
    showDetails = true,
    buildRows = function(context) return TasksTab.BuildRows(context) end,
    onRow = function(window, row)
        return TasksTab.OnRow(window, row)
    end,
})

Registry.Register({
    id = "scavenge",
    title = function()
        return Shared.Tr("UI_PNC_Scavenge_Tab", "SCAVENGE")
    end,
    detailTitle = "SCAVENGING RUN",
    showRoster = true,
    showDetails = true,
    create = function(window) ScavengeTab.Create(window) end,
    layout = function(window, Layout, content)
        ScavengeTab.Layout(window, Layout, content)
    end,
    apply = function(window, active, Layout)
        ScavengeTab.Apply(window, active, Layout)
    end,
    buildRows = function(context)
        return ScavengeTab.BuildRows(context)
    end,
    onPersonSelected = function(window)
        return ScavengeTab.OnPersonSelected(window)
    end,
    onControl = function(window, button)
        return ScavengeTab.OnControl(window, button)
    end,
})

Registry.Register({
    id = "settings",
    title = function()
        return Shared.Tr("UI_PNC_ColonySettings_Tab", "SETTINGS")
    end,
    detailTitle = "COLONY SETTINGS",
    showRoster = false,
    showDetails = true,
    create = function(window)
        SettingsTab.Create(window)
    end,
    layout = function(window, Layout, content)
        SettingsTab.Layout(window, Layout, content)
    end,
    apply = function(window, active, Layout)
        SettingsTab.Apply(window, active, Layout)
    end,
    rebuild = function(window, snapshot)
        return SettingsTab.Rebuild(window, snapshot)
    end,
    onControl = function(window, button)
        return SettingsTab.OnControl(window, button)
    end,
})

Registry.Register({
    id = "utilities",
    title = function() return Shared.Tr("UI_PNC_Utilities_Tab", "UTILITIES") end,
    detailTitle = "COLONY UTILITIES",
    showRoster = false,
    showDetails = true,
    buildRows = function(context) return UtilitiesTab.BuildRows(context) end,
})

Registry.Register({
    id = "research",
    title = "RESEARCH",
    detailTitle = "COLONY RESEARCH",
    showRoster = false,
    showDetails = false,
    -- Research is now a detachable Command Hub widget. Keep the legacy tab
    -- as a compatibility entry point so existing callers reach the same UI.
    action = function(window)
        local research = PNC.ResearchUI
        if research and research.Toggle then
            return research.Toggle(window)
        end
        return false
    end,
})

Registry.Register({
    id = "workshop",
    title = "WORKSHOP",
    detailTitle = "COLONY PRODUCTION",
    showRoster = false,
    showDetails = true,
    create = function(window, UI) Workshop.Create(window, UI, Shared.Tr) end,
    layout = function(window, Layout, content)
        Workshop.Layout(window, Layout, content)
    end,
    apply = function(window, active, Layout)
        Workshop.Apply(window, active, Layout)
    end,
    rebuild = function(window, snapshot)
        return Workshop.Rebuild(window, snapshot, Shared.Tr)
    end,
})

Registry.Register({
    id = "building",
    title = "BUILDING",
    detailTitle = "COLONY BUILDING",
    showRoster = false,
    showDetails = true,
    create = function(window, UIBuilder)
        Building.Create(window, UIBuilder)
    end,
    layout = function(window, Layout, content)
        Building.Layout(window, Layout, content)
    end,
    apply = function(window, active)
        Building.Apply(window, active)
    end,
    rebuild = function(window, snapshot)
        return Building.Rebuild(window, snapshot)
    end,
    onControl = function(window, button)
        return Building.OnControl(window, button)
    end,
})

if PNC.Client and PNC.Client.CanUseDebug and PNC.Client.CanUseDebug() then
    Registry.Register({
        id = "debug",
        title = function()
            return Shared.Tr("UI_PNC_ColonyDebug_Tab", "DEBUG")
        end,
        detailTitle = "COLONIST DEBUG",
        showRoster = true,
        create = function(window)
            DebugTab.Create(window)
        end,
        apply = function(window, active)
            DebugTab.Apply(window, active)
        end,
        buildRows = function(context)
            return DebugTab.BuildRows(
                context.selectedPerson, context.snapshot, context.window
            )
        end,
        onControl = function(window, button)
            return DebugTab.OnControl(window, button)
        end,
    })
end

Registry.Register({
    id = "refresh",
    title = function()
        return Shared.Tr(Shared.REFRESH_LABEL_KEY, "REFRESH")
    end,
    selectable = false,
    action = function(window)
        window:manualRefresh()
    end,
})

Registry.Register({
    id = "provision",
    title = function()
        return Shared.Tr("UI_PNC_Provision_Open", "PROVISION SETTINGS")
    end,
    selectable = false,
    action = function()
        if PNC.ProvisionSettingsUI then PNC.ProvisionSettingsUI.Open() end
    end,
})

return Registry
