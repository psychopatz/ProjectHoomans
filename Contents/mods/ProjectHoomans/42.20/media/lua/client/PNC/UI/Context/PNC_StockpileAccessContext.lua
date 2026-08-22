PNC = PNC or {}

local GridRegion = require "PsychopatzCore/World/PC_GridRegion"

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local function identity(object)
    local data = object and object.getModData and object:getModData() or nil
    local value = data and data.PNC or nil
    return type(value) == "table" and value.type == "stockpileAccess" and value or nil
end

local function findNode(nodeId)
    local settlement = PNC.Network and PNC.Network.ClientState
        and PNC.Network.ClientState.colonyManagement
        and PNC.Network.ClientState.colonyManagement.settlement or nil
    for _, node in ipairs(settlement and settlement.stockpileNodes or {}) do
        if tostring(node.id) == tostring(nodeId) then return node end
    end
    return nil
end

local function findNodeAtSquare(square)
    if not square then return nil end
    local settlement = PNC.Network and PNC.Network.ClientState
        and PNC.Network.ClientState.colonyManagement
        and PNC.Network.ClientState.colonyManagement.settlement or nil
    local x, y, z = square:getX(), square:getY(), square:getZ()
    for _, node in ipairs(settlement and settlement.stockpileNodes or {}) do
        local radius = math.max(1, tonumber(node.radius) or 2)
        if tonumber(node.z) == z
            and math.abs((tonumber(node.x) or 0) - x) <= radius
            and math.abs((tonumber(node.y) or 0) - y) <= radius
        then
            return node
        end
    end
    return nil
end

local function findStockpileAtSquare(square)
    if not square then return nil end
    local settlement = PNC.Network and PNC.Network.ClientState
        and PNC.Network.ClientState.colonyManagement
        and PNC.Network.ClientState.colonyManagement.settlement or nil
    local x, y, z = square:getX(), square:getY(), square:getZ()
    for _, facility in ipairs(settlement and settlement.facilities or {}) do
        if facility.definitionId == "stockpile"
            and facility.constructionState == "BUILT"
        then
            for _, component in ipairs(facility.components or {}) do
                if component.role == "storage.stockpile" and component.region
                    and GridRegion.containsPoint(component.region, x, y, z)
                then
                    return facility
                end
            end
            if facility.constructionRegion and GridRegion.containsPoint(
                facility.constructionRegion, x, y, z)
            then
                return facility
            end
        end
    end
    return nil
end

local function openStockpile()
    local snapshot = PNC.Network and PNC.Network.ClientState
        and PNC.Network.ClientState.colonyManagement or nil
    local storage = snapshot and snapshot.storage or nil
    local access = storage and storage.access or nil
    if storage and storage.storageId and access
        and access.hasStockpile == true
    then
        local StorageUI = PNC.ColonyStorageUI
            or require "PNC/UI/Communities/PNC_ColonyStorageWindow"
        return StorageUI.Open()
    end
end

local function onFillWorldObjectContextMenu(_, context, worldObjects, test)
    if test or not context then return end
    local seen = {}
    local square = PNC.NPCSelection and PNC.NPCSelection.GetWorldSquare
        and PNC.NPCSelection.GetWorldSquare(worldObjects) or nil
    local stockpile = findStockpileAtSquare(square)
    if stockpile then
        seen[stockpile.id] = true
        context:addOption(tr("UI_PNC_Stockpile_Open", "Open Colony Storage"),
            stockpile.id, openStockpile)
    end
    local zoneNode = findNodeAtSquare(square)
    if zoneNode then
        seen[zoneNode.id] = true
        context:addOption(tr("UI_PNC_Stockpile_Open", "Open Colony Storage"),
            zoneNode.id, openStockpile)
    end
    for _, object in ipairs(worldObjects or {}) do
        local value = identity(object)
        if value and not seen[value.nodeId] then
            seen[value.nodeId] = true
            context:addOption(tr("UI_PNC_Stockpile_Open", "Open Colony Storage"),
                value.nodeId, openStockpile)
        end
    end
end

if Events and Events.OnFillWorldObjectContextMenu then
    Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
end

return { OnFillWorldObjectContextMenu = onFillWorldObjectContextMenu }
