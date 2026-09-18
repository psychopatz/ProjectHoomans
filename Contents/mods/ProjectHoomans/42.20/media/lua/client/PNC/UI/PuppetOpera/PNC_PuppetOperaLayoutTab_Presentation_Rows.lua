-- Shared row rendering and sizing contracts for the layout editor.

PNC = PNC or {}

local Internal = PNC.PuppetOperaLayoutTabInternal
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

local function drawActorRow(list, y, row, alternate)
    local actor = row.item
    local selected = list.selected == row.index
    local width = math.max(32, list:getWidth() - 16)
    if selected then
        list:drawRect(0, y, list:getWidth(), list.itemheight,
            0.35, 0.20, 0.48, 0.82)
    elseif alternate then
        list:drawRect(0, y, list:getWidth(), list.itemheight,
            0.12, 0.16, 0.18, 0.20)
    end
    local liveID = actor.liveShortID
        and (" [" .. tostring(actor.liveShortID) .. "]") or ""
    local identity = actor.liveName
        and ("  -> " .. tostring(actor.liveName) .. liveID)
        or "  -> unbound"
    list:drawText(Layout.Ellipsize(
        tostring(actor.label) .. identity,
        UIFont.Small,
        width
    ), 8, y + 5,
        0.92, 0.94, 1.00, 1, UIFont.Small)
    list:drawText(
        Layout.Ellipsize(
            "slot=" .. tostring(actor.id)
                .. "  " .. tostring(actor.kind or "unbound")
                .. "  anchor=" .. tostring(actor.anchor),
            UIFont.Small,
            width
        ),
        8,
        y + 24,
        0.62,
        0.76,
        0.84,
        1,
        UIFont.Small
    )
    list:drawTextRight(
        Layout.Ellipsize(tostring(actor.state), UIFont.Small,
            math.max(32, list:getWidth() * 0.42)),
        list:getWidth() - 8,
        y + 5,
        actor.owned and 0.55 or 0.72,
        actor.owned and 1.00 or 0.80,
        actor.owned and 0.65 or 0.86,
        1,
        UIFont.Small
    )
    return y + list.itemheight
end

local function drawLiveRow(list, y, row, alternate)
    local actor = row.item
    local selected = list.selected == row.index
    local width = math.max(32, list:getWidth() - 16)
    local assignment = actor.assignedActorID
        and ("BOUND slot=" .. tostring(actor.assignedActorID))
        or tr("UI_PNC_PuppetOpera_FreeActor", "FREE - drag to graph")
    local readiness = actor.ready == true
        and tr("UI_PNC_PuppetOpera_Ready", "READY")
        or actor.ready == false
        and tr("UI_PNC_PuppetOpera_Blocked", "BLOCKED")
        or tr("UI_PNC_PuppetOpera_Checking", "CHECKING")
    if selected then
        list:drawRect(0, y, list:getWidth(), list.itemheight,
            0.35, 0.20, 0.48, 0.82)
    elseif alternate then
        list:drawRect(0, y, list:getWidth(), list.itemheight,
            0.12, 0.16, 0.18, 0.20)
    end
    local shortID = actor.shortID and (" [" .. tostring(actor.shortID)
        .. "]") or ""
    local identity = tostring(actor.name) .. shortID
    list:drawText(Layout.Ellipsize(identity, UIFont.Small,
        math.max(32, width - 72)), 8, y + 3,
        0.92, 0.94, 1.00, 1, UIFont.Small)
    list:drawText(
        Layout.Ellipsize(assignment .. "  id=" .. tostring(actor.id), UIFont.Small,
            math.max(32, width - 72)),
        8,
        y + 19,
        actor.ready == false and 1.00
            or actor.assignedActorID and 0.72 or 0.98,
        actor.ready == false and 0.45
            or actor.assignedActorID and 0.80 or 0.66,
        actor.ready == false and 0.40
            or actor.assignedActorID and 0.84 or 0.40,
        1,
        UIFont.Small
    )
    list:drawTextRight(
        string.format("%.1f tiles", math.sqrt(tonumber(actor.distSq) or 0)),
        list:getWidth() - 8,
        y + 3,
        0.62,
        0.76,
        0.84,
        1,
        UIFont.Small
    )
    list:drawTextRight(
        readiness,
        list:getWidth() - 8,
        y + 19,
        actor.ready == true and 0.40 or actor.ready == false and 1.00 or 0.80,
        actor.ready == true and 0.95 or actor.ready == false and 0.42 or 0.80,
        actor.ready == true and 0.58 or actor.ready == false and 0.38 or 0.42,
        1,
        UIFont.Small
    )
    return y + list.itemheight
end

Internal.resizeRows = resizeRows
Internal.tr = tr
Internal.drawActorRow = drawActorRow
Internal.drawLiveRow = drawLiveRow

return ISPNCPuppetOperaLayoutTab
