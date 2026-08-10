-- One reusable NPC portrait card for world-map hover feedback.

require "PNC/UI/Map/PNC_MapHoverPortraitCard"
require "PNC/Knowledge/PNC_KnowledgeInterest"

PNC = PNC or {}
PNC.MapHoverPortrait = PNC.MapHoverPortrait or {}

local HoverPortrait = PNC.MapHoverPortrait
local PortraitCard = PNC.MapHoverPortraitCard

HoverPortrait.Size = 128
HoverPortrait.NameHeight = 24
HoverPortrait.MarkerGap = 8
HoverPortrait.DelayMs = 90
HoverPortrait.LayoutVersion = 8

local function nowMilliseconds()
    if getTimestampMs then
        return tonumber(getTimestampMs()) or 0
    end
    if PNC.Core and PNC.Core.Now then
        return tonumber(PNC.Core.Now()) or 0
    end
    return 0
end

local function setVisible(element, visible)
    if not element then return end
    if element.setVisible then
        element:setVisible(visible == true)
    else
        element.visible = visible == true
    end
end

local function portraitSpec(entry)
    local portrait = entry and entry.portrait or nil
    if type(portrait) ~= "table" then return nil end
    return {
        id = tostring(entry.id),
        identitySeed = portrait.identitySeed or 1,
        isFemale = portrait.isFemale == true,
        preferDescriptor = true,
        faceOnly = true,
        appearance = portrait.appearance or {},
    }
end

local function hasCurrentLayout(panel)
    if not PortraitCard
        or not panel
        or panel.pncLayoutVersion ~= HoverPortrait.LayoutVersion
    then
        return false
    end
    if PortraitCard.FaceZoom ~= nil
        and tonumber(panel.portraitZoom)
            ~= tonumber(PortraitCard.FaceZoom)
    then
        return false
    end
    if PortraitCard.FaceYOffset ~= nil
        and tonumber(panel.portraitYOffset)
            ~= tonumber(PortraitCard.FaceYOffset)
    then
        return false
    end
    if PortraitCard.DebugBackground ~= nil
        and panel.debugBackground
            ~= (PortraitCard.DebugBackground == true)
    then
        return false
    end
    return true
end

function HoverPortrait.Ensure(map)
    local panel
    if not map then return nil end
    panel = map.pncHoverPortrait
    if hasCurrentLayout(panel) then
        return panel
    end
    if panel then
        setVisible(panel, false)
        if map.removeChild then map:removeChild(panel) end
        map.pncHoverPortrait = nil
        map._pncPortraitVisibleID = nil
        map._pncPortraitVisibleKey = nil
    end
    if not PortraitCard or not PortraitCard.new or not map.addChild then
        return nil
    end
    panel = PortraitCard:new(
        0,
        0,
        HoverPortrait.Size,
        {
            nameHeight = HoverPortrait.NameHeight,
            badgeSize = 24,
            badgeInset = 5,
        }
    )
    if panel.initialise then panel:initialise() end
    if panel.instantiate then panel:instantiate() end
    panel.pncLayoutVersion = HoverPortrait.LayoutVersion
    setVisible(panel, false)
    map:addChild(panel)
    map.pncHoverPortrait = panel
    return panel
end

function HoverPortrait.Hide(map, resetCandidate)
    if not map then return false end
    setVisible(map.pncHoverPortrait, false)
    map._pncPortraitVisibleID = nil
    map._pncPortraitVisibleKey = nil
    if resetCandidate ~= false then
        map._pncPortraitCandidateID = nil
        map._pncPortraitCandidateAt = nil
    end
    return true
end

function HoverPortrait.Update(map, entry, markerX, markerY)
    local id
    local now
    local spec
    local panel
    local bindingKey
    local size
    local totalHeight
    local x
    local y
    if not map or not entry or entry.id == nil then
        HoverPortrait.Hide(map)
        return false
    end
    id = tostring(entry.id)
    if PNC.KnowledgeInterest and PNC.KnowledgeInterest.Require then
        PNC.KnowledgeInterest.Require(id, "map_hover")
    end
    if type(entry.portrait) ~= "table" then
        HoverPortrait.Hide(map)
        return false
    end
    bindingKey = id .. ":" .. tostring(entry.portrait.revision or 0)
    now = nowMilliseconds()
    if map._pncPortraitCandidateID ~= id then
        map._pncPortraitCandidateID = id
        map._pncPortraitCandidateAt = now
        HoverPortrait.Hide(map, false)
        if now > 0 and HoverPortrait.DelayMs > 0 then
            return false
        end
    end
    if now > 0
        and now - (tonumber(map._pncPortraitCandidateAt) or now)
            < HoverPortrait.DelayMs
    then
        return false
    end
    panel = HoverPortrait.Ensure(map)
    if not panel then return false end
    if panel.setContext then panel:setContext(entry) end
    if map._pncPortraitVisibleKey ~= bindingKey and panel.setTarget then
        spec = portraitSpec(entry)
        if panel:setTarget(spec) ~= true then
            HoverPortrait.Hide(map, false)
            return false
        end
        map._pncPortraitVisibleID = id
        map._pncPortraitVisibleKey = bindingKey
    end
    size = tonumber(HoverPortrait.Size) or 128
    totalHeight = tonumber(panel.height)
        or size + (tonumber(HoverPortrait.NameHeight) or 24)
    x = math.max(
        4,
        math.min(
            (tonumber(map.width) or size) - size - 4,
            (tonumber(markerX) or 0) - size / 2
        )
    )
    y = (tonumber(markerY) or 0)
        - totalHeight
        - (tonumber(HoverPortrait.MarkerGap) or 8)
    if panel.setCardPosition then
        panel:setCardPosition(x, y)
    else
        panel.x = x
        panel.y = y
    end
    setVisible(panel, true)
    return true
end

return HoverPortrait
