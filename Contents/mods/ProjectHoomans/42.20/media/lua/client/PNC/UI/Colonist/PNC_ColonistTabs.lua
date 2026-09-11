local Registry = require "PNC/UI/Colonist/PNC_ColonistRegistry"
local Activities = require "PNC/UI/Colonist/PNC_ColonistActivities"
local Debug = require "PNC/UI/Colonist/PNC_ColonistDebug"
local Task = require "PNC/UI/Colonist/PNC_ColonistTask"
local Presentation = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Presentation"

-- The first tab deliberately delegates to the tested colony-management needs
-- presentation.  Future tabs only need to register another definition; the
-- window shell, roster, selection persistence, and snapshot lifecycle stay
-- unchanged.
Registry.Register({
    id = "needs",
    order = 10,
    titleKey = "UI_PNC_Colonist_Needs_Tab",
    titleFallback = "NEEDS",
    detailTitleKey = "UI_PNC_Colonist_Needs_Title",
    detailTitleFallback = "NEEDS OVERVIEW",
    buildRows = function(context)
        return Presentation.BuildNeeds(context.selectedPerson)
    end,
})

Registry.Register({
    id = "activities",
    order = 20,
    titleKey = "UI_PNC_Activities_Tab",
    titleFallback = "ACTIVITIES",
    detailTitleKey = "UI_PNC_Activities_Title",
    detailTitleFallback = "ACTIVITY STATUS",
    create = function(window, UI)
        return Activities.Create(window, UI)
    end,
    getControlsHeight = function(window, width, Layout, component)
        return Activities.GetControlsHeight(window, width, Layout, component)
    end,
    apply = function(window, active, Layout, component)
        Activities.Apply(window, active, Layout, component)
    end,
    buildRows = function(context)
        return Activities.BuildRows(context)
    end,
    onPersonSelected = function(window, person, component)
        return Activities.OnPersonSelected(window, person, component)
    end,
    onControl = function(window, button)
        return Activities.OnControl(window, button)
    end,
})

Registry.Register({
    id = "task",
    order = 30,
    titleKey = "UI_PNC_Task_Tab",
    titleFallback = "TASK",
    detailTitleKey = "UI_PNC_TaskBrain_Title",
    detailTitleFallback = "COLONIST TASK BRAIN",
    buildRows = function(context)
        return Task.BuildRows(context)
    end,
    onRow = function(window, row)
        return Task.OnRow(window, row)
    end,
})

Registry.Register({
    id = "debug",
    order = 40,
    titleKey = "UI_PNC_ColonyDebug_Tab",
    titleFallback = "DEBUG",
    detailTitleKey = "UI_PNC_ColonyDebug_Title",
    detailTitleFallback = "COLONIST DEBUG",
    available = function()
        return Debug.IsAvailable()
    end,
    create = function(window, UI)
        return Debug.Create(window, UI)
    end,
    getControlsHeight = function(window, width, Layout, component)
        return Debug.GetControlsHeight(window, width, Layout, component)
    end,
    apply = function(window, active, Layout, component)
        Debug.Apply(window, active, Layout, component)
    end,
    buildRows = function(context)
        return Debug.BuildRows(
            context.selectedPerson, context.snapshot, context.window,
            context.component)
    end,
    onPersonSelected = function(window, person, component)
        return Debug.OnPersonSelected(window, person, component)
    end,
    onControl = function(window, button, component)
        return Debug.OnControl(window, button, component)
    end,
})

return Registry
