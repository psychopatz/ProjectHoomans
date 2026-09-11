require "PNC/00_PNC_Init"

PNC = PNC or {}

-- Project Hoomans-specific mapping for the generic PsychopatzCore tooltip.
-- Core owns state interpretation, rendering, and lifecycle; this module only
-- describes Hoomans' list layout and metadata providers.
local Options = {}

Options.adapter = {
    lists = function(window)
        if window and window.storageList then return { window.storageList } end
        local lists = {}
        if window and window.playerList then
            lists[#lists + 1] = window.playerList
        end
        if window and window.npcList then
            lists[#lists + 1] = window.npcList
        end
        return lists
    end,
    hoveredIndex = function(list)
        return list and list.hoveredRowIndex and list:hoveredRowIndex() or nil
    end,
    rowAt = function(list, index)
        return list and index and list.items and list.items[index]
            and list.items[index].item or nil
    end,
    playerFor = function(list)
        if list and list.role == "player" then
            return getSpecificPlayer and getSpecificPlayer(0)
                or getPlayer and getPlayer() or nil
        end
        return nil
    end,
    isSuppressed = function(window)
        return window and window.dragState ~= nil
    end,
}

Options.modelOptions = {
    metadataProvider = function(fullType)
        local model = PNC.InventoryUIModel
        if model and type(model.Probe) == "function" then
            return model.Probe(fullType)
        end
        return nil
    end,
    itemProfileProvider = function(fullType)
        local inventory = PNC.Inventory
        if inventory and type(inventory.GetItemDefinitionProfile) == "function" then
            return inventory.GetItemDefinitionProfile(fullType)
        end
        return nil
    end,
    foodProfileProvider = function(fullType)
        local inventory = PNC.Inventory
        if inventory and type(inventory.GetFoodProfile) == "function" then
            return inventory.GetFoodProfile(fullType)
        end
        return nil
    end,
    translate = function(key, fallback)
        local value = getText and getText(key) or nil
        if value and value ~= "" and value ~= key then return value end
        return fallback
    end,
}

return Options
