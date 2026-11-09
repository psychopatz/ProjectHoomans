-- Named, locally extrapolated NPC journey dots for the vanilla world map.

require "PNC/Presentation/PNC_NPCTypePalette"
require "PNC/Knowledge/PNC_NPCIdentityPresentation"

local SurvivorWorldClient = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldClient"
local CoreActorMap = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldActorMap"

PNC = PNC or {}
PNC.MapTravelLayer = PNC.MapTravelLayer or {}

local TravelLayer = PNC.MapTravelLayer
local Directory = PNC.TravelDirectory
local Layers = PNC.MapLayers
local Display = PNC.MapDisplay
local Icons = PNC.MapMarkerIcons
local HoverPortrait = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldMapHover"
local Palette = PNC.NPCTypePalette
local HOVER_OWNER = "ProjectHoomans:pnc_travel"
local Identity = PNC.NPCIdentityPresentation

TravelLayer.Enabled = TravelLayer.Enabled ~= false
TravelLayer.DotTexture = TravelLayer.DotTexture
    or getTexture("media/ui/circle.png")
TravelLayer.RefreshMs = 500
TravelLayer.LabelCache = TravelLayer.LabelCache or {}

local function listProjectedEntries()
    local now = getTimestampMs and tonumber(getTimestampMs()) or 0
    local cached = TravelLayer.EntryCache
    local cachedAt = tonumber(TravelLayer.EntryCacheAt) or 0
    local refreshMs = math.max(
        0,
        tonumber(TravelLayer.RefreshMs) or 100
    )
    if now > 0
        and cached
        and now >= cachedAt
        and now - cachedAt < refreshMs
    then
        return cached
    end
    cached = Directory.ListProjected()
    if TravelLayer.EntryCache ~= cached then
        TravelLayer.LabelCache = {}
    end
    TravelLayer.EntryCache = cached
    TravelLayer.EntryCacheAt = now
    return cached
end

function TravelLayer.GetProjectedEntries()
    return listProjectedEntries()
end

local function listLegacyProjectedEntries()
    local output = {}
    for _, entry in ipairs(listProjectedEntries()) do
        if entry.coreActorProjection ~= true then
            output[#output + 1] = entry
        end
    end
    return output
end

function TravelLayer.GetDotSize(map)
    local zoom = map and map.mapAPI
        and tonumber(map.mapAPI:getZoomF()) or 0
    return math.max(
        7,
        math.min(13, 7 + (zoom - 10) * 0.8)
    )
end

function TravelLayer.FindMarkerAt(map, x, y, padding)
    if not TravelLayer.Enabled or not map or not map.mapAPI then
        return nil
    end
    local entries = listLegacyProjectedEntries()
    local positions = TravelLayer.BuildMarkerScreenPositions(map, entries)
    local half = TravelLayer.GetDotSize(map) / 2
        + (tonumber(padding) or 3)
    local index
    for index = #entries, 1, -1 do
        local entry = entries[index]
        if entry.x and entry.y then
            local position = positions[index]
            local sx = position and position.x or nil
            local sy = position and position.y or nil
            if sx and sy
                and math.abs(x - sx) <= half
                and math.abs(y - sy) <= half
            then
                return entry, sx, sy
            end
        end
    end
    return nil
end

-- Followers can share a canonical abstract coordinate while converging on
-- the owner. Keep that world coordinate authoritative, but spread only the
-- screen marker positions for exact/near-exact overlaps so a group does not
-- look like it was pruned to one green square.
function TravelLayer.BuildMarkerScreenPositions(map, entries)
    local positions = {}
    local groups = {}
    local entry
    local key
    local group
    local i
    local peerIndex
    local radius
    local angle
    if not map or not map.mapAPI then return positions end
    for i = 1, #(entries or {}) do
        entry = entries[i]
        if entry and entry.x ~= nil and entry.y ~= nil then
            positions[i] = {
                x = map.mapAPI:worldToUIX(entry.x, entry.y),
                y = map.mapAPI:worldToUIY(entry.x, entry.y),
            }
            -- Core SurvivorWorld has already performed deterministic
            -- provider-neutral overlap spreading for canonical actor dots.
            -- Keep the older screen-space fallback only for Hoomans-only
            -- records outside that projection.
            if entry.coreActorProjection ~= true then
                key = tostring(
                    math.floor((tonumber(entry.x) or 0) + 0.5)
                ) .. ":" .. tostring(
                    math.floor((tonumber(entry.y) or 0) + 0.5)
                )
                group = groups[key]
                if not group then
                    group = {}
                    groups[key] = group
                end
                group[#group + 1] = i
            end
        end
    end
    radius = math.max(8, TravelLayer.GetDotSize(map) * 0.9)
    for _, group in pairs(groups) do
        if #group > 1 then
            for peerIndex = 1, #group do
                i = group[peerIndex]
                angle = ((peerIndex - 1) / #group) * math.pi * 2
                positions[i].x = positions[i].x + math.cos(angle) * radius
                positions[i].y = positions[i].y + math.sin(angle) * radius
            end
        end
    end
    return positions
end

local function colorFor(entry)
    return Palette.Resolve(entry)
end

local function etaText(entry)
    local remaining = tonumber(entry and entry.remainingWorldHours)
    if not remaining then return nil end
    local hours = math.floor(remaining)
    local minutes = math.floor((remaining - hours) * 60 + 0.5)
    if hours > 0 then
        return "ETA " .. tostring(hours) .. "h " .. tostring(minutes) .. "m"
    end
    return "ETA " .. tostring(minutes) .. "m"
end

local function displayLabel(entry)
    local cacheKey = tostring(entry and entry.id or "")
    local cached = TravelLayer.LabelCache[cacheKey]
    if cached then return cached end
    local known = true
    if Identity and type(Identity.IsNameKnown) == "function" then
        known = Identity.IsNameKnown(entry) == true
    end
    if not known then
        TravelLayer.LabelCache[cacheKey] = ""
        return ""
    end
    local name
    if Identity and type(Identity.GetKnownName) == "function" then
        name = Identity.GetKnownName(entry)
    end
    name = name or Identity.GetName(entry)
    if type(name) ~= "string" or name == "" then
        TravelLayer.LabelCache[cacheKey] = ""
        return ""
    end
    local roleTag = entry and entry.roleTag
    local label = name
    if roleTag ~= nil and tostring(roleTag) ~= "" then
        label = name .. " [" .. tostring(roleTag) .. "]"
    end
    TravelLayer.LabelCache[cacheKey] = label
    return label
end

local function debugPresenceEnabled()
    local client = PNC.Client
    return client
        and type(client.CanUseDebug) == "function"
        and client.CanUseDebug() == true
end

local function debugPresenceLabel(entry)
    if not debugPresenceEnabled() then return nil end
    local value = entry and entry.presenceState
    if value == nil or tostring(value) == "" then
        return "UNKNOWN"
    end
    return string.upper(tostring(value))
end

local function drawMarkerIcon(map, entry, sx, sy, dotSize)
    local definition = Icons and Icons.Resolve
        and Icons.Resolve(entry and entry.iconID) or nil
    local color
    local size
    local corpseState = PNC.Const
        and PNC.Const.PRESENCE_CORPSE
    if not definition then return end
    local deceased = entry and (
        entry.deathMarker == true
        or entry.alive == false
        or corpseState ~= nil
            and entry.presenceState == corpseState
    )
    color = deceased and Palette.Get("dead")
        or definition.color
        or { r = 0.05, g = 0.05, b = 0.05, a = 1 }
    size = math.max(dotSize, tonumber(definition.size) or dotSize)
    if definition.texture and map.drawTextureScaledAspect then
        map:drawTextureScaledAspect(
            definition.texture,
            sx - size / 2,
            sy - size / 2,
            size,
            size,
            color.a or 1,
            color.r or 1,
            color.g or 1,
            color.b or 1
        )
    elseif definition.glyph then
        map:drawTextCentre(
            definition.glyph,
            sx,
            sy - 6,
            color.r or 0.05,
            color.g or 0.05,
            color.b or 0.05,
            color.a or 1,
            UIFont.Small
        )
    end
end

local function isInsideVisibleChild(child, x, y)
    if not child then return false end
    local visible = child.getIsVisible and child:getIsVisible()
    if visible == nil then visible = child.visible ~= false end
    if not visible then return false end
    local left = tonumber(child.x)
        or child.getX and child:getX() or 0
    local top = tonumber(child.y)
        or child.getY and child:getY() or 0
    local width = tonumber(child.width)
        or child.getWidth and child:getWidth() or 0
    local height = tonumber(child.height)
        or child.getHeight and child:getHeight() or 0
    return x >= left and y >= top
        and x <= left + width and y <= top + height
end

local function isOverControls(map, x, y)
    return isInsideVisibleChild(map.symbolsUI, x, y)
        or isInsideVisibleChild(map.keyUI, x, y)
        or isInsideVisibleChild(map.buttonPanel, x, y)
        or isInsideVisibleChild(map.psychopatzMapToolsButton, x, y)
        or isInsideVisibleChild(
            map.psychopatzSurvivorWorldHover, x, y)
end

local function drawSelectedRoute(map, entry)
    local points = entry and entry.route and entry.route.points or nil
    local i
    local from
    local to
    local x1
    local y1
    local x2
    local y2
    if type(points) ~= "table" or #points < 2
        or not map.javaObject
        or not map.javaObject.DrawLine
    then
        return
    end
    for i = 1, #points - 1 do
        from = points[i]
        to = points[i + 1]
        x1 = map.mapAPI:worldToUIX(from.x, from.y)
        y1 = map.mapAPI:worldToUIY(from.x, from.y)
        x2 = map.mapAPI:worldToUIX(to.x, to.y)
        y2 = map.mapAPI:worldToUIY(to.x, to.y)
        map.javaObject:DrawLine(
            nil,
            x1,
            y1,
            x2,
            y2,
            2,
            0.2,
            0.85,
            1,
            0.8
        )
    end
end

function TravelLayer.SetEnabled(enabled)
    TravelLayer.Enabled = enabled == true
end

function TravelLayer.InvalidateEntryCache()
    TravelLayer.EntryCache = nil
    TravelLayer.EntryCacheAt = nil
    TravelLayer.LabelCache = {}
end

local function drawTravelMarkers(map, entries, showLabels, dotSize,
    mouseX, mouseY)
    local hoveredEntry
    local hoveredX
    local hoveredY
    local entry
    local sx
    local sy
    local positions = TravelLayer.BuildMarkerScreenPositions(map, entries)
    local color
    local selected
    local tracked
    local emphasized
    local markerHovered
    local half = dotSize / 2
    TravelLayer.LastMarkerPositions = {}
    for i = 1, #entries do
        entry = entries[i]
        if entry.x and entry.y then
            local position = positions[i]
            sx = position and position.x or nil
            sy = position and position.y or nil
            if sx and sy
                and sx >= -dotSize and sy >= -dotSize
                and sx <= map.width + dotSize
                and sy <= map.height + dotSize
                and not isOverControls(map, sx, sy)
            then
                color = colorFor(entry)
                selected = PNC.MapCommands
                    and PNC.MapCommands.IsSelected
                    and PNC.MapCommands.IsSelected(entry.id)
                    or false
                tracked = entry.tracked == true
                emphasized = selected or tracked
                TravelLayer.LastMarkerPositions[
                    tostring(entry.id)
                ] = {
                    entry = entry,
                    x = sx,
                    y = sy,
                    radius = half + 3,
                }
                markerHovered = math.abs(mouseX - sx) <= half + 3
                    and math.abs(mouseY - sy) <= half + 3
                if markerHovered then
                    hoveredEntry = entry
                    hoveredX = sx
                    hoveredY = sy
                end
                if emphasized then
                    drawSelectedRoute(map, entry)
                end
                if TravelLayer.DotTexture then
                    map:drawTextureScaledAspect(
                        TravelLayer.DotTexture,
                        sx - half,
                        sy - half,
                        dotSize,
                        dotSize,
                        1,
                        color.r,
                        color.g,
                        color.b
                    )
                else
                    map:drawRect(
                        sx - half,
                        sy - half,
                        dotSize,
                        dotSize,
                        1,
                        color.r,
                        color.g,
                        color.b
                    )
                end
                map:drawRectBorder(
                    sx - half - (emphasized and 2 or 0),
                    sy - half - (emphasized and 2 or 0),
                    dotSize + (emphasized and 4 or 0),
                    dotSize + (emphasized and 4 or 0),
                    0.9,
                    tracked and 0.45
                        or selected and 0.2 or 0.05,
                    tracked and 1.0
                        or selected and 1.0 or 0.05,
                    tracked and 0.55
                        or selected and 0.2 or 0.05
                )
                drawMarkerIcon(map, entry, sx, sy, dotSize)
                if (showLabels or emphasized) and not markerHovered then
                    map:drawTextCentre(
                        displayLabel(entry),
                        sx,
                        sy + half + 2,
                        1,
                        1,
                        1,
                        1,
                        UIFont.Small
                    )
                end
            end
        end
    end


    return hoveredEntry, hoveredX, hoveredY
end

local function drawTravelHover(map, hoveredEntry, hoveredX, hoveredY)
    if SurvivorWorldClient
        and SurvivorWorldClient.SetHighlighted
    then
        SurvivorWorldClient.SetHighlighted(
            hoveredEntry
                and hoveredEntry.coreActorProjection == true
                and hoveredEntry.id
                or nil
        )
    end
    if hoveredEntry then
        local portraitVisible = HoverPortrait
            and HoverPortrait.Update
            and HoverPortrait.Update(
                map,
                hoveredEntry,
                hoveredX,
                hoveredY,
                nil,
                HOVER_OWNER
            )
            or false
        local label = displayLabel(hoveredEntry)
        if not portraitVisible and label ~= "" then
            local presence = debugPresenceLabel(hoveredEntry)
            local eta = etaText(hoveredEntry)
            if presence then label = label .. " [" .. presence .. "]" end
            if eta then label = label .. " — " .. eta end
            local width = getTextManager():MeasureStringX(UIFont.Small, label) + 12
            local height = getTextManager():getFontHeight(UIFont.Small) + 8
            local x = math.max(
                4,
                math.min(map.width - width - 4, hoveredX - width / 2)
            )
            local y = math.max(4, hoveredY - height - 10)
            map:drawRect(x, y, width, height, 0.88, 0.05, 0.05, 0.05)
            map:drawRectBorder(x, y, width, height, 1, 0.5, 0.5, 0.5)
            map:drawTextCentre(
                label,
                x + width / 2,
                y + 4,
                1,
                1,
                1,
                1,
                UIFont.Small
            )
        end
    elseif HoverPortrait and HoverPortrait.Hide then
        HoverPortrait.Hide(map, true, HOVER_OWNER)
    end
end

function TravelLayer.Render(map)
    if not TravelLayer.Enabled or not map or not map.mapAPI then
        if HoverPortrait and HoverPortrait.Hide then
            HoverPortrait.Hide(map, true, HOVER_OWNER)
        end
        return
    end
    local entries = listLegacyProjectedEntries()
    local showLabels = Display and Display.AreNamesVisible
        and Display.AreNamesVisible() or false
    local dotSize = TravelLayer.GetDotSize(map)
    local mouseX = map:getMouseX()
    local mouseY = map:getMouseY()
    local hoveredEntry, hoveredX, hoveredY = drawTravelMarkers(
        map, entries, showLabels, dotSize, mouseX, mouseY
    )
    drawTravelHover(map, hoveredEntry, hoveredX, hoveredY)
end

Layers.Register("pnc_travel", {
    order = 100,
    isVisible = function()
        return TravelLayer.Enabled
    end,
    render = TravelLayer.Render,
})

local function corePresentationFor(actorID)
    actorID = tostring(actorID or "")
    local entries = listProjectedEntries()
    if TravelLayer.CorePresentationIndexSource ~= entries then
        local index = {}
        for _, entry in ipairs(entries) do
            if entry.coreActorProjection == true then
                index[tostring(entry.id or "")] = entry
            end
        end
        TravelLayer.CorePresentationIndex = index
        TravelLayer.CorePresentationIndexSource = entries
    end
    return TravelLayer.CorePresentationIndex
        and TravelLayer.CorePresentationIndex[actorID] or nil
end

CoreActorMap.RegisterDecorator("ProjectHoomans", {
    -- Keep generic Hoomans actor styling below the shared Dynamic Trading
    -- decorator so trader identity/icon/faction presentation remains common.
    priority = 50,
    decorate = function(entry, style)
        local projected = corePresentationFor(entry.actorID)
        if not projected then
            return style
        end
        if style.hoverMetadata
            and style.hoverMetadata.traderID
        then
            return style
        end
        style.color = colorFor(projected)
        style.label = displayLabel(projected)
        style.size = 9
        return style
    end,
})

return TravelLayer
