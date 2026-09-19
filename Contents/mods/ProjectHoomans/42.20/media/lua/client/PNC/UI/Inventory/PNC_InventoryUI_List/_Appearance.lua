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

local function drawCatalogColumns(self, y, row, dimmed)
    local columns = self.catalogColumns
    if type(columns) ~= "table" or type(row.catalogCells) ~= "table" then
        return false
    end
    local index
    for index = 1, #columns do
        local column = columns[index]
        local value = row.catalogCells[column.key]
        local x = math.floor(self.width * (tonumber(column.x) or 0))
        local nextColumn = columns[index + 1]
        local right = nextColumn and math.floor(self.width
            * (tonumber(nextColumn.x) or 1)) or self.width
        local available = math.max(1, right - x - 4)
        local r, g, b = catalogColor(row.catalogColors
            and row.catalogColors[column.key], dimmed,
            self.readableRestricted == true)
        local text = tostring(value or "")
        if Layout and Layout.Ellipsize then
            text = Layout.Ellipsize(text, UIFont.Small, available)
        end
        self:drawText(text, x, y + 7,
            r, g, b, 1, UIFont.Small)
    end
    return true
end

function ISPNCInventoryList:doDrawItem(y, listItem, alt)
    local row = listItem and listItem.item or nil
    if not row then return y + self.itemheight end
    local selected = self.selected == listItem.index
    local stripe = (listItem.index or 0) % 2 == 0
    local dimmed = row.restricted == true
    if selected then
        self:drawRect(0, y, self.width, self.itemheight,
            scaledOpacity(self, 0.32), 0.32, 0.36, 0.40)
    elseif stripe then
        self:drawRect(0, y, self.width, self.itemheight,
            scaledOpacity(self, 0.13), 0.13, 0.13, 0.46)
    else
        self:drawRect(0, y, self.width, self.itemheight,
            scaledOpacity(self, 0.07), 0.07, 0.07, 0.46)
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
    local textColor = dimmed
        and (self.readableRestricted and 0.62 or 0.40) or 0.86
    local custom = drawCatalogColumns(self, y, row, dimmed)
    local categoryX = math.floor(self.width * 0.64)
    local nameWidth = math.max(1, self.width - 49 - indent)
    if custom and self.catalogColumns[1] then
        local firstColumnX = math.floor(self.width
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
        textColor, textColor, textColor, 1, UIFont.Small
    )
    if not custom and self.ownerWindow and self.ownerWindow.giftMode
        and self.role == "player"
        and row.giftScore
        and PNC.Gifts and PNC.Gifts.FormatShortScore
    then
        local scoreText = PNC.Gifts.FormatShortScore(row.giftScore)
        self:drawText(
            scoreText,
            categoryX,
            y + 7,
            0.50, 0.92, 0.70, 1, UIFont.Small
        )
    elseif not custom then
        local category = tostring(row.category or "Item")
        if Layout and Layout.Ellipsize then
            category = Layout.Ellipsize(category, UIFont.Small,
                math.max(1, self.width - categoryX - 4))
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
