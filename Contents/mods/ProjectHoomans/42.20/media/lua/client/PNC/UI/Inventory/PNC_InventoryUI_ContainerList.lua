require "ISUI/ISScrollingListBox"

PNC = PNC or {}

local ROOT_INVENTORY_TEXTURE = getTexture
    and getTexture("media/ui/Icon_InventoryBasic.png")
    or nil

ISPNCInventoryContainerList = ISScrollingListBox:derive("ISPNCInventoryContainerList")

function ISPNCInventoryContainerList:doDrawItem(y, listItem, alt)
    local container = listItem and listItem.item or nil
    if not container then return y + self.itemheight end

    local selectedID = self.ownerWindow
        and self.ownerWindow:getSelectedContainer(self.role)
        or nil
    local selected = tostring(selectedID or "") == tostring(container.id or "")
    if selected then
        self:drawRect(1, y + 1, self.width - 2, self.itemheight - 2,
            0.72, 0.48, 0.40, 0.24)
        self:drawRectBorder(1, y + 1, self.width - 2, self.itemheight - 2,
            0.95, 0.82, 0.68, 0.28)
    elseif (listItem.index or 0) % 2 == 0 then
        self:drawRect(1, y + 1, self.width - 2, self.itemheight - 2,
            0.30, 0.14, 0.14, 0.14)
    end

    local texture = container.texture
    if not texture and tostring(container.id) == "root" then
        texture = ROOT_INVENTORY_TEXTURE
    end
    if texture then
        self:drawTextureScaledAspect(texture, 5, y + 4,
            self.itemheight - 8, self.itemheight - 8, 1, 1, 1, 1)
    else
        self:drawTextCentre("I", math.floor(self.width / 2), y + 10,
            0.88, 0.88, 0.88, 1, UIFont.Small)
    end
    return y + self.itemheight
end

function ISPNCInventoryContainerList:selectedContainer()
    local entry = self.items and self.items[self.selected or 0] or nil
    return entry and entry.item or nil
end

function ISPNCInventoryContainerList:onMouseDown(x, y)
    if ISScrollingListBox.onMouseDown then
        ISScrollingListBox.onMouseDown(self, x, y)
    end
    local container = self:selectedContainer()
    if container and self.ownerWindow then
        self.ownerWindow:selectContainer(self.role, container.id)
    end
    return true
end

function ISPNCInventoryContainerList:onMouseUp(x, y)
    if ISScrollingListBox.onMouseUp then
        ISScrollingListBox.onMouseUp(self, x, y)
    end
    if self.ownerWindow then
        self.ownerWindow:completeInventoryDrop(self.role)
    end
    return true
end

function ISPNCInventoryContainerList:onMouseWheel(delta)
    if self.ownerWindow then
        self.ownerWindow:cycleContainer(self.role, delta)
        return true
    end
    return false
end

function ISPNCInventoryContainerList:new(x, y, width, height, ownerWindow, role)
    local o = ISScrollingListBox:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.ownerWindow = ownerWindow
    o.role = role
    o.itemheight = 40
    o.font = UIFont.Small
    o.drawBorder = true
    o.backgroundColor = { r = 0.035, g = 0.035, b = 0.035, a = 0.78 }
    o.borderColor = { r = 0.45, g = 0.45, b = 0.45, a = 0.9 }
    return o
end

return ISPNCInventoryContainerList
