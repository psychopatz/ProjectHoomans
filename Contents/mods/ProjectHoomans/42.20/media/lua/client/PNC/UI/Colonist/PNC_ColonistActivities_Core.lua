require "PsychopatzCore/UI/PsychopatzUI"
require "ISUI/ISPanel"

local Presentation = require "PNC/UI/Communities/PNC_ColonyPresentation"
local JournalPresentation = require "PNC/UI/Communities/PNC_ColonistJournalPresentation"
local Selector = require "PNC/UI/Colonist/PNC_ColonistSelector"
local ActivityPresentation = require
    "PNC/UI/Colonist/PNC_ColonistActivityPresentation"
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
    {
        -- Opens the colonist's inventory window. This is a client view rather
        -- than a dispatched order, so it is laid out on its own below the
        -- command grid and given a taller control, and it is only offered while
        -- the colonist is materialized (live, not abstract).
        id = "manual_inventory",
        separate = true,
        opensInventory = true,
        key = "UI_PNC_CommandAccessInventory",
        fallback = "ACCESS INVENTORY",
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
    -- a base, but a remote/abstract target still requires the radio relay gate.
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

--[[
    Access Inventory opens a client view of the colonist's inventory, so it only
    applies while that colonist is materialized in the world: a live body has an
    authoritative inventory to read, while an abstracted colonist has no loaded
    body behind the request and a dead one has nothing to show.
]]
local function inventoryPresentation(person, definition)
    local state = {
        title = Shared.Tr(definition.key, definition.fallback),
        variant = "default",
    }
    if not person then
        state.enabled = false
        state.reason = "no_colonist_selected"
        state.tooltip = Shared.Tr("UI_PNC_Activities_SelectHelp",
            "Choose a colonist to command their next personal activity.")
        return state
    end
    if person.alive == false then
        state.enabled = false
        state.reason = "colonist_dead"
        state.tooltip = Shared.Tr("UI_PNC_Activities_InventoryDead",
            "This colonist is no longer alive.")
        return state
    end
    local live = tostring(PNC.Const and PNC.Const.PRESENCE_LIVE or "live")
    if tostring(person.presenceState or "") ~= live then
        state.enabled = false
        state.reason = "colonist_not_live"
        state.tooltip = Shared.Tr("UI_PNC_Activities_InventoryNotLive",
            "Only available while this colonist is present in the world.")
        return state
    end
    state.enabled = true
    state.tooltip = Shared.Tr("UI_PNC_Activities_InventoryHelp",
        "Open this colonist's inventory.")
    return state
end

if BY_ID.manual_inventory then
    BY_ID.manual_inventory.presentation = inventoryPresentation
end

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
    local behaviorID = string.lower(tostring(info.behaviorId or ""))
    local orderKind = string.lower(tostring(info.orderKind or ""))
    if info.kind == "behavior"
        and (orderKind == "fishing"
            or string.find(behaviorID, "fishing", 1, true) == 1)
    then
        return ActivityPresentation.Fishing(info)
    end
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

Activities.Internal = Activities.Internal or {}
Activities.Internal.Presentation = Presentation
Activities.Internal.JournalPresentation = JournalPresentation
Activities.Internal.Selector = Selector
Activities.Internal.Shared = Shared
Activities.Internal.UI = UI
Activities.Internal.Layout = Layout
Activities.Internal.Definitions = DEFINITIONS
Activities.Internal.ByID = BY_ID
Activities.Internal.Toggle = TOGGLE
Activities.Internal.activityInfo = activityInfo
Activities.Internal.itemName = itemName
Activities.Internal.currentActivity = currentActivity
Activities.Internal.matches = matches
Activities.Internal.active = active
Activities.Internal.appendJournalRows = appendJournalRows

return Activities
