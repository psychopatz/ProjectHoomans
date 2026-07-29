require "ISUI/ISScrollingListBox"
require "ISUI/ISContextMenu"

PNC = PNC or {}

ISPNCInventoryList = ISScrollingListBox:derive("ISPNCInventoryList")

function ISPNCInventoryList:doDrawItem(y, listItem, alt)
    local row = listItem and listItem.item or nil
    if not row then return y + self.itemheight end
    local selected = self.selected == listItem.index
    local stripe = (listItem.index or 0) % 2 == 0
    local dimmed = row.restricted == true
    if selected then
        self:drawRect(0, y, self.width, self.itemheight, 0.32, 0.32, 0.36, 0.40)
    elseif stripe then
        self:drawRect(0, y, self.width, self.itemheight, 0.13, 0.13, 0.13, 0.46)
    else
        self:drawRect(0, y, self.width, self.itemheight, 0.07, 0.07, 0.07, 0.46)
    end
    local indent = row.groupHeader and 12 or row.groupChild and 12 or 0
    if row.groupHeader then
        local treeTexture = row.expanded and self.treeExpanded or self.treeCollapsed
        if treeTexture then
            self:drawTextureScaledAspect(
                treeTexture, 1, y + 9, 12, 12, 1, 1, 1, 1
            )
        end
    end
    if row.texture then
        local tint = dimmed and 0.42 or 1
        self:drawTextureScaledAspect(
            row.texture, 5 + indent, y + 3, 26, 26, 1, tint, tint, tint
        )
    end
    if row.favorite and self.favoriteStar then
        self:drawTexture(
            self.favoriteStar, 5 + indent, y + 19,
            1, dimmed and 0.42 or 1, dimmed and 0.42 or 1,
            dimmed and 0.42 or 1
        )
    end
    if row.equipped and self.equippedItemIcon then
        self:drawTexture(
            self.equippedItemIcon, 21 + indent, y + 19,
            1, dimmed and 0.42 or 1, dimmed and 0.42 or 1,
            dimmed and 0.42 or 1
        )
    end
    local countText = row.stack and row.stack > 1
        and (" (" .. tostring(row.stack) .. ")") or ""
    local textColor = dimmed and 0.40 or 0.86
    self:drawText(
        tostring(row.name) .. countText,
        39 + indent, y + 7,
        textColor, textColor, textColor, 1, UIFont.Small
    )
    local categoryX = math.floor(self.width * 0.64)
    self:drawText(
        tostring(row.category or "Item"),
        categoryX, y + 7,
        dimmed and 0.38 or 0.64,
        dimmed and 0.38 or 0.64,
        dimmed and 0.42 or 0.82,
        1, UIFont.Small
    )
    return y + self.itemheight
end

function ISPNCInventoryList:selectedRow()
    local entry = self.items and self.items[self.selected or 0] or nil
    return entry and entry.item or nil
end

function ISPNCInventoryList:onMouseDown(x, y)
    if ISScrollingListBox.onMouseDown then
        ISScrollingListBox.onMouseDown(self, x, y)
    end
    local row = self:selectedRow()
    if row and self.ownerWindow then
        if row.groupHeader and x <= 16 then
            self.ownerWindow:toggleInventoryGroup(self.role, row.groupKey)
        elseif row.restricted ~= true then
            self.ownerWindow:beginInventoryDrag(self.role, row)
        end
    end
    return true
end

function ISPNCInventoryList:onMouseUp(x, y)
    if ISScrollingListBox.onMouseUp then
        ISScrollingListBox.onMouseUp(self, x, y)
    end
    if self.ownerWindow then
        self.ownerWindow:completeInventoryDrop(self.role)
    end
    return true
end

function ISPNCInventoryList:onMouseUpOutside(x, y)
    if ISScrollingListBox.onMouseUpOutside then
        ISScrollingListBox.onMouseUpOutside(self, x, y)
    end
    if self.ownerWindow then
        self.ownerWindow:completeInventoryDropAtMouse()
    end
    return true
end

function ISPNCInventoryList:onRightMouseUp(x, y)
    if ISScrollingListBox.onMouseDown then
        ISScrollingListBox.onMouseDown(self, x, y)
    end
    local row = self:selectedRow()
    if row and self.ownerWindow then
        self.ownerWindow:showItemContext(self.role, row)
        return true
    end
    return false
end

function ISPNCInventoryList:new(x, y, width, height, ownerWindow, role)
    local o = ISScrollingListBox:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.ownerWindow = ownerWindow
    o.role = role
    o.itemheight = 32
    o.font = UIFont.Small
    o.drawBorder = true
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.62 }
    o.borderColor = { r = 0.45, g = 0.45, b = 0.45, a = 0.9 }
    o.equippedItemIcon = getTexture and getTexture("media/ui/icon.png") or nil
    o.favoriteStar = getTexture and getTexture("media/ui/FavoriteStar.png") or nil
    o.treeExpanded = getTexture
        and getTexture("media/ui/inventoryPanes/Button_TreeExpanded.png") or nil
    o.treeCollapsed = getTexture
        and getTexture("media/ui/inventoryPanes/Button_TreeCollapsed.png") or nil
    return o
end

return ISPNCInventoryList
