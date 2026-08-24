local Placement = {}

local function call(object, method, ...)
    if not object or type(object[method]) ~= "function" then return nil end
    local ok, value = pcall(object[method], object, ...)
    return ok and value or nil
end

local function currentPlayer()
    return getSpecificPlayer and getSpecificPlayer(0) or nil
end

local function fail(reason)
    Placement.lastError = reason
    if PNC and PNC.Core and PNC.Core.LogWarn then
        PNC.Core.LogWarn("building placement failed: " .. tostring(reason))
    end
    return false, reason
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
        if not square then return false end
        local world = getWorld and getWorld() or nil
        if world and type(world.isValidSquare) == "function" then
            local x = call(square, "getX")
            local y = call(square, "getY")
            local z = call(square, "getZ")
            local valid = call(world, "isValidSquare", x, y, z)
            if valid == false then return false end
        end
        return true
    end

    function class:render(x, y, z, square)
        self.square = square
        self.canBeBuild = self:isValid(square)
        local face = self:getFace()
        if not face then return end
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
    end

    function class:tryBuild(x, y, z)
        if self.placed or not self.canBeBuild then return false end
        self.placed = true
        local square = self.square or getCell():getGridSquare(x, y, z)
        local target = {
            x = call(square, "getX") or x,
            y = call(square, "getY") or y,
            z = call(square, "getZ") or z,
            north = self.north == true,
            nSprite = tonumber(self.nSprite) or 1,
            sprite = self:getSprite(),
        }
        if self.onPlacement then self.onPlacement(target) end
        local cell = getCell and getCell() or nil
        if cell and type(cell.setDrag) == "function" then
            cell:setDrag(nil, self.player or 0)
        end
        return true
    end

    function class:deactivate()
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

    function class:getSprite()
        local spriteName = firstSpriteName(self)
        self.chosenSprite = spriteName
        return spriteName
    end

    function class:tryBuild(x, y, z)
        if self.placed then return false end
        local square = getCell():getGridSquare(x, y, z)
        if not square or not self:isValid(square) then return false end
        self.placed = true
        local target = {
            x = square:getX(), y = square:getY(), z = square:getZ(),
            north = self.north == true,
            nSprite = tonumber(self.nSprite) or 1,
            sprite = self:getSprite(),
        }
        if self.onPlacement then self.onPlacement(target) end
        if getCell() and getCell().setDrag then
            getCell():setDrag(nil, self.player or 0)
        end
        return true
    end

    function class:deactivate()
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
    if Placement.eventsInstalled or not Events then return end
    if Events.OnDoTileBuilding2 and Events.OnDoTileBuilding2.Add then
        Events.OnDoTileBuilding2.Add(onDoTileBuilding)
        Placement.eventsInstalled = true
    end
end

installPlacementEvents()
if Events and Events.OnGameStart and Events.OnGameStart.Add then
    Events.OnGameStart.Add(installPlacementEvents)
end

function Placement.Cancel(window)
    local active = window and window.buildPlacement or nil
    local current = currentPlayer()
    local cell = getCell and getCell() or nil
    if active and cell and type(cell.setDrag) == "function" then
        local playerNum = active.player
        if playerNum == nil and current then
            playerNum = current:getPlayerNum()
        end
        cell:setDrag(nil, playerNum or 0)
    end
    if window then window.buildPlacement = nil end
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
        local ok, resolved = pcall(SpriteConfigManager.GetObjectInfo,
            recipe.objectInfoName)
        info = ok and resolved or nil
    end
    if not info then return fail("BUILD_RECIPE_NOT_FOUND") end

    local ok, cursor = pcall(class.new, class, character, info, 1, nil, nil)
    if not ok or not cursor then return fail("PLACEMENT_CURSOR_FAILED") end
    cursor.pncPlacement = true
    cursor.player = character:getPlayerNum()
    cursor.character = character
    cursor.recipeKey = recipe.recipeKey
    cursor.objectInfoName = recipe.objectInfoName
    cursor.haveMaterial = function() return true end
    cursor.skipBuildAction = true
    cursor.dragNilAfterPlace = true
    cursor.onPlacement = function(target)
        local options = {
            recipeKey = cursor.recipeKey,
            objectInfoName = cursor.objectInfoName,
            x = target.x, y = target.y, z = target.z,
            north = target.north, nSprite = target.nSprite,
            sprite = target.sprite,
        }
        PNC.Client.RequestColonyAction("building_queue", options)
        if window then window.buildPlacement = nil end
    end
    cursor.onCancel = function()
        if window then window.buildPlacement = nil end
    end

    local cell = getCell and getCell() or nil
    if not cell or type(cell.setDrag) ~= "function" then
        return fail("PLACEMENT_CELL_UNAVAILABLE")
    end
    window.buildPlacement = cursor
    local dragOk = pcall(cell.setDrag, cell, cursor, cursor.player)
    if not dragOk then
        window.buildPlacement = nil
        return fail("PLACEMENT_DRAG_FAILED")
    end
    Placement.lastError = nil
    return true
end

return Placement
