-- Reusable native buttons for catalog cells.
--
-- Rows describe controls; this component owns the native ISButton lifecycle,
-- scrolling geometry, visibility, and callback dispatch. Feature windows keep
-- ownership of the commands that a control invokes.

local UI = PsychopatzCore and PsychopatzCore.UI or nil
local Layout = UI and UI.Layout or nil
local BUTTON_GAP = 2
local ROW_PADDING = 3

local function number(value, fallback)
    value = tonumber(value)
    return value or fallback or 0
end

local function listWidth(list)
    local right = number(list.width, 0)
    local scrollbar = list.vscroll
    if scrollbar and scrollbar.getX then
        local scrollbarX = number(scrollbar:getX(), right)
        if scrollbarX > 0 then right = math.min(right, scrollbarX) end
    end
    return math.max(1, right)
end

function ISPNCInventoryList:catalogContentWidth()
    return listWidth(self)
end

function ISPNCInventoryList:catalogColumnBounds(columnIndex)
    local columns = self.catalogColumns
    local column = columns and columns[columnIndex]
    if not column then return 0, 0 end
    local nextColumn = columns[columnIndex + 1]
    local width = self:catalogContentWidth()
    local left = math.floor(width * number(column.x, 0))
    local right = nextColumn
        and math.floor(width * number(nextColumn.x, 1))
        or width
    return left, math.max(left + 1, right)
end

local function setBounds(button, x, y, width, height)
    if button.setX then button:setX(math.floor(x)) end
    if button.setY then button:setY(math.floor(y)) end
    if button.setWidth then button:setWidth(math.max(1, math.floor(width))) end
    if button.setHeight then button:setHeight(math.max(1, math.floor(height))) end
end

local function ensureControlLayer(list)
    if list.catalogControlLayer then return list.catalogControlLayer end
    if not UI or not UI.CreatePanel then return nil end

    local layer = UI.CreatePanel(list)
    layer:noBackground()
    if layer.setWantMouseEvents then layer:setWantMouseEvents(false) end
    if layer.setScrollChildren then layer:setScrollChildren(false) end
    if layer.setScrollWithParent then layer:setScrollWithParent(false) end
    if layer.bringToTop then layer:bringToTop() end
    list.catalogControlLayer = layer
    return layer
end

local function hideCatalogControls(list)
    if list.catalogControlLayer then
        list.catalogControlLayer:setVisible(false)
    end
    for _, button in ipairs(list.catalogControlButtons or {}) do
        button:setVisible(false)
    end
end

local function invalidateCatalogControls(list)
    list.catalogControlRevision = (tonumber(list.catalogControlRevision) or 0) + 1
    list.catalogControlState = nil
end

local function makeButton(list, layer, definition)
    if not UI or not UI.CreateButton then return nil end
    local button = UI.CreateButton(layer, {
        id = definition.id,
        title = definition.title,
        target = list,
        variant = definition.variant or "quiet",
        onclick = UI.ButtonCallback(function(clicked)
            return list:dispatchCatalogControl(clicked)
        end),
    })
    if button.setScrollWithParent then button:setScrollWithParent(false) end
    button:setVisible(false)
    return button
end

local function setButtonDefinition(list, button, row, columnKey,
    control, controlIndex, width)
    local title = tostring(control.title or "")
    local displayTitle = title
    local font = button.font or UIFont.Small
    local available = math.max(1, number(width, 1) - ROW_PADDING * 2)
    if Layout and Layout.Ellipsize then
        displayTitle = Layout.Ellipsize(title, font, available)
    end
    if button.setTitle then
        button:setTitle(displayTitle)
    else
        button.title = displayTitle
    end
    button.tooltip = control.tooltip
        or (displayTitle ~= title and title or nil)
    if UI.SetButtonVariant then
        UI.SetButtonVariant(button, control.variant or "quiet")
    end
    button:setEnable(control.enabled ~= false)
    button.psychopatzCatalogList = list
    button.psychopatzCatalogRow = row
    button.psychopatzCatalogColumn = columnKey
    button.psychopatzCatalogControl = control
    button.psychopatzCatalogControlIndex = controlIndex
end

local function layoutControls(left, right, controls)
    local count = #controls
    if count < 1 then return end
    local gap = BUTTON_GAP * math.max(0, count - 1)
    local available = math.max(1, right - left - ROW_PADDING * 2 - gap)
    local buttonWidth = math.max(1, math.floor(available / count))
    local x = left + ROW_PADDING
    for index = 1, count do
        local currentWidth = index == count
            and math.max(1, right - ROW_PADDING - x)
            or buttonWidth
        controls[index]._layoutX = x
        controls[index]._layoutWidth = currentWidth
        x = x + currentWidth + BUTTON_GAP
    end
end

-- Resolve the control under the cursor using the same row/column geometry as
-- the native child buttons.  The overlay is the primary input path, but the
-- list can receive the mouse event first when Project Zomboid is rebuilding
-- or scrolling the child tree.  Keeping this hit test beside the layout code
-- gives callers a deterministic fallback without duplicating geometry.
function ISPNCInventoryList:catalogControlAt(x, y)
    if type(self.catalogColumns) ~= "table"
        or type(self.rowAt) ~= "function"
    then
        return nil
    end
    local inputX = number(x, 0)
    local inputY = number(y, 0)
    local rowIndex = self:rowAt(inputX, inputY)
    local entry = self.items and self.items[rowIndex] or nil
    local row = entry and entry.item or nil
    if not row or row.catalogHeader == true then return nil end

    local defaultHeight = number(self.itemheight, 32)
    local top = self.topOfItem and self:topOfItem(rowIndex)
        or ((rowIndex - 1) * defaultHeight)
    top = number(top, (rowIndex - 1) * defaultHeight)
    local rowHeight = number(entry.height, defaultHeight)
    if inputY < top or inputY >= top + rowHeight then return nil end

    for columnIndex = #self.catalogColumns, 1, -1 do
        local column = self.catalogColumns[columnIndex]
        local left, right = self:catalogColumnBounds(columnIndex)
        if inputX >= left and inputX < right then
            local controls = row.catalogControls
                and row.catalogControls[column.key]
            if type(controls) ~= "table" then return nil end
            layoutControls(left, right, controls)
            for controlIndex, control in ipairs(controls) do
                local controlLeft = number(control._layoutX, left)
                local controlWidth = number(control._layoutWidth,
                    math.max(1, right - left))
                if inputX >= controlLeft
                    and inputX < controlLeft + controlWidth
                    and inputY >= top + ROW_PADDING
                    and inputY < top + rowHeight - ROW_PADDING
                then
                    return row, column.key, control, controlIndex
                end
            end
            return nil
        end
    end
    return nil
end

local function dispatchCatalogControlDefinition(list, row, columnKey,
    control, button)
    if not row or not columnKey or not control then return false end
    if control.enabled == false then return false end
    -- Record that a real control dispatch was attempted.  The list-level
    -- fallback uses this serial to avoid invoking a successful native button
    -- twice during the same mouse-up event.
    list.catalogControlDispatchSerial =
        (tonumber(list.catalogControlDispatchSerial) or 0) + 1
    if list.onCatalogControl then
        return list.onCatalogControl(list.ownerWindow, row, columnKey,
            control, button)
    end
    if list.ownerWindow and list.ownerWindow.onCatalogControl then
        return list.ownerWindow:onCatalogControl(row, columnKey,
            control, button)
    end
    return false
end

function ISPNCInventoryList:dispatchCatalogControl(button)
    if not button then return false end
    local row = button.psychopatzCatalogRow
    local columnKey = button.psychopatzCatalogColumn
    local control = button.psychopatzCatalogControl
    return dispatchCatalogControlDefinition(self, row, columnKey, control,
        button)
end

function ISPNCInventoryList:dispatchCatalogControlDefinition(row, columnKey,
    control, button)
    return dispatchCatalogControlDefinition(self, row, columnKey, control,
        button)
end

function ISPNCInventoryList:invalidateCatalogControls()
    invalidateCatalogControls(self)
end

-- Row mutations happen through the native list API. Mark the overlay dirty at
-- that boundary so its expensive visible-row scan runs after data changes,
-- rather than once per rendered frame.
local nativeClear = ISPNCInventoryList.clear or ISScrollingListBox.clear
local nativeAddItem = ISPNCInventoryList.addItem or ISScrollingListBox.addItem
local nativeRemoveItem = ISPNCInventoryList.removeItem
    or ISScrollingListBox.removeItem

if not ISPNCInventoryList.catalogControlLifecycleInstalled then
    if nativeClear then
        function ISPNCInventoryList:clear(...)
            local result = nativeClear(self, ...)
            invalidateCatalogControls(self)
            return result
        end
    end
    if nativeAddItem then
        function ISPNCInventoryList:addItem(...)
            local result = nativeAddItem(self, ...)
            invalidateCatalogControls(self)
            return result
        end
    end
    if nativeRemoveItem then
        function ISPNCInventoryList:removeItem(...)
            local result = nativeRemoveItem(self, ...)
            invalidateCatalogControls(self)
            return result
        end
    end
    ISPNCInventoryList.catalogControlLifecycleInstalled = true
end

local function controlState(list, columns)
    local scrollY = number(list.getYScroll and list:getYScroll() or 0, 0)
    return {
        revision = tonumber(list.catalogControlRevision) or 0,
        width = number(list.width, 0),
        height = number(list.height, 0),
        itemheight = number(list.itemheight, 32),
        scrollY = scrollY,
        columns = columns,
    }
end

local function sameControlState(left, right)
    return left and right
        and left.revision == right.revision
        and left.width == right.width
        and left.height == right.height
        and left.itemheight == right.itemheight
        and left.scrollY == right.scrollY
        and left.columns == right.columns
end

function ISPNCInventoryList:refreshCatalogControls()
    -- Reuse slots in draw order so scrolling does not allocate a button for
    -- every row visited in a large catalog.
    self.catalogControlButtons = self.catalogControlButtons or {}
    local activeCount = 0
    local columns = self.catalogColumns
    local state = controlState(self, columns)
    if sameControlState(self.catalogControlState, state) then return end
    self.catalogControlState = state
    if type(columns) ~= "table" then
        hideCatalogControls(self)
        return
    end

    local layer = ensureControlLayer(self)
    if not layer then
        hideCatalogControls(self)
        return
    end
    local contentWidth = self:catalogContentWidth()
    setBounds(layer, 0, 0, contentWidth, number(self.height, 1))

    local scrollY = state.scrollY
    local height = number(self.itemheight, 32)
    for rowIndex, entry in ipairs(self.items or {}) do
        local row = entry and entry.item or nil
        local rowControls = row and row.catalogControls or nil
        if type(rowControls) == "table"
            and (row.catalogHeader ~= true or row.stationHeader == true)
        then
            local top = self.topOfItem and self:topOfItem(rowIndex)
                or ((rowIndex - 1) * height)
            top = number(top, (rowIndex - 1) * height) + scrollY
            local rowHeight = number(entry and entry.height, height)
            if top + rowHeight >= 0 and top <= number(self.height, 0) then
                for columnIndex, column in ipairs(columns) do
                    local controls = rowControls[column.key]
                    if type(controls) == "table" and #controls > 0 then
                        local left, right = self:catalogColumnBounds(columnIndex)
                        layoutControls(left, right, controls)
                        for controlIndex, definition in ipairs(controls) do
                            activeCount = activeCount + 1
                            local button = self.catalogControlButtons[activeCount]
                            if not button then
                                button = makeButton(self, layer, definition)
                                if button then
                                    self.catalogControlButtons[activeCount] = button
                                end
                            end
                            if button then
                                setBounds(button, definition._layoutX,
                                    top + ROW_PADDING,
                                    definition._layoutWidth,
                                    math.max(1, rowHeight - ROW_PADDING * 2))
                                setButtonDefinition(self, button, row,
                                    column.key, definition, controlIndex,
                                    definition._layoutWidth)
                                button:setVisible(true)
                            end
                        end
                    end
                end
            end
        end
    end
    for index = activeCount + 1, #self.catalogControlButtons do
        self.catalogControlButtons[index]:setVisible(false)
    end
    local visible = activeCount > 0
    if not layer.getIsVisible or layer:getIsVisible() ~= visible then
        layer:setVisible(visible)
    end
end

local nativePrerender = ISPNCInventoryList.prerender
    or ISScrollingListBox.prerender

function ISPNCInventoryList:prerender()
    if nativePrerender then nativePrerender(self) end
    self:refreshCatalogControls()
end

return ISPNCInventoryList
