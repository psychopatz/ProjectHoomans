local Placement = {}
local Policy = require
    "PNC/UI/Base/PNC_BaseBuildingPlacementPolicy"
local Cursor = require
    "PNC/UI/Base/PNC_BaseBuildingPlacement_Cursor"
local Begin = require
    "PNC/UI/Base/PNC_BaseBuildingPlacement_Begin"
local Footprint = require "PNC/Core/Settlement/PNC_BuildingFootprint"
local QueueOverlay = require
    "PNC/UI/Base/PNC_BaseBuildingQueueOverlay"
local BuildAudit = require "PNC/Core/Diagnostics/PNC_BuildAudit"

local function call(object, method, ...)
    if not object or type(object[method]) ~= "function" then return nil end
    local ok, value = pcall(object[method], object, ...)
    return ok and value or nil
end

local function currentPlayer()
    return getSpecificPlayer and getSpecificPlayer(0) or nil
end

local function closeFacilityPlacementUI(active)
    if not active or active.pncFacilityPlacement ~= true then return end
    local placementUI = PNC and PNC.BuildingPlacementUI or nil
    if placementUI and placementUI.Close then placementUI.Close() end
end

--[[
    Placement needs to see the world, and the Base window covers most of the
    screen. Hide it for the duration of the placement and bring it back on every
    teardown path (confirm, cancel, back, tab switch, window close). The small
    placement notice stays up so the player still has the rotate hint and the
    cancel action.
]]
local function hideOwnerWhilePlacing(window)
    if not window or window.pncPlacementHidden == true then return end
    if type(window.setVisible) ~= "function" then return end
    window.pncPlacementHidden = true
    window.pncPlacementWasVisible = window.getIsVisible
        and window:getIsVisible() ~= false or true
    window:setVisible(false)
    if window.removeFromUIManager then window:removeFromUIManager() end
    BuildAudit.TracePlacement("pnc_build_window_hidden", {})
end

local function restoreOwnerAfterPlacing(window)
    if not window or window.pncPlacementHidden ~= true then return end
    window.pncPlacementHidden = false
    if window.pncPlacementWasVisible == false then
        window.pncPlacementWasVisible = nil
        return
    end
    window.pncPlacementWasVisible = nil
    if type(window.setVisible) ~= "function" then return end
    if window.addToUIManager then window:addToUIManager() end
    window:setVisible(true)
    if window.bringToTop then window:bringToTop() end
    BuildAudit.TracePlacement("pnc_build_window_restored", {})
end

Placement.HideOwnerWhilePlacing = hideOwnerWhilePlacing
Placement.RestoreOwnerAfterPlacing = restoreOwnerAfterPlacing

local function fail(reason)
    Placement.lastError = reason
    BuildAudit.TracePlacement("pnc_build_placement_failed",
        { "reason=" .. tostring(reason) })
    if BuildAudit.Enabled() then
        BuildAudit.Log("placement_failed", {
            "reason=" .. tostring(reason),
        })
    end
    if PNC and PNC.Core and PNC.Core.LogWarn then
        PNC.Core.LogWarn("building placement failed: " .. tostring(reason))
    end
    return false, reason
end

local function tr(key, fallback)
    local value = getText and PNC.Translation.GetKey(key) or nil
    if not value or value == key or value == "" then return fallback end
    return value
end

local function tooltipContent(cursor)
    local reason = tostring(cursor and cursor.pncPlacementError or "")
    if reason == "BUILD_TARGET_OUTSIDE_BASE" then
        return tr("UI_PNC_BuildingPlacement_InvalidTitle",
                "INVALID PLACEMENT"),
            tr("UI_PNC_BuildingPlacement_OutsideBase",
                "Outside home base. Select a location inside the highlighted base territory.")
    end
    if reason == "BUILD_BASE_UNAVAILABLE" then
        return tr("UI_PNC_BuildingPlacement_InvalidTitle",
                "INVALID PLACEMENT"),
            tr("UI_PNC_BuildingPlacement_BaseUnavailable",
                "Home-base territory is unavailable. Refresh the colony data and try again.")
    end
    if reason == "BUILD_TARGET_REQUIRED" then
        return tr("UI_PNC_BuildingPlacement_InvalidTitle",
                "INVALID PLACEMENT"),
            tr("UI_PNC_BuildingPlacement_TargetRequired",
                "Move the cursor over a valid world tile.")
    end
    if reason == "BUILD_TARGET_INVALID" then
        return tr("UI_PNC_BuildingPlacement_InvalidTitle",
                "INVALID PLACEMENT"),
            tr("UI_PNC_BuildingPlacement_EngineInvalid",
                "This building cannot be placed on the selected tile.")
    end
    if reason == "BUILD_TARGET_ALREADY_QUEUED" then
        return tr("UI_PNC_BuildingPlacement_InvalidTitle",
                "INVALID PLACEMENT"),
            tr("UI_PNC_BuildingPlacement_QueuedCollision",
                "This area overlaps another queued blueprint. Select a clear area before placing this blueprint.")
    end
    return nil, nil
end

function Placement.HideTooltip(cursor)
    local tooltip = cursor and cursor.tooltip or nil
    if not tooltip then return end
    if tooltip.removeFromUIManager then tooltip:removeFromUIManager() end
    if tooltip.setVisible then tooltip:setVisible(false) end
    cursor.tooltip = nil
end

function Placement.RenderTooltip(cursor)
    local title, description = tooltipContent(cursor)
    if not title or not description then
        Placement.HideTooltip(cursor)
        return
    end
    if not ISWorldObjectContextMenu then
        pcall(require, "ISUI/ISWorldObjectContextMenu")
    end
    if not ISWorldObjectContextMenu
        or type(ISWorldObjectContextMenu.addToolTip) ~= "function"
    then return end
    local tooltip = cursor.tooltip
    if not tooltip then
        tooltip = ISWorldObjectContextMenu.addToolTip()
        cursor.tooltip = tooltip
        if tooltip.setVisible then tooltip:setVisible(true) end
        if tooltip.addToUIManager then tooltip:addToUIManager() end
        tooltip.followMouse = true
        tooltip.maxLineWidth = 760
        if cursor.chosenSprite and tooltip.setTexture then
            tooltip:setTexture(cursor.chosenSprite)
        end
    end
    if tooltip.setName then tooltip:setName(title) end
    tooltip.description = description
end

local function setBoundaryValidity(cursor, square)
    local region = Footprint.FromCursor(cursor, square)
    local valid, reason, normalized, invalid, conflictingOrder =
        Policy.ValidateCurrentFootprint(region)
    cursor.pncFootprint = normalized or region
    cursor.pncInvalidFootprint = invalid
    cursor.pncCollisionOrder = conflictingOrder
    cursor.pncPlacementError = reason
    cursor.pncBaseValid = valid == true
    cursor.pncEngineValid = true
    -- Validity is recomputed every frame, so trace only when the outcome
    -- changes. "Invalid everywhere" is what makes a build impossible and it is
    -- otherwise silent: canBeBuild=false stops onPlacement from ever running,
    -- so no other line in this file would report it.
    local signature = valid == true and "valid" or tostring(reason or "invalid")
    if cursor.pncValiditySignature ~= signature then
        cursor.pncValiditySignature = signature
        BuildAudit.TracePlacement("pnc_build_placement_validity", {
            "valid=" .. tostring(valid == true),
            "reason=" .. tostring(reason),
            "settlement=" .. tostring(Policy.CurrentSettlement() ~= nil),
        })
        if BuildAudit.Enabled() then
            BuildAudit.Log("placement_validity", {
                "valid=" .. tostring(valid == true),
                "reason=" .. tostring(reason),
                "settlement=" .. tostring(Policy.CurrentSettlement() ~= nil),
                "footprint=" .. tostring(cursor.pncFootprint ~= nil),
            })
        end
    end
    return valid == true
end

local function setEngineInvalid(cursor, square)
    cursor.pncFootprint = nil
    cursor.pncInvalidFootprint = nil
    cursor.pncCollisionOrder = nil
    cursor.pncEngineValid = false
    cursor.pncBaseValid = false
    cursor.pncPlacementError = square and "BUILD_TARGET_INVALID"
        or "BUILD_TARGET_REQUIRED"
    return false
end

local function renderRegion(playerNum, region, color)
    if not addAreaHighlightForPlayer or not region then return end
    for z, level in pairs(region.levels or {}) do
        for y, spans in pairs(level.rows or {}) do
            for index = 1, #spans, 2 do
                addAreaHighlightForPlayer(playerNum, spans[index], y,
                    spans[index + 1] + 1, y + 1, z,
                    color.r, color.g, color.b, color.a)
            end
        end
    end
end

-- This is intentionally a placement-owned, frame-only guide. It does not
-- toggle the persistent settlement overlay and therefore remains compatible
-- with freestyle selectors such as chop-tree and fishing zones.
function Placement.RenderBaseGuide()
    local cursor = Placement.activeCursor
    if not cursor or cursor.pncPlacement ~= true then return end
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local settlement = Policy.CurrentSettlement()
    local region = settlement and settlement.geometry
        and settlement.geometry.region or nil
    if not player or not region then return end
    local playerNum = player.getPlayerNum and player:getPlayerNum() or 0
    renderRegion(playerNum, region,
        { r = 0.10, g = 0.70, b = 1.00, a = 0.12 })
    if QueueOverlay and QueueOverlay.RenderPlacement then
        QueueOverlay.RenderPlacement(playerNum)
    end
    renderRegion(playerNum, cursor.pncInvalidFootprint,
        { r = 1.00, g = 0.12, b = 0.08, a = 0.42 })
end

local function onDoTileBuilding(cursor, isRender, x, y, z, square)
    if not cursor or cursor.pncPlacement ~= true then return end
    if isRender then
        if cursor.render then cursor:render(x, y, z, square) end
        return
    end
    if cursor.placed then return end
    if cursor.render then cursor:render(x, y, z, square) end
    if cursor.canBeBuild and cursor.tryBuild then
        cursor:tryBuild(x, y, z)
    end
end

local function installPlacementEvents()
    if not Events then return end
    if not Placement.doTileEventsInstalled
        and Events.OnDoTileBuilding2 and Events.OnDoTileBuilding2.Add
    then
        Events.OnDoTileBuilding2.Add(onDoTileBuilding)
        Placement.doTileEventsInstalled = true
    end
    if not Placement.guideEventInstalled
        and Events.OnPreUIDraw and Events.OnPreUIDraw.Add
    then
        Events.OnPreUIDraw.Add(Placement.RenderBaseGuide)
        Placement.guideEventInstalled = true
    end
    Placement.eventsInstalled = Placement.doTileEventsInstalled == true
        or Placement.guideEventInstalled == true
end

installPlacementEvents()
if Events and Events.OnGameStart and Events.OnGameStart.Add then
    Events.OnGameStart.Add(installPlacementEvents)
end

function Placement.Cancel(window, reason)
    local active = window and window.buildPlacement or nil
    local current = currentPlayer()
    local cell = getCell and getCell() or nil
    if active or Placement.activeCursor then
        BuildAudit.TracePlacement("pnc_build_placement_cancel",
            { "reason=" .. tostring(reason or "unspecified") })
    end
    if BuildAudit.Enabled() and (active or Placement.activeCursor) then
        BuildAudit.Log("placement_cancel", {
            "reason=" .. tostring(reason or "unspecified"),
            "had_cursor=" .. tostring((active or Placement.activeCursor) ~= nil),
            "had_ui=" .. tostring(active ~= nil),
        })
    end
    if active and cell and type(cell.setDrag) == "function" then
        local playerNum = active.player
        if playerNum == nil and current then
            playerNum = current:getPlayerNum()
        end
        cell:setDrag(nil, playerNum or 0)
    end
    Placement.HideTooltip(active)
    if Placement.activeCursor == active then Placement.activeCursor = nil end
    if window then window.buildPlacement = nil end
    closeFacilityPlacementUI(active)
    restoreOwnerAfterPlacing(window)
    Placement.lastError = nil
end

local beginDependencies = {
    currentPlayer = currentPlayer,
    closeFacilityPlacementUI = closeFacilityPlacementUI,
    restoreOwnerAfterPlacing = restoreOwnerAfterPlacing,
    hideOwnerWhilePlacing = hideOwnerWhilePlacing,
    fail = fail,
    setBoundaryValidity = setBoundaryValidity,
    setEngineInvalid = setEngineInvalid,
}

function Placement.Begin(window, recipe)
    return Begin.Start(Placement, beginDependencies, window, recipe)
end

return Placement
