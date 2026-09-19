function ISPNCInventoryList:resolveMouse(x, y)
    if type(self.getMouseX) == "function"
        and type(self.getMouseY) == "function"
    then
        local mouseX = tonumber(self:getMouseX())
        local mouseY = tonumber(self:getMouseY())
        if mouseX and mouseY then
            return mouseX, mouseY
        end
    end
    return tonumber(x) or 0, tonumber(y) or 0
end

function ISPNCInventoryList:hoveredRowIndex()
    if not self.isMouseOver or not self:isMouseOver() then return -1 end
    if self.isMouseOverScrollBar and self:isMouseOverScrollBar() then
        return -1
    end
    local inputX, inputY = self:resolveMouse(
        self.getMouseX and self:getMouseX() or 0,
        self.getMouseY and self:getMouseY() or 0
    )
    return self:rowAt(inputX, inputY)
end

function ISPNCInventoryList:onMouseMove(dx, dy)
    if ISScrollingListBox.onMouseMove then
        ISScrollingListBox.onMouseMove(self, dx, dy)
    end
    if self.ownerWindow and self.ownerWindow.onInventoryHover then
        self.ownerWindow:onInventoryHover(self)
    end
end

function ISPNCInventoryList:onMouseMoveOutside(x, y)
    if ISScrollingListBox.onMouseMoveOutside then
        ISScrollingListBox.onMouseMoveOutside(self, x, y)
    end
    if self.ownerWindow and self.ownerWindow.onInventoryHoverOutside then
        self.ownerWindow:onInventoryHoverOutside(self)
    end
end

function ISPNCInventoryList:onMouseDown(x, y)
    local inputX, inputY = self:resolveMouse(x, y)
    if ISScrollingListBox.onMouseDown then
        ISScrollingListBox.onMouseDown(self, inputX, inputY)
    end
    local row = self:selectedRow()
    if row and self.ownerWindow then
        if row.groupHeader and inputX <= 16
            and self.ownerWindow.toggleInventoryGroup
        then
            self.ownerWindow:toggleInventoryGroup(self.role, row.groupKey)
        elseif type(self.catalogColumns) == "table"
            and type(row.catalogCells) == "table" and row.catalogHeader ~= true
            and self.onCatalogCell
        then
            local index
            for index = #self.catalogColumns, 1, -1 do
                local column = self.catalogColumns[index]
                local left = math.floor(self.width * (tonumber(column.x) or 0))
                if inputX >= left then
                    local nextColumn = self.catalogColumns[index + 1]
                    local right = nextColumn and math.floor(self.width
                        * (tonumber(nextColumn.x) or 1)) or self.width
                    self.onCatalogCell(self.ownerWindow, row, column.key,
                        inputX - left, math.max(1, right - left))
                    return true
                end
            end
        elseif self.ownerWindow.onInventoryRowClick then
            self.ownerWindow:onInventoryRowClick(self.role, row)
        elseif self.selectOnly ~= true and row.restricted ~= true
            and self.ownerWindow.beginInventoryDrag
        then
            self.ownerWindow:beginInventoryDrag(self.role, row)
        end
    end
    return true
end

function ISPNCInventoryList:onMouseUp(x, y)
    if ISScrollingListBox.onMouseUp then
        ISScrollingListBox.onMouseUp(self, x, y)
    end
    if self.ownerWindow and self.ownerWindow.completeInventoryDrop then
        self.ownerWindow:completeInventoryDrop(self.role)
    end
    return true
end

function ISPNCInventoryList:onMouseUpOutside(x, y)
    if ISScrollingListBox.onMouseUpOutside then
        ISScrollingListBox.onMouseUpOutside(self, x, y)
    end
    if self.ownerWindow and self.ownerWindow.completeInventoryDropAtMouse then
        self.ownerWindow:completeInventoryDropAtMouse()
    end
    return true
end

function ISPNCInventoryList:onRightMouseUp(x, y)
    local inputX, inputY = self:resolveMouse(x, y)
    if ISScrollingListBox.onMouseDown then
        ISScrollingListBox.onMouseDown(self, inputX, inputY)
    end
    local row = self:selectedRow()
    if row and self.ownerWindow and self.ownerWindow.showItemContext then
        self.ownerWindow:showItemContext(self.role, row)
        return true
    end
    return false
end

return ISPNCInventoryList
