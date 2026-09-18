-- Presentation helpers for the Puppet Opera animation catalog tab.

PNC = PNC or {}

local Internal = PNC.PuppetOperaAnimationTabInternal
local Layout = Internal.Layout

local function resizeRows(list, itemHeight)
    if not list then return end
    itemHeight = math.max(1, math.floor(itemHeight))
    list.itemheight = itemHeight
    for _, item in ipairs(list.items or {}) do
        item.height = itemHeight
    end
    if list.setScrollHeight then
        list:setScrollHeight(#(list.items or {}) * itemHeight)
    end
end

local function tr(key, fallback)
    local translation = PNC.Translation
    local value = translation and translation.GetKey
        and translation.GetKey(key, fallback) or fallback
    if not value or value == "" or value == key then return fallback end
    return value
end

local function conditionText(condition)
    return tostring(condition.name or "?") .. "="
        .. tostring(condition.value or "?")
end

local function selectorText(entry)
    local values = {}
    for _, condition in ipairs(entry.conditions or {}) do
        if condition.name ~= "PNCActor" and condition.name ~= "BumpType"
        then
            values[#values + 1] = conditionText(condition)
        end
    end
    return table.concat(values, ", ")
end

local function drawCatalogItem(list, y, row, alternate)
    local entry = row.item
    local selected = list.selected == row.index
    if selected then
        list:drawRect(0, y, list:getWidth(), list.itemheight,
            0.38, 0.20, 0.48, 0.82)
    elseif alternate then
        list:drawRect(0, y, list:getWidth(), list.itemheight,
            0.12, 0.16, 0.18, 0.20)
    end
    local width = math.max(32, list:getWidth() - 16)
    local title = Layout.Ellipsize(
        tostring(entry.node or entry.file or "?"),
        UIFont.Small,
        width
    )
    local clip = Layout.Ellipsize(
        tostring(entry.anim or "(no direct clip)"),
        UIFont.Small,
        width
    )
    local selector = selectorText(entry)
    list:drawText(title, 8, y + 4,
        entry.playable and 0.92 or 0.62,
        entry.playable and 0.94 or 0.62,
        entry.playable and 1.00 or 0.62, 1, UIFont.Small)
    list:drawText(clip, 8, y + 21,
        0.62, 0.82, 0.95, 1, UIFont.Small)
    list:drawText(
        Layout.Ellipsize(
            selector ~= "" and selector or tostring(entry.path or "-"),
            UIFont.Small,
            math.max(32, list:getWidth() - 16)
        ),
        8, y + 38,
        0.66, 0.70, 0.74, 1, UIFont.Small
    )
    local approved = entry.puppetOperaApproved == true
    list:drawTextRight(
        approved and "SERVER OK" or "catalog",
        list:getWidth() - 8,
        y + 4,
        approved and 0.42 or 0.70,
        approved and 0.92 or 0.72,
        approved and 0.58 or 0.72,
        1,
        UIFont.Small
    )
    return y + list.itemheight
end

Internal.resizeRows = resizeRows
Internal.tr = tr
Internal.selectorText = selectorText
Internal.drawCatalogItem = drawCatalogItem

return ISPNCPuppetOperaAnimationTab
