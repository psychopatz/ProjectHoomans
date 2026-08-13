-- Inventory network adapter. Inventory mutation remains in ServerInventory.

local Router = PNC.ServerCommandRouter
local Const = PNC.Const

Router.Register(Const.CMD_INVENTORY_TRANSFER, function(player, args)
    local inventory = PNC.ServerInventory
    if inventory and inventory.Transfer then
        inventory.Transfer(player, args)
    end
end)

Router.Register(Const.CMD_INVENTORY_ACTION, function(player, args)
    local inventory = PNC.ServerInventory
    if inventory and inventory.Action then
        inventory.Action(player, args)
    end
end)
