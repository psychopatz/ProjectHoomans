function ISPNCInventoryList:selectedRow()
    local entry = self.items and self.items[self.selected or 0] or nil
    return entry and entry.item or nil
end

function ISPNCInventoryList:setContentOpacity(alpha)
    self.contentOpacity = math.max(0.1, math.min(1, tonumber(alpha) or 1))
    return self.contentOpacity
end

-- PZ sends list callbacks with coordinates that can be stale when the list is
-- inside a resized/scrolling parent.  The native list itself resolves the
-- current cursor through getMouseX/Y for hover handling, so use that same
-- coordinate space for selection and catalog cells.  This is especially
-- important for the Base building catalog, which is refreshed while the

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
    -- Use the base-game favorite glyph so recipe rows and inventory rows
    -- present favorites consistently with the native build menu.
    o.favoriteStar = getTexture
        and getTexture("media/ui/inventoryPanes/FavouriteYes.png") or nil
    o.treeExpanded = getTexture
        and getTexture("media/ui/inventoryPanes/Button_TreeExpanded.png") or nil
    o.treeCollapsed = getTexture
        and getTexture("media/ui/inventoryPanes/Button_TreeCollapsed.png") or nil
    return o
end

return ISPNCInventoryList
