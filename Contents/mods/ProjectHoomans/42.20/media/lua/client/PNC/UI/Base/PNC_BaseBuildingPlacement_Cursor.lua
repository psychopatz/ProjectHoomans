local Cursor = {}
local Placement
local setBoundaryValidity
local setEngineInvalid

local function call(object, method, ...)
    if not object or type(object[method]) ~= "function" then return nil end
    local ok, value = pcall(object[method], object, ...)
    return ok and value or nil
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

function Cursor.Create(owner, validate, engineInvalid)
    Placement = owner
    setBoundaryValidity = validate
    setEngineInvalid = engineInvalid
    return cursorClass()
end

return Cursor
