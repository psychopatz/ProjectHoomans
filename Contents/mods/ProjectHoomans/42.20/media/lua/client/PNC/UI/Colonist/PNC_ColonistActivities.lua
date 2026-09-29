require "PsychopatzCore/UI/PsychopatzUI"
require "ISUI/ISPanel"

local Presentation = require "PNC/UI/Shared/PNC_ColonyPresentation"
local JournalPresentation = require "PNC/UI/Communities/PNC_ColonistJournalPresentation"
local Selector = require "PNC/UI/Colonist/PNC_ColonistSelector"
local Shared = require "PNC/UI/Shared/PNC_ColonyUIShared"

local Activities = {}
local UI = PsychopatzCore.UI
local Layout = UI.Layout

local DEFINITIONS = {
    {
        -- Single control for the two movement orders a player issues constantly.
        -- It reads the colonist's follow state and offers the opposite order, so
        -- recalling someone from the base is one click instead of a menu hunt.
        id = "radio_follow_toggle",
        toggle = true,
        followCommandID = "follow",
        homeCommandID = "return_home",
        offTitleKey = "UI_PNC_CommandFollow",
        offTitleFallback = "FOLLOW ME",
        offVariant = "primary",
        onTitleKey = "UI_PNC_CommandReturnHome",
        onTitleFallback = "GO HOME",
        onVariant = "selected",
    },
    {
        id = "manual_eat",
        capabilities = { "survival.eat.inventory", "food.dine" },
        key = "UI_PNC_CommandEat",
        fallback = "EAT",
    },
    {
        id = "manual_drink",
        capabilities = { "survival.drink.inventory", "survival.drink.world" },
        key = "UI_PNC_CommandDrink",
        fallback = "DRINK",
    },
    {
        id = "manual_refill",
        capabilities = { "survival.fill.water" },
        key = "UI_PNC_CommandRefillWater",
        fallback = "REFILL WATER",
    },
    {
        id = "manual_sleep",
        capabilities = { "sleep" },
        key = "UI_PNC_CommandSleep",
        fallback = "SLEEP",
    },
    {
        id = "manual_provision",
        operation = "PROVISION_PICKUP",
        key = "UI_PNC_CommandProvision",
        fallback = "GRAB PROVISION",
    },
    {
        id = "manual_corpse_haul",
        operation = "CORPSE_HAUL",
        key = "UI_PNC_CommandCorpseHaul",
        fallback = "GRAB CORPSES",
    },
}

Activities.Definitions = DEFINITIONS

local BY_ID = {}
for _, definition in ipairs(DEFINITIONS) do
    BY_ID[definition.id] = definition
end

local TOGGLE = BY_ID.radio_follow_toggle

local function livePlayer()
    return getSpecificPlayer and getSpecificPlayer(0) or nil
end

-- Mirrors the authority's radio verdict by reusing the same device check the
-- radio UI and discovery broadcasts already depend on.
local function playerRadioActive()
    local deviceState = PsychopatzCore and PsychopatzCore.RadioDeviceState or nil
    local player = livePlayer()
    if not deviceState or type(deviceState.FindActivePlayerDevice) ~= "function"
        or not player
    then
        return false
    end
    local ok, device = pcall(deviceState.FindActivePlayerDevice, player)
    return ok and device ~= nil
end

-- A colonist is only "commandable in person" while materialized and standing
-- within the companion command radius on the same floor, which is exactly what
-- Commands.CanPlayerCommand enforces server-side.
local function reachableDirectly(person)
    local player = livePlayer()
    local location = person and person.location or nil
    local live = tostring(PNC.Const and PNC.Const.PRESENCE_LIVE or "live")
    local x, y, z, distanceSq, radius
    if not player or not location then return false end
    if tostring(person.presenceState or "") ~= live then return false end
    x, y, z = tonumber(location.x), tonumber(location.y), tonumber(location.z)
    if not x or not y or not z then return false end
    if math.floor(tonumber(player:getZ()) or 0) ~= math.floor(z) then
        return false
    end
    if not (PNC.Core and type(PNC.Core.DistanceSq) == "function") then
        return false
    end
    distanceSq = PNC.Core.DistanceSq(player:getX(), player:getY(), x, y)
    radius = tonumber(PNC.Const and PNC.Const.COMPANION_COMMAND_RADIUS) or 20
    return distanceSq <= radius * radius
end

local function relayEligible(commandID)
    local registry = PNC.CompanionCommands
    local definition = registry and registry.Get
        and registry.Get(commandID) or nil
    return definition ~= nil and definition.radioRelay == true
end

-- Sending a colonist home is only meaningful after the player has created a
-- base by claiming its territory: that claim is what gives the authority a
-- home point to travel to. Read the same base snapshot the Command Hub and the
-- Base window gate on, so the colonist bar cannot offer an order the server
-- will reject with "no base".
local function playerHasBase()
    local client = PNC.ColonyManagementClient
    local snapshot
    if client and type(client.ReadBaseSnapshot) == "function" then
        local update = client.ReadBaseSnapshot()
        snapshot = type(update) == "table" and update.snapshot or nil
    end
    if type(snapshot) ~= "table" then
        local state = PNC.Network and PNC.Network.ClientState or nil
        snapshot = state
            and (state.colonyBase or state.colonyManagement) or nil
    end
    return type(snapshot) == "table"
        and type(snapshot.settlement) == "table"
end

local function toggleCommandID(person)
    return person and person.followingCurrentPlayer == true
        and TOGGLE.homeCommandID or TOGGLE.followCommandID
end

TOGGLE.resolveCommandID = toggleCommandID

-- One verdict shared with the server: the relay gate owns the rules, this
-- function only gathers the facts a client snapshot can answer.
local function toggleFacts(person, commandID)
    return {
        companion = person ~= nil,
        -- The colony roster only ever lists records this player owns.
        owned = person ~= nil,
        dead = person ~= nil and person.alive == false,
        reachableDirectly = reachableDirectly(person),
        relayAllowed = relayEligible(commandID),
        playerRadio = playerRadioActive(),
        npcRadio = person ~= nil and person.radioGear ~= nil
            and person.radioGear.equipped == true or false,
    }
end

local function togglePresentation(person, definition)
    local gate = PNC.CommandRelayGate
    local commandID = definition.resolveCommandID(person)
    local following = person ~= nil
        and person.followingCurrentPlayer == true
    local state = { toggleState = following }
    local function actionTitle(follows)
        return follows
            and Shared.Tr(definition.onTitleKey, definition.onTitleFallback)
            or Shared.Tr(definition.offTitleKey, definition.offTitleFallback)
    end
    local function actionVariant(follows)
        return follows and definition.onVariant or definition.offVariant
    end
    -- The title and variant are always computed so the panel renders correctly
    -- even when the core toggle control is unavailable; the control's own state
    -- setter simply re-applies the same pair.
    state.title = actionTitle(following)
    state.variant = actionVariant(following)
    if not person then
        state.enabled = false
        state.reason = "no_colonist_selected"
        state.tooltip = Shared.Tr("UI_PNC_Activities_SelectHelp",
            "Choose a colonist to command their next personal activity.")
        return state
    end
    local help = following
        and Shared.Tr("UI_PNC_RadioRelay_GoHomeHelp",
            "Send this colonist home and end their errands.")
        or Shared.Tr("UI_PNC_RadioRelay_FollowHelp",
            "Call this colonist to follow you.")
    -- Go Home is base-anchored, so it stays disabled until the player has
    -- claimed a base territory. The follow face of the same toggle never needs
    -- a base and is judged by the relay gate alone.
    if commandID == TOGGLE.homeCommandID and not playerHasBase() then
        state.enabled = false
        state.reason = "base_required"
        state.tooltip = help .. "\n" .. Shared.Tr(
            "UI_PNC_CommandHub_Disabled_NoBase", "Requires a colony base.")
        return state
    end
    local allowed
    local reason
    local detail
    if not gate or type(gate.Evaluate) ~= "function" then
        state.enabled = false
        state.reason = "relay_gate_unavailable"
        state.tooltip = help
        return state
    end
    allowed, reason = gate.Evaluate(toggleFacts(person, commandID))
    if allowed ~= true then
        local line = gate.Reason(reason)
        detail = line and Shared.Tr(line.key, line.fallback) or nil
        state.enabled = false
        state.reason = reason
        state.tooltip = detail and (help .. "\n" .. detail) or help
        return state
    end
    if reason == gate.RELAY then
        detail = Shared.Tr("UI_PNC_RadioRelay_HelpRelay",
            "Radio relay: you and this colonist both hold a live walkie-talkie.")
    else
        detail = Shared.Tr("UI_PNC_RadioRelay_HelpDirect",
            "Within earshot: the order is given in person.")
    end
    state.enabled = true
    state.reason = reason
    state.tooltip = help .. "\n" .. detail
    return state
end

TOGGLE.presentation = togglePresentation

local function activityInfo(person)
    return person and person.actionInformation or nil
end

local function itemName(info)
    local fullType = tostring(info and info.activityItemFullType or "")
    if fullType ~= "" and getItemNameFromFullType then
        local resolved = getItemNameFromFullType(fullType)
        if resolved and resolved ~= "" then return tostring(resolved) end
    end
    if fullType ~= "" then
        local shortType = string.match(fullType, "([^%.]+)$") or fullType
        return string.gsub(shortType, "_", " ")
    end
    return nil
end

local function currentActivity(person)
    local info = activityInfo(person)
    if not info then return Shared.Text(person and person.activity, "IDLE") end
    if info.kind == "work_order" then
        local operation = tostring(info.operation or "")
        local label
        if operation == "PROVISION_PICKUP" then
            label = Shared.Tr("UI_PNC_Action_Grabbing", "GRABBING")
        elseif operation == "CORPSE_HAUL" then
            label = Shared.Tr("UI_PNC_CommandCorpseHaul", "GRAB CORPSES")
        else
            label = tostring(info.buildDisplayName or info.recipeId
                or operation or "WORKING")
        end
        local phase = tostring(info.phase or "")
        return phase ~= "" and label .. " (" .. phase .. ")" or label
    end
    local label
    if tostring(info.activityConsumptionMode or "") == "dual" then
        label = Shared.Tr("UI_PNC_Activity_Consuming", "CONSUMING")
    else
        label = info.labelKey
            and Shared.Tr(info.labelKey, info.fallback)
            or Shared.Text(info.fallback or info.activityId, "IDLE")
    end
    local item = itemName(info)
    if not item and info.activityItemLabelKey then
        local fallback = (info.resourceKind == "world_water"
            or info.capability == "survival.drink.world")
            and "water" or "item"
        item = Shared.Tr(info.activityItemLabelKey, fallback)
    end
    if item and item ~= "" then label = label .. " - " .. item end
    local phase = tostring(info.phase or "")
    if phase ~= "" then label = label .. " (" .. phase .. ")" end
    return label
end

local function matches(definition, capability)
    for _, value in ipairs(definition.capabilities or {}) do
        if value == tostring(capability or "") then return true end
    end
    return false
end

local function active(definition, person)
    local info = activityInfo(person)
    if definition.operation then
        return info and info.kind == "work_order"
            and tostring(info.operation or "") == definition.operation
    end
    return matches(definition, info and info.capability)
end

local function appendJournalRows(rows, person)
    local journalRows = JournalPresentation.Rows(person and person.journal)
    rows[#rows + 1] = Presentation.Detail(
        Shared.Tr("UI_PNC_Journal_Title", "COLONIST JOURNAL"),
        Shared.TrFormat("UI_PNC_Journal_EntryCount", "%s entries",
            tostring(#journalRows)), "accent")
    if #journalRows == 0 then
        rows[#rows + 1] = Presentation.Detail(
            Shared.Tr("UI_PNC_Journal_Empty", "No recorded history yet"), "")
        return
    end
    for _, journalRow in ipairs(journalRows) do
        rows[#rows + 1] = Presentation.Detail(
            journalRow.message, journalRow.time)
    end
end

local function getComponent(window, component)
    if component then return component end
    if window and window.tabComponents then
        component = window.tabComponents.activities
    end
    return component or (window and window.activityComponent)
end

local function syncControls(window, component)
    component = getComponent(window, component)
    if not component then return end
    local person = Selector.GetSelected(window.people)
    for _, definition in ipairs(DEFINITIONS) do
        local button = component.controls[definition.id]
        local state
        if definition.presentation then
            state = definition.presentation(person, definition)
        else
            local isActive = active(definition, person)
            local title = Shared.Tr(definition.key, definition.fallback)
            if definition.id == "manual_sleep" then
                title = title .. ": " .. Shared.Tr(
                    isActive and "UI_PNC_MonitorOn" or "UI_PNC_MonitorOff",
                    isActive and "ON" or "OFF")
            elseif isActive then
                title = title .. " (" .. Shared.Tr(
                    "UI_PNC_MonitorActive", "active") .. ")"
            end
            state = {
                title = title,
                enabled = person ~= nil and person.alive ~= false,
                variant = isActive and "selected" or "default",
            }
        end
        -- setEnable snapshots the enabled colours, so it has to run before any
        -- variant restyle; otherwise ISButton restores stale colours on the next
        -- enable and the button keeps looking disabled.
        button:setEnable(state.enabled == true)
        if definition.toggle and type(button.setToggleState) == "function" then
            -- The core toggle control owns the label swap and each state's
            -- variant; the panel only feeds it the current state. Labels are
            -- re-resolved here so a language change reaches the button too.
            if type(button.setToggleLabels) == "function" then
                button:setToggleLabels(
                    Shared.Tr(definition.offTitleKey,
                        definition.offTitleFallback),
                    Shared.Tr(definition.onTitleKey,
                        definition.onTitleFallback))
            end
            button:setToggleState(state.toggleState == true)
        else
            if button.setTitle then
                button:setTitle(state.title)
            else
                button.title = state.title
            end
            UI.SetButtonVariant(button, state.variant or "default")
        end
        -- A disabled toggle always reads as unavailable, whichever variant its
        -- own state setter just applied.
        if definition.toggle and state.enabled ~= true then
            UI.SetButtonVariant(button, "quiet")
        end
        if button.setTooltip then
            button:setTooltip(state.tooltip)
        else
            button.tooltip = state.tooltip
        end
    end
end

local function gridOptions(window, width)
    local scale = window.uiScale or Layout.Scale()
    local available = math.max(1, tonumber(width) or 1)
    return {
        scale = scale,
        columns = available >= Layout.Pixels(460, scale) and 2 or 1,
        gap = 8,
        rowGap = 8,
        height = 34,
        stretchLastRow = true,
    }
end

local function controlsHeight(window, width, component)
    component = getComponent(window, component)
    if not component then return 0 end
    local options = gridOptions(window, width)
    local header = Layout.Pixels(25, options.scale)
    local result = Layout.Grid(component.controlList, {
        x = 0,
        y = header + Layout.Pixels(8, options.scale),
        width = math.max(1, tonumber(width) or 1),
        height = 1,
    }, options) or {}
    return header + Layout.Pixels(8, options.scale) + result.height
end

function Activities.Create(window, _)
    local pane = UI.CreatePanel(window)
    pane:setVisible(false)
    local component = {
        pane = pane,
        controls = {},
        controlList = {},
    }
    window.activityComponent = component
    pane.render = function(panel)
        ISPanel.render(panel)
        UI.DrawSectionTitle(panel,
            Shared.Tr("UI_PNC_Activities_Commands", "MANUAL COMMANDS"),
            0, 0, panel:getWidth())
    end
    for _, definition in ipairs(DEFINITIONS) do
        local onclick = UI.ButtonCallback(function(control)
            return window:onColonistControl(control)
        end)
        local button
        if definition.toggle and type(UI.CreateToggleButton) == "function" then
            -- Core's reusable toggle control owns the two-state label and
            -- variant swap; the panel only feeds it state from syncControls.
            button = UI.CreateToggleButton(pane, {
                id = definition.id,
                offTitle = Shared.Tr(definition.offTitleKey,
                    definition.offTitleFallback),
                onTitle = Shared.Tr(definition.onTitleKey,
                    definition.onTitleFallback),
                offVariant = definition.offVariant,
                onVariant = definition.onVariant,
                target = window,
                onclick = onclick,
            })
        else
            button = UI.CreateButton(pane, {
                id = definition.id,
                title = Shared.Tr(definition.key, definition.fallback),
                target = window,
                onclick = onclick,
                variant = "default",
            })
        end
        button.activityCommandID = definition.id
        component.controls[definition.id] = button
        component.controlList[#component.controlList + 1] = button
    end
    return component
end

function Activities.GetControlsHeight(window, width, _, component)
    return controlsHeight(window, width, component)
end

function Activities.Apply(window, activeTab, Layout, component)
    component = getComponent(window, component)
    if not component then return end
    local pane = component.pane
    if pane then pane:setVisible(activeTab == true) end
    for _, button in ipairs(component.controlList or {}) do
        button:setVisible(activeTab == true)
    end
    if not activeTab then return end
    syncControls(window, component)
    if not pane then return end
    local options = gridOptions(window, pane:getWidth())
    local header = Layout.Pixels(25, options.scale)
    Layout.Grid(component.controlList, {
        x = 0,
        y = header + Layout.Pixels(8, options.scale),
        width = pane:getWidth(),
        height = 1,
    }, options)
end

function Activities.BuildRows(context)
    local person = context.selectedPerson
    if not person then
        return { Presentation.Detail(
            Shared.Tr("UI_PNC_Activities_Select", "SELECT A COLONIST"),
            Shared.Tr("UI_PNC_Activities_SelectHelp",
                "Choose a colonist to command their next personal activity."),
            "warning") }
    end
    local info = activityInfo(person)
    local rows = {
        Presentation.Detail(
            Shared.Tr("UI_PNC_Activities_Current", "CURRENT ACTIVITY"),
            currentActivity(person), "accent"),
        Presentation.Detail(
            Shared.Tr("UI_PNC_Activities_Mode", "ACTIVITY MODE"),
            info and info.manual == true
                and Shared.Tr("UI_PNC_Activities_Manual", "MANUAL")
                or Shared.Tr("UI_PNC_Activities_Automatic", "AUTOMATIC")),
    }
    if info and tostring(info.phase or "") ~= "" then
        rows[#rows + 1] = Presentation.Detail(
            Shared.Tr("UI_PNC_Activities_Phase", "PHASE"),
            tostring(info.phase))
    end
    local diagnostic = person.manualActivityDiagnostic
        or person.corpseHaulManualDiagnostic
    if type(diagnostic) == "table" and diagnostic.reason then
        local stage = tostring(diagnostic.details
            and diagnostic.details.stage or "request")
        local label = diagnostic.commandID
            and Shared.Tr("UI_PNC_Activities_LastActivityDiagnostic",
                "LAST ACTIVITY COMMAND")
            or Shared.Tr("UI_PNC_Activities_LastCorpseHaulDiagnostic",
                "LAST CORPSE HAUL DIAGNOSTIC")
        rows[#rows + 1] = Presentation.Detail(
            label,
            diagnostic.commandID and tostring(diagnostic.commandID) .. " = "
                .. tostring(diagnostic.reason)
                or stage .. " = " .. tostring(diagnostic.reason),
            diagnostic.result == true and "accent" or "warning")
    end
    if tostring(person.manualActivityDisabled or "") == "sleep" then
        rows[#rows + 1] = Presentation.Detail(
            Shared.Tr("UI_PNC_Activities_SleepDisabled", "SLEEP CONTROL"),
            Shared.Tr("UI_PNC_Activities_SleepDisabledHelp",
            "OFF - automatic sleep is suppressed until Sleep is enabled."),
            "warning")
    end
    appendJournalRows(rows, person)
    return rows
end

function Activities.OnPersonSelected(window, _, component)
    syncControls(window, component)
    if window.requestResponsiveLayout then window:requestResponsiveLayout(true) end
    return true
end

function Activities.OnControl(window, button)
    local person = Selector.GetSelected(window.people)
    local commandID = button and (button.activityCommandID or button.internal)
    local definition = BY_ID[tostring(commandID or "")]
    if not person or not definition or person.alive == false then return false end
    -- A toggle resolves the order it means to issue from the colonist's current
    -- state, so the same control can both call a colonist and send one home.
    local targetCommandID = definition.resolveCommandID
        and definition.resolveCommandID(person) or definition.id
    if definition.presentation then
        local state = definition.presentation(person, definition)
        if not state or state.enabled ~= true then
            -- The button is disabled in this state; keep the reason visible in
            -- the activity status rows instead of failing silently.
            local client = PNC.Client
            if client and client.RecordManualActivityDiagnostic then
                client.RecordManualActivityDiagnostic(person.id, targetCommandID,
                    false, state and state.reason or "command_unavailable")
            end
            return false
        end
    end
    local client = PNC.Client
    local execute = client and client.ExecuteCompanionCommand or nil
    if not execute then return false end
    local requestID = PNC.Core and PNC.Core.GenerateID
        and PNC.Core.GenerateID("colonist_activity")
        or tostring(person.id) .. ":" .. tostring(targetCommandID)
    local sent, reason = execute(targetCommandID, person.id, nil, {
        source = "colonist_activities",
        requestID = requestID,
    })
    if client.RecordManualActivityDiagnostic then
        client.RecordManualActivityDiagnostic(person.id, targetCommandID,
            sent == true, reason, requestID)
    end
    if window.requestSnapshot then
        window:requestSnapshot("colonist_activity_" .. targetCommandID)
    end
    return sent == true
end

return Activities
