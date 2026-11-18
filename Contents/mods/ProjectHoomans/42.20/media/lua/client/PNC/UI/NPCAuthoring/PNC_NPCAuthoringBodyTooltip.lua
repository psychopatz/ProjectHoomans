-- An icon/name list for the hovered authoring region, using native tooltip life cycle.
require 'ISUI/ISToolTip'
local Tip = ISToolTip:derive('ISPNCNPCAuthoringBodyTooltip')
local function tr(k, fallback) return PNC.Translation.GetKey(k, fallback) end
function Tip:new()
    local o = ISToolTip.new(self)
    setmetatable(o, self); self.__index = self
    o.rows = {}
    o.backgroundColor = { r = .03, g = .04, b = .05, a = .96 }
    return o
end
function Tip:SetRegion(owner, region, slots)
    self:setOwner(owner)
    self.heading, self.rows = region.title, {}
    for _, row in ipairs(slots or {}) do
        if row.group == region.group and row.type then
            local item = PNC.NPCAuthoringCatalog.Find(row.type)
            self.rows[#self.rows + 1] = { label = item and item.label or row.type,
                texture = item and item.script:getNormalTexture() }
        end
    end
    if #self.rows == 0 then self.rows[1] = { label = tr('UI_PNC_Authoring_NoEquippedItems', 'No equipped items') } end
end
function Tip:doLayout()
    local manager = getTextManager()
    self.rowHeight = math.max(30, manager:getFontHeight(UIFont.Small) + 8)
    local width = manager:MeasureStringX(UIFont.Small, self.heading or '') + 24
    self.visibleRows = math.min(10, #self.rows, math.max(1, math.floor((getCore():getScreenHeight() - 32) / self.rowHeight) - 2))
    for index = 1, self.visibleRows do width = math.max(width, manager:MeasureStringX(UIFont.Small, self.rows[index].label) + 56) end
    self:setWidth(math.min(getCore():getScreenWidth() - 24, math.max(180, math.min(420, width))))
    self:setHeight(self.rowHeight * (1 + self.visibleRows + (#self.rows > self.visibleRows and 1 or 0)) + 16)
end
function Tip:render()
    if not self:getIsVisible() or not self.rowHeight then return end
    self:setX(math.max(0, math.min(getMouseX() + 20, getCore():getScreenWidth() - self.width)))
    self:setY(math.max(0, math.min(getMouseY() + 16, getCore():getScreenHeight() - self.height)))
    self:drawRectBorder(0, 0, self.width, self.height, .7, .7, .8, .8)
    self:drawText(self.heading or '', 8, 8, 1, 1, 1, 1, UIFont.Small)
    local y = self.rowHeight + 8
    for index = 1, self.visibleRows do
        local row = self.rows[index]
        if row.texture then self:drawTextureScaledAspect(row.texture, 8, y, 26, 26, 1, 1, 1, 1) end
        self:drawText(PsychopatzCore.UI.Layout.Ellipsize(row.label, UIFont.Small, self.width - 52), 42, y + 3, .85, .9, .9, 1, UIFont.Small)
        y = y + self.rowHeight
    end
    if #self.rows > self.visibleRows then self:drawText('+' .. tostring(#self.rows - self.visibleRows) .. ' ' .. tr('UI_PNC_Authoring_MoreItems', 'more items'), 8, y, .7, .8, .8, 1, UIFont.Small) end
end
return Tip
