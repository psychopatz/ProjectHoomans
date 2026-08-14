PNC = PNC or {}

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

local function openStockpile(nodeId)
    local node = findNode(nodeId)
    if node and node.storageId and PNC.InventoryWindow
        and PNC.InventoryWindow.OpenStorage
    then
        PNC.InventoryWindow.OpenStorage(node.storageId, {
            displayName = tr("UI_PNC_Storage_Colony", "Colony Storage"),
            readOnly = false,
        })
        return
    end
    if PNC.ColonyManagementUI and PNC.ColonyManagementUI.Open then
        PNC.ColonyManagementUI.Open()
    end
end

local function onFillWorldObjectContextMenu(_, context, worldObjects, test)
    if test or not context then return end
    local seen = {}
    for _, object in ipairs(worldObjects or {}) do
        local value = identity(object)
        if value and not seen[value.nodeId] then
            seen[value.nodeId] = true
            context:addOption(tr("UI_PNC_Stockpile_Open", "Access Base Inventory"),
                value.nodeId, openStockpile)
        end
    end
end

if Events and Events.OnFillWorldObjectContextMenu then
    Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
end

return { OnFillWorldObjectContextMenu = onFillWorldObjectContextMenu }
