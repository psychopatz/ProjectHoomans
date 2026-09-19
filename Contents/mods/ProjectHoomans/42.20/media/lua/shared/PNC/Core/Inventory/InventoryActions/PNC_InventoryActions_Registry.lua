-- Registry and shared execution contract for NPC inventory item actions.
local Actions = PNC.InventoryActions
local Inventory = PNC.Inventory

local function appendUnique(value)
    for index = 1, #Actions.Order do
        if Actions.Order[index] == value then return end
    end
    Actions.Order[#Actions.Order + 1] = value
end

function Actions.Register(definition)
    if type(definition) ~= "table" or not definition.id
        or type(definition.execute) ~= "function"
    then
        return false
    end
    local actionID = tostring(definition.id)
    if actionID == "" then return false end
    definition.id = actionID
    Actions.Definitions[actionID] = definition
    appendUnique(actionID)
    return true
end

function Actions.Get(actionID)
    return Actions.Definitions[tostring(actionID or "")]
end

function Actions.List()
    local output = {}
    for index = 1, #Actions.Order do
        local definition = Actions.Definitions[Actions.Order[index]]
        if definition then output[#output + 1] = definition end
    end
    return output
end

function Actions.IsAvailable(definition, record, item)
    if not definition or not item then return false end
    if type(definition.isAvailable) ~= "function" then return true end
    -- Action definitions may be registered by add-ons; isolate their
    -- availability callbacks from the inventory action dispatcher.
    local ok, available = pcall(definition.isAvailable, record, item)
    return ok and available == true
end

function Actions.Execute(actionID, player, record, itemID, context)
    local definition = Actions.Get(actionID)
    local inv = Inventory and Inventory.EnsureRecordInventory
        and Inventory.EnsureRecordInventory(record)
        or nil
    local item = inv and inv.items and inv.items[tostring(itemID or "")] or nil
    if not definition then return false, "action_not_found" end
    if not item then return false, "item_not_found" end
    if not Actions.IsAvailable(definition, record, item) then
        return false, "action_unavailable"
    end
    return definition.execute(player, record, item, context or {})
end

return Actions
