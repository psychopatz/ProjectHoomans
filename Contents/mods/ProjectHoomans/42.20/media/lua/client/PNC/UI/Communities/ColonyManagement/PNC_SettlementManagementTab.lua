require "ISUI/ISComboBox"
require "PsychopatzCore/UI/PsychopatzUI"

local Components = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Components"
local Presentation = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Presentation"
local Shared = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local Selector = require "PsychopatzCore/UI/World/PsychopatzGridRegionSelector"
local BuildModal = require "PNC/UI/Communities/ColonyManagement/PNC_FacilityBuildModal"
local LayoutOverlay = require "PNC/UI/Communities/ColonyManagement/PNC_SettlementLayoutOverlay"

local BaseTab = {}
local UI = PsychopatzCore.UI
local BUTTONS = {
    { "claim", "UI_PNC_Base_ClaimAction", "CLAIM TERRITORY", "success" },
    { "overlay", "UI_PNC_Base_ShowLayout", "SHOW BASE LAYOUT", "selected" },
    { "build_facility", "UI_PNC_Facility_BuildAction", "BUILD A BUILDING", "success" },
    { "expand", "UI_PNC_Base_ExpandAction", "EXPAND", "primary" },
    { "shrink", "UI_PNC_Base_ShrinkAction", "SHRINK", "warning" },
    { "barricade", "UI_PNC_Base_BarricadeAction", "REINFORCE", "primary" },
    { "hq", "UI_PNC_Base_UpgradeAction", "UPGRADE HQ", "primary" },
    { "facility_area", "UI_PNC_Facility_AssignArea", "ASSIGN AREA", "primary" },
    { "facility_anchor", "UI_PNC_Facility_AssignBed", "ASSIGN BED", "primary" },
    { "facility_upgrade", "UI_PNC_Facility_Upgrade", "UPGRADE FACILITY", "primary" },
    { "stockpile", "UI_PNC_Stockpile_PlaceNode", "PLACE STOCKPILE", "success" },
}

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    if not value or value == key then return fallback end
    return value
end

local function emptyRegion() return { levels = {} } end

local function baseRegion(window)
    local geometry = window.snapshot and window.snapshot.settlement
        and window.snapshot.settlement.geometry
    return geometry and geometry.region or emptyRegion()
end

local function footprint(region)
    local rows = {}
    for _, level in pairs(GridRegion.normalize(region).levels) do
        for y, spans in pairs(level.rows) do
            local row = rows[y] or {}
            rows[y] = row
            for index = 1, #spans do row[#row + 1] = spans[index] end
        end
    end
    return GridRegion.normalize({ levels = { [0] = { rows = rows } } })
end

local function selectionTitle(key, fallback)
    return tr(key, fallback)
end

local function selectedFacility(window)
    local combo = window.baseFacilityCombo
    return combo and combo:getOptionData(combo.selected) or nil
end

local function componentForRole(facility, role)
    for _, component in ipairs(facility and facility.components or {}) do
        if component.role == role then return component end
    end
    return nil
end

local function usedGuideLayers(window, excludedComponentId)
    local settlement = window.snapshot and window.snapshot.settlement or nil
    local layers = LayoutOverlay.BuildLayers(settlement, false)
    if not excludedComponentId then return layers end
    local filtered = {}
    for _, layer in ipairs(layers) do
        if tostring(layer.componentId or "") ~= tostring(excludedComponentId) then
            filtered[#filtered + 1] = layer
        end
    end
    return filtered
end

local function applyLocalResult(window)
    if window and PNC.Core and PNC.Core.IsClientOnly
        and PNC.Core.IsClientOnly() ~= true and window.refresh
    then window:refresh() end
end

local function openSelector(window, options)
    options.ownerWindow = window
    options.player = getSpecificPlayer(0)
    options.playerNum = 0
    return Selector.Open(options)
end

local function validateConnected(region)
    if GridRegion.countTiles(region) <= 0 then return false, "EMPTY_REGION" end
    if not GridRegion.isConnected(region, 4) then
        return false, "BASE_DISCONNECTED"
    end
    return true
end

local function beginBaseEdit(window, operation)
    local snapshot = window.snapshot or {}
    local settlement = snapshot.settlement
    local current = baseRegion(window)
    local currentCount = GridRegion.countTiles(current)
    local territory = settlement and settlement.territory or {}
    local maximum = operation == "create"
        and (PNC.SettlementDefinitions.STARTING_TERRITORY or 270)
        or tonumber(territory.territoryCapacity) or 0
    local options = {
        title = operation == "create"
            and selectionTitle("UI_PNC_Base_SelectCreate", "SELECT AREA: BASE TERRITORY")
            or operation == "expand"
                and selectionTitle("UI_PNC_Base_SelectExpand", "SELECT AREA TO ADD")
                or selectionTitle("UI_PNC_Base_SelectShrink", "SELECT AREA TO REMOVE"),
        instruction = tr("UI_PNC_Base_SelectHelp",
            "Drag a rectangle; use Add or Erase to shape an irregular connected area."),
        initialRegion = emptyRegion(),
        guideRegion = operation == "create" and nil or current,
        guideRenderZ = math.floor(getSpecificPlayer(0):getZ()),
        maxTiles = operation == "create" and maximum or nil,
        highlightColor = operation == "shrink"
            and { r = 1, g = 0.25, b = 0.2, a = 0.42 }
            or { r = 0.15, g = 0.7, b = 1, a = 0.44 },
    }
    options.validate = function(region, stats)
        local candidate = operation == "create" and footprint(region)
            or operation == "expand"
                and GridRegion.union(current, footprint(region))
                or GridRegion.subtract(current, footprint(region))
        local ok, reason = validateConnected(candidate)
        local claimed = GridRegion.countTiles(candidate)
        if ok and claimed > maximum then ok, reason = false, "BASE_CAPACITY_EXCEEDED" end
        if ok and operation == "expand" and claimed <= currentCount then
            ok, reason = false, "NO_NEW_TERRITORY"
        end
        if ok and operation == "shrink" and claimed >= currentCount then
            ok, reason = false, "NO_TERRITORY_REMOVED"
        end
        return ok, ok and nil or Shared.SettlementReason(reason),
            { claimed = claimed, capacity = maximum,
            selected = stats.tileCount }
    end
    options.onConfirm = function(region)
        local colony = snapshot.colony or {}
        if operation == "create" then
            PNC.Client.RequestCreateBase({
                colonyId = colony.id,
                factionId = colony.factionID or colony.factionId,
                region = region,
            })
        elseif operation == "expand" then
            PNC.Client.RequestExpandBase({ baseId = settlement.id,
                expectedRevision = settlement.revision, regionDelta = region })
        else
            PNC.Client.RequestShrinkBase({ baseId = settlement.id,
                expectedRevision = settlement.revision, regionDelta = region })
        end
        applyLocalResult(window)
    end
    openSelector(window, options)
end

local function facilityRole(facility)
    if not facility then return nil end
    if facility.definitionId == "barracks" then return "sleep.area" end
    if facility.definitionId == "farm" then return "farm.field" end
    return nil
end

local function beginFacilityArea(window, facility)
    local role = facilityRole(facility)
    if not role then return false end
    local existing = componentForRole(facility, role)
    local level = PNC.FacilityDefinitions.GetLevel(
        facility.definitionId, facility.level)
    local limit = level and level.componentLimits[role] or {}
    openSelector(window, {
        title = getText("UI_PNC_Facility_SelectArea"),
        instruction = tr("UI_PNC_Facility_SelectAreaHelp",
            "Select one connected area inside the base territory."),
        initialRegion = existing and existing.region or emptyRegion(),
        guideRegion = baseRegion(window),
        guideLayers = usedGuideLayers(window, existing and existing.id),
        guideRenderZ = math.floor(getSpecificPlayer(0):getZ()),
        maxTiles = limit.maxTotalTiles,
        validate = function(region, stats)
            local ok, reason = validateConnected(region)
            if ok and not GridRegion.containsRegion(
                baseRegion(window), footprint(region))
            then ok, reason = false, "OUTSIDE_BASE" end
            if ok and limit.maxTotalTiles
                and stats.tileCount > limit.maxTotalTiles
            then ok, reason = false, "FACILITY_AREA_TOO_LARGE" end
            return ok, ok and nil or Shared.SettlementReason(reason)
        end,
        onConfirm = function(region)
            PNC.Client.RequestSetFacilityComponent({
                facilityId = facility.id,
                expectedRevision = facility.revision,
                component = { id = existing and existing.id or nil,
                    kind = "region", role = role, region = region },
            })
            applyLocalResult(window)
        end,
    })
    return true
end

local function beginPoint(window, kind, facility)
    local role = kind == "bed" and "sleep.bed" or nil
    openSelector(window, {
        title = kind == "bed"
            and selectionTitle("UI_PNC_Facility_SelectBed", "SELECT BED TILE")
            or selectionTitle("UI_PNC_Stockpile_SelectNode", "SELECT STOCKPILE ACCESS TILE"),
        instruction = tr("UI_PNC_Point_SelectHelp", "Click one tile, then confirm."),
        selectionKind = "point",
        guideRegion = baseRegion(window),
        guideLayers = usedGuideLayers(window),
        guideRenderZ = math.floor(getSpecificPlayer(0):getZ()),
        validate = function(region)
            local bounds = GridRegion.bounds(region)
            if not bounds or not GridRegion.containsXY(
                baseRegion(window), bounds.minX, bounds.minY)
            then return false, Shared.SettlementReason("OUTSIDE_BASE") end
            return true
        end,
        onConfirm = function(region)
            local bounds = GridRegion.bounds(region)
            if kind == "bed" then
                PNC.Client.RequestSetFacilityComponent({
                    facilityId = facility.id,
                    expectedRevision = facility.revision,
                    component = { kind = "anchor", role = role,
                        x = bounds.minX, y = bounds.minY, z = bounds.minZ,
                        targetResolver = "worldObject", objectTag = "bed" },
                })
            else
                local settlement = window.snapshot.settlement
                local storage = window.snapshot.storage or {}
                PNC.Client.RequestCreateStockpileAccessNode({
                    baseId = settlement.id,
                    expectedRevision = settlement.revision,
                    storageId = storage.storageId,
                    x = bounds.minX, y = bounds.minY, z = bounds.minZ,
                })
            end
            applyLocalResult(window)
        end,
    })
end

function BaseTab.Create(window, UI)
    window.baseControls = {}
    for _, definition in ipairs(BUTTONS) do
        local button = UI.CreateButton(window, {
            id = definition[1], title = tr(definition[2], definition[3]),
            target = window, onclick = ISPNCColonyManagementWindow.onBaseControl,
            variant = definition[4],
        })
        window.baseControls[#window.baseControls + 1] = button
        window.baseControls[definition[1]] = button
    end
    window.baseFacilityCombo = ISComboBox:new(0, 0, 220, 26, window, nil)
    window.baseFacilityCombo:initialise()
    window.baseFacilityCombo:instantiate()
    window:addChild(window.baseFacilityCombo)
end

function BaseTab.Layout(window, Layout, content)
    local gap, height = 6, 27
    local minimum = 112
    local columns = math.max(2, math.floor((content.width + gap) / (minimum + gap)))
    local width = math.floor((content.width - gap * (columns - 1)) / columns)
    local index = 0
    for _, button in ipairs(window.baseControls or {}) do
        local column = index % columns
        local row = math.floor(index / columns)
        Layout.SetBounds(button, content.x + column * (width + gap),
            content.y + row * (height + gap), width, height)
        index = index + 1
    end
    local rows = math.ceil(index / columns)
    local comboY = content.y + rows * (height + gap) + 2
    Layout.SetBounds(window.baseFacilityCombo, content.x, comboY,
        math.min(300, content.width), height)
    window.baseDetailsY = comboY + height + 8
end

function BaseTab.Apply(window, active)
    local established = window.snapshot and window.snapshot.settlement ~= nil
    for _, button in ipairs(window.baseControls or {}) do
        button:setVisible(active and (button.internal == "claim"
            and not established or button.internal ~= "claim" and established))
    end
    window.baseFacilityCombo:setVisible(active and established)
    if active and window.baseDetailsY then
        window:layoutPane(window.detailsPane, window.layout.content.x,
            window.baseDetailsY, window.layout.content.width,
            math.max(60, window.layout.content.y + window.layout.content.height
                - window.baseDetailsY))
    end
end

function BaseTab.Rebuild(window, snapshot)
    local combo = window.baseFacilityCombo
    local previous = selectedFacility(window)
    local previousId = previous and previous.id
    combo:clear()
    local selectedIndex = 1
    local facilities = snapshot.settlement
        and snapshot.settlement.facilities or {}
    for index, facility in ipairs(facilities) do
        local definition = PNC.FacilityDefinitions.Get(facility.definitionId)
        combo:addOptionWithData(tr(definition and definition.displayNameKey or "",
            facility.definitionId) .. "  L" .. tostring(facility.level), facility)
        if facility.id == previousId then selectedIndex = index end
    end
    if #facilities == 0 then
        combo:addOptionWithData(tr("UI_PNC_Facility_None", "NO FACILITIES"), false)
    end
    combo.selected = selectedIndex
    LayoutOverlay.SetSettlement(snapshot.settlement)
    local overlayButton = window.baseControls and window.baseControls.overlay
    if overlayButton then
        overlayButton:setTitle(LayoutOverlay.IsEnabled()
            and tr("UI_PNC_Base_HideLayout", "HIDE BASE LAYOUT")
            or tr("UI_PNC_Base_ShowLayout", "SHOW BASE LAYOUT"))
        UI.SetButtonVariant(overlayButton,
            LayoutOverlay.IsEnabled() and "warning" or "selected")
    end
    Components.SetRows(window.details, Presentation.BuildSettlement(snapshot))
    return true
end

function BaseTab.OnControl(window, button)
    local action = button and button.internal
    local settlement = window.snapshot and window.snapshot.settlement
    if action == "claim" then beginBaseEdit(window, "create"); return true end
    if not settlement then return false end
    if action == "expand" then beginBaseEdit(window, "expand"); return true end
    if action == "shrink" then beginBaseEdit(window, "shrink"); return true end
    if action == "overlay" then
        local enabled = LayoutOverlay.Toggle(settlement)
        button:setTitle(enabled
            and tr("UI_PNC_Base_HideLayout", "HIDE BASE LAYOUT")
            or tr("UI_PNC_Base_ShowLayout", "SHOW BASE LAYOUT"))
        UI.SetButtonVariant(button, enabled and "warning" or "selected")
        return true
    elseif action == "build_facility" then
        BuildModal.Open(settlement, function(definitionId)
            PNC.Client.RequestCreateFacility({ baseId = settlement.id,
                expectedRevision = settlement.revision,
                definitionId = definitionId })
            applyLocalResult(window)
        end, window.snapshot and window.snapshot.storage)
        return true
    elseif action == "barricade" then
        PNC.Client.RequestBuildBarricade({ baseId = settlement.id,
            expectedRevision = settlement.revision })
    elseif action == "hq" then
        PNC.Client.RequestUpgradeHQ({ baseId = settlement.id,
            expectedRevision = settlement.revision })
    elseif action == "stockpile" then
        beginPoint(window, "stockpile")
        return true
    else
        local facility = selectedFacility(window)
        if not facility then return false end
        if action == "facility_area" then return beginFacilityArea(window, facility) end
        if action == "facility_anchor" and facility.definitionId == "barracks" then
            beginPoint(window, "bed", facility); return true
        end
        if action == "facility_upgrade" then
            PNC.Client.RequestUpgradeFacility({ facilityId = facility.id,
                expectedRevision = facility.revision })
        end
    end
    applyLocalResult(window)
    return true
end

return BaseTab
