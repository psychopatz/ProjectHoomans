require "PsychopatzCore/UI/PsychopatzUI"

local Shared = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"
local Jobs = {}
local UI = PsychopatzCore.UI

local DEFINITIONS = {
    { id = "Constructor", key = "UI_PNC_Job_Constructor",
        fallback = "CONSTRUCTOR" },
    { id = "Researcher", key = "UI_PNC_Job_Researcher",
        fallback = "RESEARCHER" },
    { id = "WorkshopWorker", key = "UI_PNC_Job_WorkshopWorker",
        fallback = "WORKSHOP WORKER" },
}

function Jobs.Create(window)
    window.jobControls = {}
    for _, definition in ipairs(DEFINITIONS) do
        local button = UI.CreateButton(window, {
            id = definition.id,
            title = Shared.Tr(definition.key, definition.fallback),
            target = window,
            onclick = ISPNCColonyManagementWindow.onJobsControl,
            variant = "quiet",
        })
        window.jobControls[#window.jobControls + 1] = button
        window.jobControls[definition.id] = button
    end
end

function Jobs.Layout() end

function Jobs.Apply(window, active, Layout)
    for _, button in ipairs(window.jobControls or {}) do button:setVisible(active) end
    if not active or not window.layout then return end
    local rect = window.layout.details
    local gap = Layout.Pixels(6, window.uiScale)
    local height = Layout.Pixels(28, window.uiScale)
    local width = math.floor((rect.width - gap * (#DEFINITIONS - 1))
        / #DEFINITIONS)
    for index, button in ipairs(window.jobControls) do
        Layout.SetBounds(button, rect.x + (index - 1) * (width + gap),
            rect.y, width, height)
    end
    window:layoutPane(window.detailsPane, rect.x, rect.y + height + gap,
        rect.width, math.max(60, rect.height - height - gap))
end

function Jobs.BuildRows(context)
    local person = context.selectedPerson
    local window = context.window
    if not person then
        return {{ key = "jobs_empty",
            label = Shared.Tr("UI_PNC_Jobs_Select", "SELECT A COLONIST"),
            detail = Shared.Tr("UI_PNC_Jobs_Help",
                "Choose a colonist to configure their allowed work.") }}
    end
    local rows = {}
    for _, definition in ipairs(DEFINITIONS) do
        local enabled = not person.allowedJobs
            or person.allowedJobs[definition.id] ~= false
        local button = window.jobControls and window.jobControls[definition.id]
        if button then
            button:setTitle(Shared.Tr(definition.key, definition.fallback)
                .. (enabled and "  ON" or "  OFF"))
            UI.SetButtonVariant(button, enabled and "success" or "quiet")
        end
        rows[#rows + 1] = {
            key = definition.id,
            label = Shared.Tr(definition.key, definition.fallback),
            detail = enabled
                and Shared.Tr("UI_PNC_Jobs_AllowedHelp",
                    "ALLOWED - this NPC may automatically claim this work.")
                or Shared.Tr("UI_PNC_Jobs_DisabledHelp",
                    "DISABLED - this NPC will not claim this work."),
            colorName = enabled and "success" or "warning",
        }
    end
    return rows
end

function Jobs.OnControl(window, button)
    local person = Shared.ListValue(window.people)
    local job = tostring(button and button.internal or "")
    if not person or not window.jobControls[job] then return false end
    local enabled = not person.allowedJobs or person.allowedJobs[job] ~= false
    return PNC.Client.RequestColonyAction("job_permission_set", {
        npcID = person.id, job = job, enabled = not enabled,
    })
end

return Jobs
