local FILE =
    "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Map/"
        .. "PNC_MapHoverPortraitCard.lua"

package.preload["ISUI/ISPanel"] = function() return true end
package.preload["PsychopatzCore/UI/Components/PsychopatzPortraitPanel"] =
    function() return true end
package.preload["PNC/UI/Factions/PNC_FactionEmblemRenderer"] =
    function() return true end

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
function Panel:drawTextCentre(text, ...)
    self.texts[#self.texts + 1] = text
end
ISPanel = Panel

local portraitOptions
local portraitTarget
local portraitCreateCount = 0
local PortraitPanel = Panel:derive("PortraitPanel")
function PortraitPanel:new(x, y, width, height, options)
    portraitCreateCount = portraitCreateCount + 1
    portraitOptions = options
    local portrait = Panel.new(self, x, y, width, height)
    portrait.background = true
    return portrait
end
function PortraitPanel:initialise()
    self.background = false
end
function PortraitPanel:createChildren() end
function PortraitPanel:setTarget(_, spec)
    portraitTarget = spec
    return true
end

PsychopatzCore = { UI = { PortraitPanel = PortraitPanel } }
local emblemDrawCount = 0
PNC = {
    FactionEmblemRenderer = {
        Draw = function(_, emblem)
            emblemDrawCount = emblemDrawCount + 1
            return emblem ~= nil
        end,
    },
}
UIFont = { Small = "small" }
IsoDirections = { S = "south" }

dofile("Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/Knowledge/PNC_NPCIdentityPresentation.lua")
package.preload["PNC/Knowledge/PNC_NPCIdentityPresentation"] =
    function() return PNC.NPCIdentityPresentation end
dofile(FILE)

local card = PNC.MapHoverPortraitCard:new(0, 0, 128, {
    nameHeight = 24,
    badgeSize = 24,
})
card:initialise()
card:instantiate()

assert(card.background == false,
    "map portrait card retained a stock background or border")
assert(card.width == 128 and card.height == 152,
    "map portrait card dimensions do not include the name plate")
assert(portraitCreateCount == 1
    and card.portrait.width == 128
    and card.portrait.height == 128
    and #card.children == 1
    and card.children[1] == card.portrait,
    "portrait renderer was not placed inside the card container")
assert(portraitOptions.zoom == 18
    and portraitOptions.yOffset == -0.85
    and portraitOptions.animate == false
    and portraitOptions.faceOnly == true
    and portraitOptions.showBackground == false
    and portraitOptions.showBorder == false
    and portraitOptions.padding == 0,
    "map portrait renderer did not use the debug face-preview setup")

local spec = { id = "npc_card", faceOnly = true }
assert(card:setTarget(spec), "map portrait card did not bind its target")
assert(portraitTarget == spec, "map portrait card changed its target spec")

card:setContext({
    id = "npc_card",
    name = "Dion Amaya",
    faction = "colonist",
    roleTag = "farmer",
    organizationalFaction = {
        id = "colonist",
        name = "Colonists",
        role = "farmer",
    },
})
card:render()
assert(card.texts[1] == "Dion Amaya",
    "NPC name was not centered beneath the portrait")
assert(card.texts[2] == "C" and card.texts[3] == "F",
    "faction and worker badge placeholders were not rendered")
assert(#card.rects == 6,
    "portrait card did not render its name plate and two badge slots")
card:setFactionIcon("faction_texture")
card:setWorkerIcon("worker_texture")
assert(card.factionIcon == "faction_texture"
    and card.workerIcon == "worker_texture",
    "portrait badge slots cannot accept future icon textures")

card:setContext({
    id = "npc_card",
    name = "Dion Amaya",
    faction = "neutral",
    roleTag = "farmer",
    organizationalFaction = {
        name = "Ashwood Haven",
        emblem = {
            revision = 3,
            backgroundColorID = "green",
            layers = {},
        },
    },
})
card:render()
assert(emblemDrawCount == 1,
    "layered organizational faction emblem did not replace placeholder")

card:setCardPosition(20, 30)
assert(card.x == 20 and card.y == 30,
    "portrait card position did not update without reconstruction")

print("pnc_map_hover_portrait_card_smoke: ok")
