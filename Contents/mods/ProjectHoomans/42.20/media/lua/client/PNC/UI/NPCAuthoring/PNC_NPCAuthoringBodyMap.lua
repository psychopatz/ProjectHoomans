-- Draft-safe navigation using the native protection/temperature silhouettes.
-- No live actor, BodyDamage or health/temperature mutation is involved.
require 'ISUI/ISPanel'
ISPNCNPCAuthoringBodyMap = ISPanel:derive('ISPNCNPCAuthoringBodyMap')
local Map = ISPNCNPCAuthoringBodyMap
local regions = {
    { 'left-hand', 'hands' }, { 'right-hand', 'hands' },
    { 'lower-left-arm', 'hands' }, { 'lower-right-arm', 'hands' },
    { 'upper-left-arm', 'torso' }, { 'upper-right-arm', 'torso' },
    { 'chest', 'torso', 30 }, { 'abdomen', 'torso', 50 },
    { 'head', 'head' }, { 'neck', 'neck' }, { 'groin', 'waist', 100 },
    { 'left-thigh', 'legs' }, { 'right-thigh', 'legs' },
    { 'left-calf', 'legs' }, { 'right-calf', 'legs' },
    { 'left-foot', 'feet' }, { 'right-foot', 'feet' },
}
function Map:new(x, y, w, h, onSelect)
    local o = ISPanel.new(self, x, y, w, h)
    setmetatable(o, self); self.__index = self
    o.onSelect, o.counts, o.regions = onSelect, {}, {}
    o.background = false
    return o
end
function Map:SetState(female, counts, selected)
    self.counts, self.selected = counts or {}, selected
    local sex = female and 'female' or 'male'
    if self.sex == sex and #self.regions > 0 then return end
    self.sex, self.regions = sex, {}
    self.baseTexture = getTexture and getTexture('media/ui/BodyParts/' .. sex .. '_base_white')
    self.outline = getTexture and getTexture('media/ui/BodyParts/bps_' .. sex .. '_outlines')
    for _, region in ipairs(regions) do
        local texture = getTexture and getTexture('media/ui/BodyParts/bps_' .. sex .. '_' .. region[1])
        if texture then self.regions[#self.regions + 1] = { texture = texture, group = region[2], z = region[3] or 0,
            x = texture:getOffsetX(), y = texture:getOffsetY(), w = texture:getWidth(), h = texture:getHeight() } end
    end
end
function Map:Projection()
    local scale = math.max(.01, math.min(self.width / 123, self.height / 302))
    return (self.width - 123 * scale) / 2, (self.height - 302 * scale) / 2, scale
end
function Map:Hit(x, y)
    local ox, oy, scale = self:Projection()
    x, y = (x - ox) / scale, (y - oy) / scale
    local hit, z = nil, -1
    -- Native ISBodyPartPanel uses trimmed bounds and z-order for overlapping parts.
    for _, region in ipairs(self.regions) do
        if self.counts[region.group] and x >= region.x and x <= region.x + region.w
            and y >= region.y and y <= region.y + region.h and region.z > z then hit, z = region, region.z end
    end
    return hit and hit.group
end
function Map:onMouseDown(x, y)
    local group = self:Hit(x, y)
    if group and self.onSelect then self.onSelect(group) end
    return true
end
function Map:onMouseMove()
    self.hovered = self:Hit(self:getMouseX(), self:getMouseY())
    local group
    for _, candidate in ipairs(PNC.NPCAuthoringSlots.Groups()) do if candidate.id == self.hovered then group = candidate end end
    self.tooltip = group and PNC.Translation.GetKey('UI_PNC_Authoring_Group_' .. group.key, group.label) or nil
end
function Map:onMouseMoveOutside() self.hovered, self.tooltip = nil, nil end
function Map:render()
    local x, y, scale = self:Projection()
    if self.baseTexture then self:drawTextureScaledUniform(self.baseTexture, x, y, scale, .25, 1, 1, 1) end
    for _, region in ipairs(self.regions) do
        local count = self.counts[region.group]
        local occupied = count and count.equipped > 0
        local selected = region.group == self.selected
        local hovered = region.group == self.hovered
        local r, g, b = .5, .52, .54
        if occupied then r, g, b = .2, .8, .35 end
        if selected or hovered then
            if occupied then r, g, b = .35, 1, .5 else r, g, b = .9, .85, .3 end
        end
        self:drawTextureScaledUniform(region.texture, x, y, scale, count and 1 or .18, r, g, b)
    end
    if self.outline then self:drawTextureScaledUniform(self.outline, x, y, scale, 1, 1, 1, 1) end
end
return Map
