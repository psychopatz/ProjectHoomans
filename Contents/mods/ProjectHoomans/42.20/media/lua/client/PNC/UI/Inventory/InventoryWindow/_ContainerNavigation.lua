local Helpers = require "PNC/UI/Inventory/InventoryWindow/_Helpers"
local tr = Helpers.tr
local getTooltipHost = Helpers.getTooltipHost

function ISPNCInventoryWindow:toggleInventoryGroup(role, groupKey)
    if not groupKey then return false end
    local groups = role == "player"
        and self.expandedPlayerGroups or self.expandedNPCGroups
    groups[groupKey] = groups[groupKey] ~= true
    self.contextSignature = nil
    self:refreshInventory(true)
    return true
end

function ISPNCInventoryWindow:onInventoryHover(list)
    getTooltipHost().OnHover(self, list)
end

function ISPNCInventoryWindow:onInventoryHoverOutside(list)
    if self.psychopatzInventoryTooltipList == list then
        self.psychopatzInventoryTooltipList = nil
    end
    getTooltipHost().Update(self)
end

function ISPNCInventoryWindow:updateInventoryTooltip()
    getTooltipHost().Update(self)
end

function ISPNCInventoryWindow:getSelectedContainer(role)
    if role == "player" then return self.selectedPlayerContainer end
    return self.selectedNPCContainer
end

function ISPNCInventoryWindow:selectContainer(role, containerID)
    if not containerID then return false end
    if role == "player" then
        self.selectedPlayerContainer = containerID
    else
        self.selectedNPCContainer = containerID
    end
    self:refreshInventory(true)
    return true
end

function ISPNCInventoryWindow:cycleContainer(role, delta)
    local containers = role == "player" and self.playerContainers or self.npcContainers
    local current = role == "player" and self.selectedPlayerContainer or self.selectedNPCContainer
    if not containers or #containers < 2 then return end
    local nextID = delta and delta < 0
        and containers[#containers].id
        or containers[1].id
    for index = 1, #containers do
        if tostring(containers[index].id) == tostring(current) then
            if delta and delta < 0 then
                nextID = containers[((index - 2) % #containers) + 1].id
            else
                nextID = containers[(index % #containers) + 1].id
            end
            break
        end
    end
    self:selectContainer(role, nextID)
end

return ISPNCInventoryWindow
