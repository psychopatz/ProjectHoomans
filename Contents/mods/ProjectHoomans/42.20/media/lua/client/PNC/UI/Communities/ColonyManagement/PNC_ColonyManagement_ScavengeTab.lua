require "PsychopatzCore/UI/PsychopatzUI"

local Controller = require "PNC/Scavenge/PNC_ScavengeController"
local Components = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Components"
local Presentation = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Presentation"
local Shared = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"

PNC = PNC or {}
PNC.ColonyScavengeTab = PNC.ColonyScavengeTab or {}

local Tab = PNC.ColonyScavengeTab
local UI = PsychopatzCore.UI

local function cachedSnapshot()
    local state = PNC.Network and PNC.Network.ClientState or nil
    local sessionId = state and state.activeScavengeSessionId or nil
    return sessionId and state.scavengeSessions
        and state.scavengeSessions[sessionId] or nil
end

local function ensureTeam(window)
    local snapshot = cachedSnapshot()
    Controller.SeedTeam(snapshot and snapshot.npcIds or {})
    window.scavengeTeam = Controller.Team
    return Controller.Team
end

local function followerRoster(window)
    local rows = {}
    local team = ensureTeam(window)
    for _, row in ipairs(Presentation.BuildRoster(window.snapshot)) do
        local assigned = team[tostring(row.id)] == true
        if row.value and (row.value.followingCurrentPlayer == true
            or assigned)
        then
            row.label = (assigned and "[X] " or "[ ] ") .. row.label
            row.detail = assigned and Shared.Tr(
                "UI_PNC_Scavenge_Assigned", "ON SCAVENGING RUN")
                or Shared.Tr("UI_PNC_Scavenge_Available",
                    "AVAILABLE TO ASSIGN")
            rows[#rows + 1] = row
        end
    end
    return rows
end

local function syncAssignmentControl(window)
    local button = window.scavengeAssignControl
    if not button then return end
    local person = Shared.ListValue(window.people)
    local assigned = person and ensureTeam(window)[tostring(person.id)] == true
        or false
    if button.setToggleState then button:setToggleState(assigned) end
    if button.setEnable then button:setEnable(person ~= nil) end
end

local function bindRoster(window)
    local selectedID = window.selectedPersonID
    local rows = followerRoster(window)
    local selectedIndex
    Components.SetRows(window.people, rows)
    for index, row in ipairs(rows) do
        if tostring(row.id) == tostring(selectedID) then selectedIndex = index end
    end
    if #rows > 0 then
        window.people.selected = selectedIndex or 1
        local person = Shared.ListValue(window.people)
        window.selectedPersonID = person and person.id or nil
    else
        window.people.selected = 0
        window.selectedPersonID = nil
    end
    window.peoplePane:setHeader(Shared.Tr(
        "UI_PNC_Scavenge_Followers", "FOLLOWERS / ASSIGNED"), #rows)
    syncAssignmentControl(window)
end

local function teamIDs(window)
    ensureTeam(window)
    return Controller.TeamIDs()
end

function Tab.Create(window)
    ensureTeam(window)
    window.scavengeAssignControl = UI.CreateToggleButton(window, {
        id = "toggle_scavenger",
        offTitle = Shared.Tr("UI_PNC_Scavenge_Assign", "ASSIGN SCAVENGER"),
        onTitle = Shared.Tr("UI_PNC_Scavenge_Remove", "REMOVE SCAVENGER"),
        target = window,
        onclick = ISPNCColonyManagementWindow.onScavengeControl,
        offVariant = "quiet",
        onVariant = "warning",
    })
    window.scavengeOpenControl = UI.CreateButton(window, {
        id = "open_scavenge",
        title = Shared.Tr("UI_PNC_Scavenge_Open", "OPEN SCAVENGING UI"),
        target = window,
        onclick = ISPNCColonyManagementWindow.onScavengeControl,
        variant = "primary",
    })
end

function Tab.Layout() end

function Tab.Apply(window, active, Layout)
    window.scavengeAssignControl:setVisible(active)
    window.scavengeOpenControl:setVisible(active)
    if not active then return end
    bindRoster(window)
    if not window.layout then return end
    local rect = window.layout.details
    local gap = Layout.Pixels(6, window.uiScale)
    local height = Layout.Pixels(28, window.uiScale)
    local width = math.floor((rect.width - gap) / 2)
    Layout.SetBounds(window.scavengeAssignControl,
        rect.x, rect.y, width, height)
    Layout.SetBounds(window.scavengeOpenControl,
        rect.x + width + gap, rect.y,
        rect.width - width - gap, height)
    local paneY = rect.y + height + gap
    window:layoutPane(window.detailsPane, rect.x, paneY,
        rect.width, math.max(60, rect.height - (paneY - rect.y)))
end

function Tab.BuildRows(context)
    local window = context.window
    local person = context.selectedPerson
    local ids = teamIDs(window)
    local rows = {
        Presentation.Detail(Shared.Tr(
            "UI_PNC_Scavenge_Team", "SCAVENGING TEAM"),
            tostring(#ids) .. " " .. Shared.Tr(
                "UI_PNC_Scavenge_Selected", "SELECTED"), "accent"),
    }
    if not person then
        rows[#rows + 1] = Presentation.Detail(Shared.Tr(
            "UI_PNC_Scavenge_NoFollowers", "NO FOLLOWERS AVAILABLE"),
            Shared.Tr("UI_PNC_Scavenge_NoFollowersHelp",
                "Ask an NPC to follow you before assigning them."), "warning")
        return rows
    end
    local assigned = ensureTeam(window)[tostring(person.id)] == true
    rows[#rows + 1] = Presentation.Detail(
        tostring(person.name or person.id), assigned and Shared.Tr(
            "UI_PNC_Scavenge_Assigned", "ON SCAVENGING RUN")
            or Shared.Tr("UI_PNC_Scavenge_Available",
                "AVAILABLE TO ASSIGN"), assigned and "success" or "muted")
    rows[#rows + 1] = Presentation.Detail(Shared.Tr(
        "UI_PNC_Scavenge_Workflow", "WORKFLOW"), Shared.Tr(
            "UI_PNC_Scavenge_WorkflowHelp",
            "Choose the team here, then open the scavenging UI to run it."))
    return rows
end

function Tab.OnPersonSelected(window)
    local person = Shared.ListValue(window.people)
    window.selectedPersonID = person and person.id or nil
    syncAssignmentControl(window)
    return person ~= nil
end

function Tab.OnControl(window, button)
    local action = tostring(button and button.internal or "")
    local person = Shared.ListValue(window.people)
    if action == "toggle_scavenger" then
        if not person then return false end
        local id = tostring(person.id)
        local team = ensureTeam(window)
        if team[id] ~= true and person.followingCurrentPlayer ~= true then
            return false
        end
        return Controller.SetAssigned(id, team[id] ~= true)
    end
    if action == "open_scavenge" then
        local ids = teamIDs(window)
        if #ids < 1 then return false end
        local leadId = ids[1]
        return Controller.Open(leadId, {
                npcIds = ids,
                name = tostring(#ids) .. " scavengers",
            })
    end
    return false
end


function Tab.ReceiveSnapshot(payload)
    local window = PNC.ColonyManagementUI
        and PNC.ColonyManagementUI.instance or nil
    if not window or not payload or payload.requestFailed == true then
        return false
    end
    window.scavengeTeam = Controller.Team
    if window.tab == "scavenge" then
        bindRoster(window)
        window:rebuildDetails()
    end
    return true
end

if not Tab.teamListenerInstalled then
    Tab.teamListenerInstalled = Controller.OnTeamChanged(function()
        local window = PNC.ColonyManagementUI
            and PNC.ColonyManagementUI.instance or nil
        if not window or window.tab ~= "scavenge" then return end
        window.scavengeTeam = Controller.Team
        bindRoster(window)
        window:rebuildDetails()
    end)
end

return Tab
