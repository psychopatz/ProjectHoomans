-- Translation and row rendering helpers for the Puppet Opera beat tab.

PNC = PNC or {}

local Internal = PNC.PuppetOperaBeatsTabInternal
local Layout = Internal.Layout

local function tr(key, fallback)
    local translation = PNC.Translation
    local getter = translation and translation.GetKey
    local value = type(getter) == "function"
        and getter(key, fallback) or fallback
    if not value or value == "" or value == key then return fallback end
    return value
end

local function drawBeatItem(list, y, row, alternate)
    if type(row) ~= "table" then return y + list.itemheight end
    local beat = type(row.item) == "table" and row.item or {}
    local selected = list.selected == row.index
    if selected then
        list:drawRect(0, y, list:getWidth(), list.itemheight,
            0.35, 0.20, 0.48, 0.82)
    elseif alternate then
        list:drawRect(0, y, list:getWidth(), list.itemheight,
            0.12, 0.16, 0.18, 0.20)
    end
    list:drawText(
        tostring(row.index) .. ".  " .. tostring(beat.id),
        8, y + 5,
        0.92, 0.94, 1.00, 1, UIFont.Small
    )
    list:drawText(
        Layout.Ellipsize(
            tostring(row.summary or "No tracks assigned"),
            UIFont.Small,
            math.max(32, list:getWidth() - 16)
        ),
        8, y + 24,
        0.62, 0.82, 0.95, 1, UIFont.Small
    )
    list:drawTextRight(
        tostring(beat.durationMs or "-") .. " ms",
        list:getWidth() - 8,
        y + 5,
        0.72, 0.78, 0.84, 1, UIFont.Small
    )
    return y + list.itemheight
end

Internal.tr = tr
Internal.drawBeatItem = drawBeatItem

return ISPNCPuppetOperaBeatsTab
