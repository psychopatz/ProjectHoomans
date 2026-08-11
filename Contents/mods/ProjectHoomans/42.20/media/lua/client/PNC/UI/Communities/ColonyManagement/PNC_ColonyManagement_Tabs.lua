local Registry = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Registry"
local Presentation = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Presentation"
local Storage = require "PNC/UI/Communities/PNC_ColonyManagementStorageTabs"
local Research = require "PNC/UI/Communities/PNC_ColonyManagementResearchTab"
local Shared = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"
local DebugTab = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_DebugTab"

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
    id = "needs",
    title = "NEEDS",
    detailTitle = "NEEDS OVERVIEW",
    showRoster = true,
    buildRows = function(context)
        return Presentation.BuildNeeds(context.selectedPerson)
    end,
})

Registry.Register({
    id = "storage",
    title = "STORAGE",
    detailTitle = "DEBUG DETAILS",
    showRoster = false,
    showDetails = false,
    create = function(window, UI)
        Storage.Create(window, UI, Shared.Tr)
    end,
    layout = function(window, Layout, content)
        Storage.Layout(window, Layout, content)
    end,
    apply = function(window, active, Layout)
        Storage.ApplyLayout(window, Layout, active)
    end,
    rebuild = function(window, snapshot)
        return Storage.Rebuild(window, snapshot, Shared.Tr)
    end,
    render = function(window, Theme)
        if not window.layout then return end
        window:drawSectionTitle("GENERAL STOCKPILE", window.storageList)
        Storage.RenderSummary(window, Theme)
    end,
})

Registry.Register({
    id = "research",
    title = "RESEARCH",
    detailTitle = "COLONY RESEARCH",
    showRoster = false,
    showDetails = true,
    create = function(window, UI)
        Research.Create(window, UI, Shared.Tr)
    end,
    layout = function(window, Layout, content)
        Research.Layout(window, Layout, content)
    end,
    apply = function(window, active, Layout)
        Research.ApplyVisibility(window, active, Layout)
    end,
    rebuild = function(window, snapshot)
        return Research.Rebuild(window, snapshot, Shared.Tr)
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
                context.selectedPerson, context.snapshot
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
