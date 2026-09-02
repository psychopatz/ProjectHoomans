if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.BuildingService = PNC.BuildingService or {}
PNC.BuildingServiceInternal = PNC.BuildingServiceInternal or {}

local Service = PNC.BuildingService
local H = PNC.BuildingServiceInternal
local Catalog = PNC.BuildRecipeCatalog
local Repository = PNC.WorkRepository
local Definitions = PNC.WorkDefinitions

function H.BuilderFor(order)
    local live = order.workerId and PNC.Registry
        and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(order.workerId) or nil
    if live and type(live.isBuildCheat) == "function"
        and type(live.getPerkLevel) == "function"
    then return live end
    local onlineID = order.payload and order.payload.requesterOnlineID
    if onlineID and getPlayerByOnlineID then
        local ok, player = pcall(getPlayerByOnlineID, onlineID)
        if ok and player then return player end
    end
    if getSpecificPlayer then return getSpecificPlayer(0) end
    return nil
end

function H.PlayerNumberFor(builder)
    if builder and type(builder.getPlayerNum) == "function" then
        local ok, playerNumber = pcall(builder.getPlayerNum, builder)
        if ok and playerNumber ~= nil then
            return tonumber(playerNumber) or 0
        end
    end
    return 0
end

function H.FakeRecipeData(builder, descriptor)
    local recorded = ArrayList and ArrayList.new and ArrayList.new() or nil
    local seen = {}
    local inventory = builder and builder.getInventory
        and builder:getInventory() or nil
    local items = inventory and inventory.getItems
        and inventory:getItems() or nil
    if recorded and items and items.size and items.get then
        for _, requirement in ipairs(descriptor.requirements or {}) do
            local needed = math.max(1, math.floor(
                tonumber(requirement.amount) or 1))
            for index = 0, items:size() - 1 do
                if needed <= 0 then break end
                local item = items:get(index)
                local fullType = item and item.getFullType
                    and tostring(item:getFullType()) or ""
                local matches = false
                for _, candidate in ipairs(requirement.itemTypes or {}) do
                    if fullType == tostring(candidate) then
                        matches = true; break
                    end
                end
                if matches and not seen[item] then
                    seen[item] = true
                    recorded:add(item)
                    needed = needed - 1
                end
            end
        end
    end
    return {
        luaCallOnCreate = function() end,
        processDestroyAndUsedItems = function() end,
        getAllRecordedConsumedItems = function() return recorded end,
        getAllConsumedItems = function() return recorded end,
        getAllInputItems = function() return recorded end,
        getRecipe = function() return descriptor.nativeRecipe end,
    }
end

function H.Place(order)
    local payload = order.payload or {}
    local blueprint = payload.blueprint or {}
    if payload.placed == true then return true end
    local descriptor = Catalog.Get(blueprint.objectInfoName)
    local base = PNC.BaseService.Get(order.baseId)
    if not H.TargetValid(base, blueprint, descriptor) then
        return false, "BUILD_TARGET_OUTSIDE_BASE"
    end
    local info = descriptor and descriptor.nativeObjectInfo or nil
    local builder = H.BuilderFor(order)
    if not info or not builder then return false, "BUILD_REQUIRES_LIVE_BUILDER" end
    if not ISBuildIsoEntity then
        pcall(require, "BuildingObjects/ISBuildIsoEntity")
    end
    if not ISBuildIsoEntity then return false, "BUILD_ENGINE_UNAVAILABLE" end
    local data = H.FakeRecipeData(builder, descriptor)
    local logic = {
        startCraftAction = function() end,
        performCurrentRecipe = function() return true end,
        getRecipeDataInProgress = function() return data end,
        getRecipeData = function() return data end,
        getAllConsumedItems = function() return nil end,
    }
    local ok, cursor = pcall(ISBuildIsoEntity.new, ISBuildIsoEntity,
        builder, info, blueprint.nSprite or 1, nil, logic)
    if not ok or not cursor then return false, "BUILD_CURSOR_CREATE_FAILED" end
    -- ISBuildIsoEntity uses character on the server and player on the client
    -- when calculating the completed object's health. Keep both contexts
    -- valid because this completion path can cross the vanilla boundary.
    cursor.character = builder
    if cursor.player == nil or cursor.player == false then
        cursor.player = H.PlayerNumberFor(builder)
    end
    cursor.modData = {}
    cursor.updateModData = function() end
    cursor.blockBuild = false
    cursor.nSprite = blueprint.nSprite or 1
    cursor:getSprite()
    local created, result = pcall(cursor.create, cursor, blueprint.x,
        blueprint.y, blueprint.z, blueprint.north == true, blueprint.sprite)
    if not created or result == false then
        return false, "BUILD_PLACEMENT_FAILED"
    end
    payload.placed = true
    Repository.MarkDirty()
    return true
end
