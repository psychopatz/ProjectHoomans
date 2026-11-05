local T = require "tests/support/test"

local FILE = T.path(
    "PsychopatzCore",
    "client",
    "PsychopatzCore/World/SurvivorWorld/"
        .. "PsychopatzSurvivorWorldMapHoverCard.lua"
)

package.preload["ISUI/ISPanel"] = function() return true end
package.preload[
    "PsychopatzCore/UI/Components/PsychopatzPortraitPanel"
] = function() return true end

local Panel = {}
Panel.__index = Panel
function Panel:derive(name)
    local class = { Type = name }
    class.__index = class
    setmetatable(class, { __index = self })
    return class
end
function Panel:new(x, y, width, height)
    return setmetatable({
        x = x,
        y = y,
        width = width,
        height = height,
        children = {},
        rects = {},
        texts = {},
    }, self)
end
function Panel:initialise() end
function Panel:createChildren() end
function Panel:instantiate() self:createChildren() end
function Panel:render() end
function Panel:addChild(child) self.children[#self.children + 1] = child end
function Panel:setX(value) self.x = value end
function Panel:setY(value) self.y = value end
function Panel:drawRect(...)
    self.rects[#self.rects + 1] = { ... }
end
function Panel:drawRectBorder(...) end
function Panel:drawTextCentre(text, ...)
    self.texts[#self.texts + 1] = text
end
ISPanel = Panel

local portraitTarget
local PortraitPanel = Panel:derive("PortraitPanel")
function PortraitPanel:new(x, y, width, height, options)
    local portrait = Panel.new(self, x, y, width, height)
    portrait.options = options
    return portrait
end
function PortraitPanel:setTarget(_, spec)
    portraitTarget = spec
    return true
end

PsychopatzCore = { UI = { PortraitPanel = PortraitPanel } }
UIFont = { Small = "small" }
IsoDirections = { S = "south" }

T.load(FILE)
local Card = PsychopatzCore.SurvivorWorldMapHoverCard
local card = Card:new(0, 0, 128, {
    nameHeight = 24,
    badgeSize = 24,
})
card:initialise()
card:instantiate()

T.truthy(card.width == 128 and card.height == 152,
    "shared Core map hover card dimensions changed")
T.truthy(card.portrait.options.zoom == 18
    and card.portrait.options.yOffset == -0.85
    and card.portrait.options.faceOnly == true,
    "shared Core map hover card lost the portrait preview contract")

local entry = {
    actorID = "actor:card:one",
    name = "Mara Voss",
    organizationalFaction = {
        id = "faction:card",
        name = "Crossroads Exchange",
        role = "trader",
    },
}
card:setContext(entry)
card:setTarget(nil, { actorID = entry.actorID })
card:render()
T.truthy(portraitTarget.actorID == entry.actorID,
    "shared Core map hover card did not bind the actor portrait")
local sawName = false
for _, text in ipairs(card.texts) do
    if text == "Mara Voss" then sawName = true end
end
T.truthy(sawName,
    "shared Core map hover card did not render the learned actor name")
T.truthy(card.contextFaction == "Crossroads Exchange"
    and card.contextRole == "trader",
    "shared Core map hover card did not render faction/role context")

T.finish("pnc_map_hover_portrait_card_smoke")
