local Layout = PsychopatzCore and PsychopatzCore.UI
    and PsychopatzCore.UI.Layout or nil

local function catalogColor(value, dimmed, readable)
    if dimmed then
        if readable then return 0.60, 0.63, 0.68 end
        return 0.38, 0.38, 0.42
    end
    if value == "success" then return 0.35, 0.86, 0.50 end
    if value == "warning" then return 0.96, 0.68, 0.20 end
    if value == "accent" then return 0.22, 0.78, 0.94 end
    return 0.72, 0.74, 0.78
end

local function scaledOpacity(self, value)
    local multiplier = tonumber(self.contentOpacity) or 1
    return math.max(0, math.min(1, (tonumber(value) or 0) * multiplier))
end

local function giftPreferenceText(value)
    local key
    local fallback
    if value == "like" then
        key = "UI_PNC_Inventory_GiftPreference_Like"
        fallback = "Like"
    elseif value == "dislike" then
        key = "UI_PNC_Inventory_GiftPreference_Dislike"
        fallback = "Dislike"
    else
        return nil
    end
    local text = getText and getText(key) or nil
    if type(text) == "string" and text ~= "" and text ~= key then
        return text
    end
    return fallback
end

local function catalogCellsForRow(self, row)
    if type(row.catalogCells) == "table" then
        return row.catalogCells
    end
    if type(self.catalogColumns) ~= "table" then return nil end
    local cells = {}
    for _, column in ipairs(self.catalogColumns) do
        if column.key == "category" then
            local value = row.category or "Item"
            if self.ownerWindow and self.ownerWindow.giftMode
                and self.role == "player"
            then
                value = giftPreferenceText(row.giftPreference) or value
            end
            cells[column.key] = value
        elseif column.key == "quantity"
            or column.key == "availability"
        then
            cells[column.key] = row.stack
        end
    end
    return cells
end

local function drawCatalogColumns(self, y, row, dimmed, cells)
    local columns = self.catalogColumns
    if type(columns) ~= "table" or type(cells) ~= "table" then
        return false
    end
    local contentWidth = self.catalogContentWidth
        and self:catalogContentWidth() or self.width
    local index
    for index = 1, #columns do
        local column = columns[index]
        local value = cells[column.key]
        local x = math.floor(contentWidth * (tonumber(column.x) or 0))
        local nextColumn = columns[index + 1]
        local right = nextColumn and math.floor(contentWidth
            * (tonumber(nextColumn.x) or 1)) or contentWidth
        local available = math.max(1, right - x - 4)
        local r, g, b = catalogColor(row.catalogColors
            and row.catalogColors[column.key], dimmed,
            self.readableRestricted == true)
        local controls = row.catalogControls
            and row.catalogControls[column.key]
        if type(controls) ~= "table" then
            local text = tostring(value or "")
            if Layout and Layout.Ellipsize then
                text = Layout.Ellipsize(text, UIFont.Small, available)
            end
            self:drawText(text, x, y + 7,
                r, g, b, 1, UIFont.Small)
        end
    end
    return true
end

function ISPNCInventoryList:doDrawItem(y, listItem, alt)
    local row = listItem and listItem.item or nil
    if not row then return y + self.itemheight end
    local selected = self.selected == listItem.index
    local stripe = (listItem.index or 0) % 2 == 0
    local skillHeader = row.skillHeader == true
    local stationHeader = row.stationHeader == true
    -- Group rows are navigational headers, not unavailable inventory items.
    -- Keep them readable even when their child rows are restricted.
    local dimmed = row.restricted == true and row.groupHeader ~= true
    if selected then
        self:drawRect(0, y, self.width, self.itemheight,
            scaledOpacity(self, 0.32), 0.32, 0.36, 0.40)
    elseif skillHeader then
        self:drawRect(0, y, self.width, self.itemheight,
            scaledOpacity(self, 0.18), 0.08, 0.25, 0.18)
    elseif stationHeader then
        self:drawRect(0, y, self.width, self.itemheight,
            scaledOpacity(self, 0.16), 0.08, 0.15, 0.22)
    elseif stripe then
        self:drawRect(0, y, self.width, self.itemheight,
            scaledOpacity(self, 0.13), 0.13, 0.13, 0.46)
    else
        self:drawRect(0, y, self.width, self.itemheight,
            scaledOpacity(self, 0.07), 0.07, 0.07, 0.46)
    end
    if skillHeader then
        self:drawRect(0, y, 3, self.itemheight,
            scaledOpacity(self, 0.70), 0.25, 0.86, 0.50)
    elseif stationHeader then
        local red, green, blue = 0.28, 0.68, 0.92
        if row.stationMissing or row.stationStatus == "unresolved" then
            red, green, blue = 0.96, 0.68, 0.20
        end
        self:drawRect(0, y, 3, self.itemheight,
            scaledOpacity(self, 0.80), red, green, blue)
    end
    local indent = skillHeader and 12
        or stationHeader and 28
        or row.groupChild and 42 or 0
    if row.groupHeader then
        local treeTexture = row.expanded and self.treeExpanded or self.treeCollapsed
        if treeTexture then
            self:drawTextureScaledAspect(
                treeTexture, stationHeader and 15 or 1, y + 9,
                12, 12, 1, 1, 1, 1
            )
        end
    end
    if row.texture then
        local tint = dimmed and (self.readableRestricted and 0.62 or 0.42)
            or 1
        self:drawTextureScaledAspect(
            row.texture, 5 + indent, y + 3, 26, 26, 1, tint, tint, tint
        )
    end
    if row.favorite and self.favoriteStar then
        self:drawTexture(
            self.favoriteStar, 5 + indent, y + 19,
            1, dimmed and (self.readableRestricted and 0.62 or 0.42) or 1,
            dimmed and (self.readableRestricted and 0.62 or 0.42) or 1,
            dimmed and (self.readableRestricted and 0.62 or 0.42) or 1
        )
    end
    if row.equipped and self.equippedItemIcon then
        self:drawTexture(
            self.equippedItemIcon, 21 + indent, y + 19,
            1, dimmed and (self.readableRestricted and 0.62 or 0.42) or 1,
            dimmed and (self.readableRestricted and 0.62 or 0.42) or 1,
            dimmed and (self.readableRestricted and 0.62 or 0.42) or 1
        )
    end
    local countText = row.stack and row.stack > 1
        and (" (" .. tostring(row.stack) .. ")") or ""
    local textRed, textGreen, textBlue
    if skillHeader then
        textRed, textGreen, textBlue = 0.92, 0.96, 0.94
    elseif stationHeader then
        if row.stationMissing or row.stationStatus == "unresolved" then
            textRed, textGreen, textBlue = 1.00, 0.76, 0.28
        else
            textRed, textGreen, textBlue = 0.68, 0.86, 0.96
        end
    else
        textRed, textGreen, textBlue = dimmed
            and (self.readableRestricted and 0.62 or 0.40) or 0.86,
            dimmed and (self.readableRestricted and 0.62 or 0.40) or 0.86,
            dimmed and (self.readableRestricted and 0.68 or 0.46) or 0.92
    end
    local catalogCells = catalogCellsForRow(self, row)
    local custom = drawCatalogColumns(self, y, row, dimmed, catalogCells)
    local contentWidth = self.catalogContentWidth
        and self:catalogContentWidth() or self.width
    local categoryX = math.floor(contentWidth * 0.64)
    local nameWidth = math.max(1, self.width - 49 - indent)
    if custom and self.catalogColumns[1] then
        local firstColumnX = math.floor(contentWidth
            * (tonumber(self.catalogColumns[1].x) or 1))
        nameWidth = math.max(1, firstColumnX - 43 - indent)
    elseif not custom then
        nameWidth = math.max(1, categoryX - 43 - indent)
    end
    local name = tostring(row.name) .. countText
    if Layout and Layout.Ellipsize then
        name = Layout.Ellipsize(name, UIFont.Small, nameWidth)
    end
    self:drawText(
        name,
        39 + indent, y + 7,
        textRed, textGreen, textBlue, 1, UIFont.Small
    )
    local preferenceColumn = not custom and self.ownerWindow
        and self.ownerWindow.giftMode and self.role == "player"
    if preferenceColumn then
        local preference = tostring(row.giftPreference or "")
        local preferenceLabel = giftPreferenceText(preference)
        if preferenceLabel then
            local red, green, blue = 0.50, 0.92, 0.70
            if preference == "dislike" then
                red, green, blue = 0.94, 0.48, 0.48
            end
            self:drawText(
                preferenceLabel, categoryX, y + 7,
                red, green, blue, 1, UIFont.Small
            )
        end
    elseif not custom then
        local category = tostring(row.category or "Item")
        if Layout and Layout.Ellipsize then
            category = Layout.Ellipsize(category, UIFont.Small,
                math.max(1, contentWidth - categoryX - 4))
        end
        self:drawText(
            category,
            categoryX, y + 7,
            dimmed and (self.readableRestricted and 0.60 or 0.38)
                or 0.64,
            dimmed and (self.readableRestricted and 0.60 or 0.38)
                or 0.64,
            dimmed and (self.readableRestricted and 0.64 or 0.42)
                or 0.82,
            1, UIFont.Small
        )
    end
    return y + self.itemheight
end

return ISPNCInventoryList
