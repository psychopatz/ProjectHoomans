require "PsychopatzCore/UI/PsychopatzUI"

local Shared = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"
local WorkPolicy = PNC.WorkPolicy
    or require "PNC/Core/Production/WorkDefinition/PNC_WorkPolicy"
local Jobs = {}
local UI = PsychopatzCore.UI

local DEFINITIONS = {
    { id = "Constructor", key = "UI_PNC_Job_Constructor",
        fallback = "CONSTRUCTOR" },
    { id = "Researcher", key = "UI_PNC_Job_Researcher",
        fallback = "RESEARCHER" },
    { id = "WorkshopWorker", key = "UI_PNC_Job_WorkshopWorker",
        fallback = "WORKSHOP WORKER" },
    { id = "Farmer", key = "UI_PNC_Job_Farmer", fallback = "FARMER" },
    { id = "Fishing", key = "UI_PNC_Job_Fishing", fallback = "FISHING" },
    { id = "Lumber", key = "UI_PNC_Job_Lumber", fallback = "LUMBER" },
    { id = "Provisioner", key = "UI_PNC_Job_Provisioner",
        fallback = "PROVISIONER" },
    { id = "CorpseHaul", key = "UI_PNC_Job_CorpseHaul",
        fallback = "CORPSE HAUL" },
    { id = "MedicalCare", key = "UI_PNC_Job_MedicalCare",
        fallback = "MEDICAL CARE" },
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
    window.returnHomeControl = UI.CreateButton(window, {
        id = "return_home",
        title = Shared.Tr("UI_PNC_Jobs_ReturnHome", "RETURN HOME"),
        target = window,
        onclick = ISPNCColonyManagementWindow.onJobsControl,
        variant = "quiet",
    })
    window.followMeControl = UI.CreateButton(window, {
        id = "follow_me",
        title = Shared.Tr("UI_PNC_Jobs_FollowMe", "FOLLOW ME"),
        target = window,
        onclick = ISPNCColonyManagementWindow.onJobsControl,
        variant = "quiet",
    })
    window.recoverColonistControl = UI.CreateButton(window, {
        id = "recover_colonist",
        title = Shared.Tr("UI_PNC_Jobs_Recover", "RECOVER NEAR STOCKPILE"),
        target = window,
        onclick = ISPNCColonyManagementWindow.onJobsControl,
        variant = "warning",
    })
end

function Jobs.Layout() end

function Jobs.Apply(window, active, Layout)
    for _, button in ipairs(window.jobControls or {}) do button:setVisible(active) end
    window.returnHomeControl:setVisible(active)
    window.followMeControl:setVisible(active)
    window.recoverColonistControl:setVisible(active)
    if not active or not window.layout then return end
    local rect = window.layout.details
    local gap = Layout.Pixels(6, window.uiScale)
    local height = Layout.Pixels(28, window.uiScale)
    local columns = math.min(3, #DEFINITIONS)
    local rows = math.ceil(#DEFINITIONS / columns)
    local width = math.floor((rect.width - gap * (columns - 1)) / columns)
    for index, button in ipairs(window.jobControls) do
        local column = math.fmod(index - 1, columns)
        local row = math.floor((index - 1) / columns)
        Layout.SetBounds(button, rect.x + column * (width + gap),
            rect.y + row * (height + gap), width, height)
    end
    local actionY = rect.y + rows * (height + gap)
    local actionWidth = math.floor((rect.width - gap * 2) / 3)
    Layout.SetBounds(window.returnHomeControl, rect.x, actionY,
        actionWidth, height)
    Layout.SetBounds(window.recoverColonistControl,
        rect.x + (actionWidth + gap) * 2, actionY,
        rect.width - (actionWidth + gap) * 2, height)
    Layout.SetBounds(window.followMeControl,
        rect.x + actionWidth + gap, actionY, actionWidth, height)
    local paneY = actionY + height + gap
    window:layoutPane(window.detailsPane, rect.x, paneY,
        rect.width, math.max(60, rect.height - (paneY - rect.y)))
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
    local home = person.home or {}
    local homeState = tostring(home.state or "NO_BASE")
    local homeDetails = {
        AT_CAMP = Shared.Tr("UI_PNC_Jobs_AtCampHelp",
            "AT CAMP - temporary local activities are available; colony duties remain unavailable."),
        AT_HOME = Shared.Tr("UI_PNC_Jobs_AtHomeHelp",
            "IDLE - available for colony duties."),
        RETURNING_HOME = Shared.Tr("UI_PNC_Jobs_ReturningHomeHelp",
            "RETURNING HOME - traveling through the world to the base."),
        AWAY = Shared.Tr("UI_PNC_Jobs_AwayHelp",
            "AWAY - colony duties remain unavailable until this NPC returns."),
        AWAY_FOR_WORK = Shared.Tr("UI_PNC_Jobs_AwayForWorkHelp",
            "AWAY FOR WORK - this NPC is executing a remote colony task."),
        NO_BASE = Shared.Tr("UI_PNC_Jobs_NoBaseHelp",
            "NO BASE - establish a settlement before assigning duties."),
    }
    rows[#rows + 1] = {
        key = "home_state",
        label = Shared.Tr("UI_PNC_Jobs_HomeState", "HOME STATUS"),
        detail = homeDetails[homeState] or homeState,
        colorName = (homeState == "AT_HOME" or homeState == "AT_CAMP"
            or homeState == "AWAY_FOR_WORK") and "success"
            or homeState == "RETURNING_HOME" and "warning" or "muted",
    }
    for _, definition in ipairs(DEFINITIONS) do
        local priority = WorkPolicy.GetPriority(person, definition.id)
        local enabled = priority > WorkPolicy.MIN_PRIORITY
        local button = window.jobControls and window.jobControls[definition.id]
        if button then
            button:setTitle(Shared.Tr(definition.key, definition.fallback)
                .. (enabled and "  P" .. tostring(priority) or "  OFF"))
            UI.SetButtonVariant(button, enabled and "success" or "quiet")
        end
        rows[#rows + 1] = {
            key = definition.id,
            label = Shared.Tr(definition.key, definition.fallback),
            detail = enabled
                and Shared.Tr("UI_PNC_Jobs_AllowedHelp",
                    "ALLOWED - priority " .. tostring(priority)
                        .. " (1 is highest; 4 is lowest).")
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
    if not person then return false end
    if job == "return_home" then
        return PNC.Client.RequestColonyAction("colonist_return_home", {
            npcID = person.id,
        })
    end
    if job == "follow_me" then
        return PNC.Client.RequestColonyAction("colonist_follow_player", {
            npcID = person.id,
        })
    end
    if job == "recover_colonist" then
        return PNC.Client.RequestColonyAction("colonist_recover", {
            npcID = person.id,
        })
    end
    if not window.jobControls[job] then return false end
    local previous = WorkPolicy.GetPriority(person, job)
    local priority = previous > WorkPolicy.MIN_PRIORITY
        and WorkPolicy.MIN_PRIORITY or WorkPolicy.DEFAULT_PRIORITY
    WorkPolicy.SetPriority(person, job, priority)
    local requestId = PNC.ColonyManagementClient
        and PNC.ColonyManagementClient.QueueWorkPolicy
        and PNC.ColonyManagementClient.QueueWorkPolicy(
            person.id, job, priority) or nil
    local ok = PNC.Client.RequestColonyAction("job_permission_set", {
        npcID = person.id, job = job,
        priority = priority,
        enabled = priority > WorkPolicy.MIN_PRIORITY,
        requestId = requestId,
    })
    if ok == false then
        WorkPolicy.SetPriority(person, job, previous)
        if PNC.ColonyManagementClient
            and PNC.ColonyManagementClient.ClearWorkPolicy
        then
            PNC.ColonyManagementClient.ClearWorkPolicy(person.id, job)
        end
    end
    return ok
end

return Jobs
