-- One reusable map-hover card around the core 3D portrait renderer.

require "ISUI/ISPanel"
require "PsychopatzCore/UI/Components/PsychopatzPortraitPanel"
require "PNC/UI/Factions/PNC_FactionEmblemRenderer"
require "PNC/Knowledge/PNC_NPCIdentityPresentation"

PNC = PNC or {}

local PortraitPanel = PsychopatzCore
    and PsychopatzCore.UI
    and PsychopatzCore.UI.PortraitPanel

PNCMapHoverPortraitCard = ISPanel:derive("PNCMapHoverPortraitCard")
PNC.MapHoverPortraitCard = PNCMapHoverPortraitCard

-- This is the single camera tuning point for map portraits.
PNCMapHoverPortraitCard.FaceZoom = 18
PNCMapHoverPortraitCard.FaceYOffset = -0.85
PNCMapHoverPortraitCard.DebugBackground = false

local FACTION_COLOR = { r = 0.82, g = 0.61, b = 0.16 }
local WORKER_COLOR = { r = 0.16, g = 0.55, b = 0.78 }
local EmblemRenderer = PNC.FactionEmblemRenderer
local Identity = PNC.NPCIdentityPresentation

local function firstGlyph(value, fallback)
    local text = tostring(value or "")
    if text == "" then return fallback end
    return string.upper(string.sub(text, 1, 1))
end

function PNCMapHoverPortraitCard:initialise()
    ISPanel.initialise(self)
    self.background = false
end

function PNCMapHoverPortraitCard:createChildren()
    ISPanel.createChildren(self)
    if self.portrait or not PortraitPanel or not PortraitPanel.new then return end
    self.portrait = PortraitPanel:new(
        0,
        0,
        self.portraitSize,
        self.portraitSize,
        {
            zoom = self.portraitZoom,
            xOffset = 0,
            yOffset = self.portraitYOffset,
            direction = IsoDirections and IsoDirections.S,
            animSetName = false,
            stateName = "idle",
            animate = false,
            faceOnly = true,
            showBackground = self.debugBackground,
            showBorder = false,
            padding = 0,
        }
    )
    self.portrait:initialise()
    self.portrait:instantiate()
    self:addChild(self.portrait)
end

function PNCMapHoverPortraitCard:setTarget(spec)
    if not self.portrait or not self.portrait.setTarget then return false end
    return self.portrait:setTarget(nil, spec) == true
end

function PNCMapHoverPortraitCard:setContext(entry)
    local presentation = PNC.FactionPresentation
        and PNC.FactionPresentation.Resolve(entry) or nil
    local name = presentation and presentation.npcName or Identity.GetName(entry)
    local faction = presentation and presentation.factionName or ""
    local factionID = presentation and presentation.factionID or faction
    local workerRole = presentation and presentation.factionRole or ""
    local emblem = presentation and presentation.emblem or nil
    local emblemRevision = emblem
        and tonumber(emblem.revision) or -1
    if self.contextName == name
        and self.contextFaction == faction
        and self.contextFactionID == factionID
        and self.contextWorkerRole == workerRole
        and self.contextEmblemRevision == emblemRevision
    then
        return
    end
    self.contextName = name
    self.contextFaction = faction
    self.contextFactionID = factionID
    self.contextWorkerRole = workerRole
    self.contextEmblemRevision = emblemRevision
    self.factionEmblem = emblem
    self.factionGlyph = firstGlyph(faction, "?")
    self.workerGlyph = firstGlyph(workerRole, "?")
end

function PNCMapHoverPortraitCard:setFactionIcon(texture)
    self.factionIcon = texture
end

function PNCMapHoverPortraitCard:setFactionEmblem(emblem)
    self.factionEmblem = emblem
end

function PNCMapHoverPortraitCard:setWorkerIcon(texture)
    self.workerIcon = texture
end

function PNCMapHoverPortraitCard:setCardPosition(x, y)
    if self.setX then self:setX(x) else self.x = x end
    if self.setY then self:setY(y) else self.y = y end
end

function PNCMapHoverPortraitCard:drawBadge(x, color, glyph, texture)
    local y = self.portraitSize - self.badgeSize - self.badgeInset
    self:drawRect(
        x + 2,
        y + 2,
        self.badgeSize,
        self.badgeSize,
        0.55,
        0,
        0,
        0
    )
    self:drawRect(
        x,
        y,
        self.badgeSize,
        self.badgeSize,
        0.96,
        color.r,
        color.g,
        color.b
    )
    if self.drawRectBorder then
        self:drawRectBorder(
            x,
            y,
            self.badgeSize,
            self.badgeSize,
            1,
            0.05,
            0.05,
            0.05
        )
    end
    if texture and self.drawTextureScaledAspect then
        self:drawTextureScaledAspect(
            texture,
            x + 2,
            y + 2,
            self.badgeSize - 4,
            self.badgeSize - 4,
            1,
            1,
            1,
            1
        )
        return
    end
    self:drawTextCentre(
        glyph or "?",
        x + self.badgeSize / 2,
        y + 3,
        1,
        1,
        1,
        1,
        UIFont.Small
    )
end

function PNCMapHoverPortraitCard:drawFactionBadge(x)
    local y = self.portraitSize - self.badgeSize - self.badgeInset
    if self.factionEmblem and PNC.FactionPresentation
        and PNC.FactionPresentation.DrawBadge
    then
        self:drawRect(
            x + 2,
            y + 2,
            self.badgeSize,
            self.badgeSize,
            0.55,
            0,
            0,
            0
        )
        PNC.FactionPresentation.DrawBadge(
            self,
            self.factionEmblem,
            x,
            y,
            self.badgeSize
        )
        return
    end
    self:drawBadge(
        x,
        FACTION_COLOR,
        self.factionGlyph,
        self.factionIcon
    )
end

function PNCMapHoverPortraitCard:render()
    ISPanel.render(self)
    local nameY = self.portraitSize
    self:drawRect(
        0,
        nameY,
        self.width,
        self.nameHeight,
        0.91,
        0.035,
        0.035,
        0.035
    )
    self:drawRect(
        0,
        nameY,
        self.width,
        2,
        0.95,
        FACTION_COLOR.r,
        FACTION_COLOR.g,
        FACTION_COLOR.b
    )
    self:drawTextCentre(
        self.contextName or "NPC",
        self.width / 2,
        nameY + 5,
        1,
        1,
        1,
        1,
        UIFont.Small
    )
    self:drawFactionBadge(self.badgeInset)
    self:drawBadge(
        self.width - self.badgeSize - self.badgeInset,
        WORKER_COLOR,
        self.workerGlyph,
        self.workerIcon
    )
end

function PNCMapHoverPortraitCard:new(x, y, portraitSize, options)
    local size = math.max(1, tonumber(portraitSize) or 128)
    local values = options or {}
    local nameHeight = math.max(18, tonumber(values.nameHeight) or 24)
    local o = ISPanel:new(x, y, size, size + nameHeight)
    setmetatable(o, self)
    self.__index = self
    o.portraitSize = size
    o.nameHeight = nameHeight
    o.badgeSize = math.max(18, tonumber(values.badgeSize) or 24)
    o.badgeInset = math.max(2, tonumber(values.badgeInset) or 5)
    o.portraitZoom = tonumber(values.portraitZoom)
        or tonumber(self.FaceZoom) or 18
    o.portraitYOffset = tonumber(values.portraitYOffset)
        or tonumber(self.FaceYOffset) or -0.85
    o.debugBackground = values.debugBackground == true
        or self.DebugBackground == true
    o.factionGlyph = "?"
    o.workerGlyph = "?"
    return o
end

return PNCMapHoverPortraitCard
