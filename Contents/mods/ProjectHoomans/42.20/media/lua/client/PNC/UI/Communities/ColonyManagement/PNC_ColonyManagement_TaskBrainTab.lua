local Presentation = require
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_TaskBrainPresentation"

local Brain = {}

function Brain.BuildRows(context)
    return Presentation.BuildRows(context.selectedPerson, context.window)
end

function Brain.OnRow(window, row)
    return Presentation.OnRow(window, row)
end

return Brain
