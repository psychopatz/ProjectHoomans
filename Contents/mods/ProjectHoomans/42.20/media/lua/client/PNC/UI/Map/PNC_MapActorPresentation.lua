-- Project Hoomans presentation/data adapter for Core's actor map.
--
-- PsychopatzCore owns the complete actor-map engine: projection consumption,
-- caching, overlap handling, dots, icons, hover, selection, hit testing and
-- routes. This module contributes only Hoomans-specific presentation policy
-- and a bounded supplemental-record provider for records not in Core yet.

require "PNC/Presentation/PNC_NPCTypePalette"
require "PNC/Knowledge/PNC_NPCIdentityPresentation"

local CoreActorMap = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldActorMap"
local CoreClient = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldClient"

PNC = PNC or {}
PNC.MapActorPresentation = PNC.MapActorPresentation or {}

local Presentation = PNC.MapActorPresentation
local Display = PNC.MapDisplay
local Icons = PNC.MapMarkerIcons
local Palette = PNC.NPCTypePalette
local Identity = PNC.NPCIdentityPresentation
local Directory = PNC.TravelDirectory

local function actorID(entry)
    return tostring(entry and (
        entry.actorID or entry.id or entry.npcId
    ) or "")
end

local function displayLabel(entry)
    local id = actorID(entry)
    Presentation.LabelCache = Presentation.LabelCache or {}
    local cached = Presentation.LabelCache[id]
    if cached ~= nil then return cached end

    local known = true
    if Identity and type(Identity.IsNameKnown) == "function" then
        known = Identity.IsNameKnown(entry) == true
    end
    if not known then
        Presentation.LabelCache[id] = ""
        return ""
    end

    local name
    if Identity and type(Identity.GetKnownName) == "function" then
        name = Identity.GetKnownName(entry)
    end
    if not name and entry then
        name = entry.name or entry.displayName or entry.label
    end
    if not name and Identity and type(Identity.GetName) == "function" then
        name = Identity.GetName(entry)
    end
    name = tostring(name or "")
    if name == "" then
        Presentation.LabelCache[id] = ""
        return ""
    end

    local roleTag = entry and entry.role
        or entry and entry.roleTag or nil
    if roleTag ~= nil and tostring(roleTag) ~= "" then
        name = name .. " [" .. tostring(roleTag) .. "]"
    end
    Presentation.LabelCache[id] = name
    return name
end

local function iconFor(entry, color)
    if not Icons or type(Icons.Resolve) ~= "function" then
        return nil
    end
    local definition = Icons.Resolve(
        entry and (entry.iconID or entry.markerID)
    )
    if type(definition) ~= "table" then return nil end
    local iconColor = type(definition.color) == "table"
        and definition.color or color
    return {
        texture = definition.texture,
        glyph = definition.glyph,
        size = definition.size,
        r = tonumber(iconColor and iconColor.r) or color.r,
        g = tonumber(iconColor and iconColor.g) or color.g,
        b = tonumber(iconColor and iconColor.b) or color.b,
        a = tonumber(iconColor and iconColor.a) or color.a,
    }
end

local function canonicalActorIDs()
    local ids = {}
    if not CoreClient or type(CoreClient.ListActors) ~= "function" then
        return ids
    end
    for _, entry in ipairs(CoreClient.ListActors(false) or {}) do
        local id = actorID(entry)
        if id ~= "" then ids[id] = true end
    end
    return ids
end

local function listSupplementalActors()
    if not Directory
        or type(Directory.ListSupplementalActors) ~= "function"
    then
        return {}
    end

    local canonical = canonicalActorIDs()
    local output = {}
    for _, entry in ipairs(
        Directory.ListSupplementalActors() or {}
    ) do
        local id = actorID(entry)
        if id ~= "" and not canonical[id] then
            output[#output + 1] = entry
        end
    end
    return output
end

if CoreActorMap and type(CoreActorMap.RegisterSource) == "function" then
    CoreActorMap.RegisterSource("ProjectHoomans:SupplementalActors", {
        priority = 10,
        list = listSupplementalActors,
    })
end

if CoreActorMap and type(CoreActorMap.RegisterDecorator) == "function" then
    CoreActorMap.RegisterDecorator("ProjectHoomans", {
        -- DynamicTrading owns trader-bound identity at a higher priority.
        priority = 50,
        decorate = function(entry, style)
            style = type(style) == "table" and style or {}
            style.showLabel = Display
                and type(Display.AreNamesVisible) == "function"
                and Display.AreNamesVisible() == true or false

            -- Preserve DynamicTrading's commercial marker and hover payload.
            if style.hoverMetadata
                and style.hoverMetadata.traderID
            then
                return style
            end

            style.label = displayLabel(entry)
            style.color = Palette.Resolve(entry)
            style.size = 9
            style.icon = iconFor(entry, style.color)
            style.hoverMetadata = style.hoverMetadata or {}
            style.hoverMetadata.provider = entry and entry.provider
            style.hoverMetadata.providerState =
                entry and entry.providerState
            style.hoverMetadata.presence = entry
                and entry.presenceState
            return style
        end,
    })
end

return Presentation
