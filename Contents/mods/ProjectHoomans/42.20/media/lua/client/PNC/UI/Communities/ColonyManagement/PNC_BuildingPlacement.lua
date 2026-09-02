local Placement = {}
local Policy = require
    "PNC/UI/Communities/ColonyManagement/PNC_BuildingPlacementPolicy"
local Footprint = require "PNC/Core/Settlement/PNC_BuildingFootprint"

local function call(object, method, ...)
    if not object or type(object[method]) ~= "function" then return nil end
    local ok, value = pcall(object[method], object, ...)
    return ok and value or nil
end

local function currentPlayer()
    return getSpecificPlayer and getSpecificPlayer(0) or nil
end

local function closeFacilityPlacementUI(active, restorePrevious)
    if not active or active.pncFacilityPlacement ~= true then return end
    local placementUI = PNC and PNC.BuildingPlacementUI or nil
    if placementUI and placementUI.Close then placementUI.Close() end
    if restorePrevious ~= false then
        local buildUI = PNC and PNC.FacilityBuildUI or nil
        if buildUI and buildUI.RestorePrevious then
            buildUI.RestorePrevious()
        end
    end
end

local function fail(reason)
    Placement.lastError = reason
    if PNC and PNC.Core and PNC.Core.LogWarn then
        PNC.Core.LogWarn("building placement failed: " .. tostring(reason))
    end
    return false, reason
end

local function tr(key, fallback)
    local value = getText and getText(key) or nil
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
    local valid, reason, normalized, invalid =
        Policy.ValidateCurrentFootprint(region)
    cursor.pncFootprint = normalized or region
    cursor.pncInvalidFootprint = invalid
    cursor.pncPlacementError = reason
    cursor.pncBaseValid = valid == true
    cursor.pncEngineValid = true
    return valid == true
end

local function setEngineInvalid(cursor, square)
    cursor.pncFootprint = nil
    cursor.pncInvalidFootprint = nil
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
    renderRegion(playerNum, cursor.pncInvalidFootprint,
        { r = 1.00, g = 0.12, b = 0.08, a = 0.42 })
end

local function faceIndex(nSprite)
    nSprite = tonumber(nSprite) or 1
    if nSprite == 2 then return 0 end
    if nSprite == 4 then return 2 end
    return nSprite
end

local function firstSpriteName(cursor)
    local face = cursor.getFace and cursor:getFace() or nil
    if not face then return cursor.sprite end
    local layers = tonumber(call(face, "getzLayers")) or 0
    local width = tonumber(call(face, "getWidth")) or 0
    local height = tonumber(call(face, "getHeight")) or 0
    for zz = 0, layers - 1 do
        for xx = 0, width - 1 do
            for yy = 0, height - 1 do
                local tile = call(face, "getTileInfo", xx, yy, zz)
                local name = call(tile, "getSpriteName")
                if name and tostring(name) ~= "" then return tostring(name) end
            end
        end
    end
    return cursor.sprite
end

local function renderGhostTile(cursor, spriteName, x, y, z, r, g, b)
    if not spriteName then return false end
    cursor.spriteCache = cursor.spriteCache or {}
    local sprite = cursor.spriteCache[spriteName]
    if not sprite and IsoSprite and IsoSprite.new then
        local ok, created = pcall(IsoSprite.new)
        if ok and created then
            local loaded = pcall(created.LoadSingleTexture, created, spriteName)
            if loaded then
                cursor.spriteCache[spriteName] = created
                sprite = created
            end
        end
    end
    if not sprite and getSprite then
        local ok, shared = pcall(getSprite, spriteName)
        sprite = ok and shared or nil
    end
    if not sprite or type(sprite.RenderGhostTileColor) ~= "function" then
        return false
    end
    pcall(sprite.RenderGhostTileColor, sprite, x, y, z, 0, 0,
        r, g, b, 0.6)
    return true
end

local function createFallbackCursorClass()
    local class = {}

    function class:new(character, info, nSprite)
        local cursor = setmetatable({}, { __index = self })
        cursor.character = character
        cursor.objectInfo = info
        cursor.nSprite = tonumber(nSprite) or 1
        cursor.spriteCache = {}
        cursor.canBeBuild = false
        cursor.dragNilAfterPlace = true
        return cursor
    end

    function class:getFace()
        if self.face and self.faceSprite == self.nSprite then
            return self.face
        end
        local face = call(self.objectInfo, "getFace", faceIndex(self.nSprite))
        self.face, self.faceSprite = face, self.nSprite
        return face
    end

    function class:getSprite()
        local spriteName = firstSpriteName(self)
        self.chosenSprite = spriteName
        return spriteName
    end

    function class:isValid(square)
        if not square then return setEngineInvalid(self, square) end
        local world = getWorld and getWorld() or nil
        if world and type(world.isValidSquare) == "function" then
            local x = call(square, "getX")
            local y = call(square, "getY")
            local z = call(square, "getZ")
            local valid = call(world, "isValidSquare", x, y, z)
            if valid == false then return setEngineInvalid(self, square) end
        end
        return setBoundaryValidity(self, square)
    end

    function class:render(x, y, z, square)
        self.square = square
        self.canBeBuild = self:isValid(square)
        local face = self:getFace()
        if not face then
            Placement.RenderTooltip(self)
            return
        end
        local layers = tonumber(call(face, "getzLayers")) or 0
        local width = tonumber(call(face, "getWidth")) or 0
        local height = tonumber(call(face, "getHeight")) or 0
        local r, g, b = 1, 1, 1
        if not self.canBeBuild then r, g, b = 0.65, 0.2, 0.2 end
        for zz = 0, layers - 1 do
            for xx = 0, width - 1 do
                for yy = 0, height - 1 do
                    local tile = call(face, "getTileInfo", xx, yy, zz)
                    local spriteName = call(tile, "getSpriteName")
                    if spriteName then
                        renderGhostTile(self, tostring(spriteName),
                            x + xx, y + yy, z + zz, r, g, b)
                    end
                end
            end
        end
        Placement.RenderTooltip(self)
    end

    function class:tryBuild(x, y, z)
        if self.placed or not self.canBeBuild then return false end
        local square = self.square or getCell():getGridSquare(x, y, z)
        local target = {
            x = call(square, "getX") or x,
            y = call(square, "getY") or y,
            z = call(square, "getZ") or z,
            north = self.north == true,
            nSprite = tonumber(self.nSprite) or 1,
            sprite = self:getSprite(),
        }
        if self.onPlacement and self.onPlacement(target) == false then
            return false
        end
        self.placed = true
        local cell = getCell and getCell() or nil
        if cell and type(cell.setDrag) == "function" then
            cell:setDrag(nil, self.player or 0)
        end
        return true
    end

    function class:deactivate()
        Placement.HideTooltip(self)
        if not self.placed and self.onCancel then self.onCancel() end
    end

    function class:reinit()
        self.canBeBuild, self.build, self.square = false, false, nil
    end

    return class
end

local function createNativeCursorClass()
    if not ISBuildIsoEntity or type(ISBuildIsoEntity.derive) ~= "function" then
        return nil
    end
    local class = ISBuildIsoEntity:derive("ISPNCBuildPlacementCursor")
    local nativeIsValid = class.isValid
    local nativeRender = class.render

    function class:isValid(square)
        if nativeIsValid then
            local ok, valid = pcall(nativeIsValid, self, square)
            if not ok or valid == false then
                return setEngineInvalid(self, square)
            end
        end
        return setBoundaryValidity(self, square)
    end

    function class:render(x, y, z, square)
        local result = nativeRender(self, x, y, z, square)
        Placement.RenderTooltip(self)
        return result
    end

    function class:getSprite()
        local spriteName = firstSpriteName(self)
        self.chosenSprite = spriteName
        return spriteName
    end

    function class:tryBuild(x, y, z)
        if self.placed then return false end
        local square = getCell():getGridSquare(x, y, z)
        if not square or not self:isValid(square) then return false end
        local target = {
            x = square:getX(), y = square:getY(), z = square:getZ(),
            north = self.north == true,
            nSprite = tonumber(self.nSprite) or 1,
            sprite = self:getSprite(),
        }
        if self.onPlacement and self.onPlacement(target) == false then
            return false
        end
        self.placed = true
        if getCell() and getCell().setDrag then
            getCell():setDrag(nil, self.player or 0)
        end
        return true
    end

    function class:deactivate()
        Placement.HideTooltip(self)
        if not self.placed and self.onCancel then self.onCancel() end
    end

    return class
end

local function cursorClass()
    local native = createNativeCursorClass()
    if native then
        Placement.cursorClass = native
        ISPNCBuildPlacementCursor = native
        return native
    end
    Placement.cursorClass = Placement.cursorClass or createFallbackCursorClass()
    ISPNCBuildPlacementCursor = Placement.cursorClass
    return Placement.cursorClass
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

function Placement.Cancel(window, options)
    options = type(options) == "table" and options or {}
    local active = window and window.buildPlacement or nil
    local current = currentPlayer()
    local cell = getCell and getCell() or nil
    if active and cell and type(cell.setDrag) == "function" then
        local playerNum = active.player
        if playerNum == nil and current then
            playerNum = current:getPlayerNum()
        end
        active.pncSuppressPlacementRestore = options.restorePrevious == false
        cell:setDrag(nil, playerNum or 0)
        active.pncSuppressPlacementRestore = nil
    end
    Placement.HideTooltip(active)
    if Placement.activeCursor == active then Placement.activeCursor = nil end
    if window then window.buildPlacement = nil end
    closeFacilityPlacementUI(active, options.restorePrevious ~= false)
    Placement.lastError = nil
end

function Placement.Begin(window, recipe)
    local class = cursorClass()
    if not window or not recipe or not class then
        return fail("PLACEMENT_UNAVAILABLE")
    end
    local character = currentPlayer()
    if not character then return fail("PLAYER_UNAVAILABLE") end
    Placement.Cancel(window)

    local descriptor = PNC.BuildRecipeCatalog
        and PNC.BuildRecipeCatalog.Get(recipe.objectInfoName)
    local info = descriptor and descriptor.nativeObjectInfo or nil
    if not info and SpriteConfigManager
        and SpriteConfigManager.GetObjectInfo
    then
        info = SpriteConfigManager.GetObjectInfo(recipe.objectInfoName)
    end
    if not info then return fail("BUILD_RECIPE_NOT_FOUND") end

    -- ISBuildIsoEntity creates a BaseCraftingLogic when no logic is passed.
    -- That constructor calls setContainers, so the native cursor must receive
    -- the same container list as the vanilla build menu. Passing nil here
    -- causes a Java-side NPE before the placement cursor can be shown.
    local containers
    if not ISInventoryPaneContextMenu then
        -- This module is supplied by the vanilla client, but the fallback
        -- cursor also runs in headless/test contexts where it is absent.
        pcall(require, "ISUI/ISInventoryPaneContextMenu")
    end
    if ISInventoryPaneContextMenu
        and type(ISInventoryPaneContextMenu.getContainers) == "function"
    then
        containers = ISInventoryPaneContextMenu.getContainers(character)
    end
    local cursor = class.new(class, character, info, 1, containers, nil)
    if not cursor then return fail("PLACEMENT_CURSOR_FAILED") end
    cursor.pncPlacement = true
    cursor.player = character:getPlayerNum()
    cursor.character = character
    cursor.recipeKey = recipe.recipeKey
    cursor.objectInfoName = recipe.objectInfoName
    cursor.haveMaterial = function() return true end
    cursor.skipBuildAction = true
    cursor.dragNilAfterPlace = true
    cursor.pncFacilityPlacement = recipe.facilityDefinitionId ~= nil
    cursor.onPlacement = function(target)
        local valid, reason = Policy.ValidateCurrentFootprint(
            cursor.pncFootprint)
        if not valid then
            fail(reason)
            cursor.canBeBuild = false
            return false
        end
        local options = {
            recipeKey = cursor.recipeKey,
            objectInfoName = cursor.objectInfoName,
            x = target.x, y = target.y, z = target.z,
            north = target.north, nSprite = target.nSprite,
            sprite = target.sprite,
        }
        if recipe.facilityDefinitionId then
            options.facilityDefinitionId = recipe.facilityDefinitionId
            options.facilityBaseId = recipe.facilityBaseId
            options.facilityExpectedRevision =
                recipe.facilityExpectedRevision
        end
        PNC.Client.RequestColonyAction("building_queue", options)
        Placement.HideTooltip(cursor)
        if Placement.activeCursor == cursor then Placement.activeCursor = nil end
        if window then window.buildPlacement = nil end
        closeFacilityPlacementUI(cursor, true)
    end
    cursor.onCancel = function()
        Placement.HideTooltip(cursor)
        if Placement.activeCursor == cursor then Placement.activeCursor = nil end
        if window then window.buildPlacement = nil end
        closeFacilityPlacementUI(cursor,
            cursor.pncSuppressPlacementRestore ~= true)
    end

    local cell = getCell and getCell() or nil
    if not cell or type(cell.setDrag) ~= "function" then
        return fail("PLACEMENT_CELL_UNAVAILABLE")
    end
    window.buildPlacement = cursor
    Placement.activeCursor = cursor
    cell:setDrag(cursor, cursor.player)
    if cursor.pncFacilityPlacement then
        local placementUI = require
            "PNC/UI/Communities/ColonyManagement/PNC_BuildingPlacementModal"
        if placementUI and placementUI.Open then
            placementUI.Open({
                onBack = function()
                    Placement.Cancel(window, { restorePrevious = false })
                    local buildUI = PNC and PNC.FacilityBuildUI or nil
                    if buildUI and buildUI.Reopen then
                        buildUI.Reopen()
                    elseif buildUI and buildUI.RestorePrevious then
                        buildUI.RestorePrevious()
                    end
                end,
            })
        end
    end
    Placement.lastError = nil
    return true
end

return Placement
