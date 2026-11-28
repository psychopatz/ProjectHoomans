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

local function clientSnapshots()
    if PNC.Network and type(PNC.Network.ClientState) == "table"
        and type(PNC.Network.ClientState.snapshots) == "table"
    then
        return PNC.Network.ClientState.snapshots
    end
    if PNC.ClientState and type(PNC.ClientState.snapshots) == "table" then
        return PNC.ClientState.snapshots
    end
    return nil
end

local function findByCoreActorID(coreID)
    if coreID == "" then return nil, nil end
    local snaps = clientSnapshots()
    if snaps then
        for _, snap in pairs(snaps) do
            if type(snap) == "table"
                and tostring(snap.coreActorID or "") == coreID
            then
                return snap, nil
            end
        end
    end
    local isClientOnly = PNC.Core
        and type(PNC.Core.IsClientOnly) == "function"
        and PNC.Core.IsClientOnly() == true
    if not isClientOnly and PNC.Registry
        and type(PNC.Registry.Data) == "table"
    then
        for _, rec in pairs(PNC.Registry.Data) do
            if type(rec) == "table"
                and (tostring(rec.coreActorID or "") == coreID
                    or (type(rec.runtime) == "table"
                        and tostring(rec.runtime.coreActorID or "") == coreID))
            then
                return nil, rec
            end
        end
    end
    return nil, nil
end

local function resolveHoomansContext(entry)
    if type(entry) ~= "table" then return entry end
    local id = actorID(entry)
    if id == "" then return entry end

    local snaps = clientSnapshots()
    local snapshot = entry.snapshot
    if type(snapshot) ~= "table" and snaps then
        snapshot = snaps[id]
        if type(snapshot) ~= "table" and type(entry.aliases) == "table" then
            for _, alias in ipairs(entry.aliases) do
                snapshot = snaps[tostring(alias or "")]
                if type(snapshot) == "table" then break end
            end
        end
    end

    local record = entry.record
    local isClientOnly = PNC.Core
        and type(PNC.Core.IsClientOnly) == "function"
        and PNC.Core.IsClientOnly() == true
    if type(record) ~= "table"
        and not isClientOnly
        and PNC.Registry
        and type(PNC.Registry.Get) == "function"
    then
        record = PNC.Registry.Get(id)
        if type(record) ~= "table" and type(entry.aliases) == "table" then
            for _, alias in ipairs(entry.aliases) do
                record = PNC.Registry.Get(tostring(alias or ""))
                if type(record) == "table" then break end
            end
        end
    end

    if type(snapshot) ~= "table" and type(record) ~= "table" then
        local foundSnap, foundRec = findByCoreActorID(id)
        snapshot = snapshot or foundSnap
        record = record or foundRec
    end

    local enriched = {}
    for key, value in pairs(entry) do
        enriched[key] = value
    end
    enriched.id = enriched.id or id
    enriched.npcId = enriched.npcId or id
    if type(snapshot) == "table" then
        enriched.snapshot = snapshot
        if snapshot.tacticalClass ~= nil and tostring(snapshot.tacticalClass) ~= ""
            and (enriched.tacticalClass == nil or tostring(enriched.tacticalClass) == "" or tostring(enriched.tacticalClass) == "neutral")
        then
            enriched.tacticalClass = snapshot.tacticalClass
        end
        if snapshot.recruited == true or enriched.recruited == nil then
            enriched.recruited = snapshot.recruited
        end
        if snapshot.colonyOwned == true or enriched.colonyOwned == nil then
            enriched.colonyOwned = snapshot.colonyOwned
        end
        if enriched.orderKind == nil then
            enriched.orderKind = snapshot.orderKind
        end
        if enriched.alive == nil then
            enriched.alive = snapshot.alive
        end
        if enriched.deathMarker == nil then
            enriched.deathMarker = snapshot.deathMarker
        end
        if enriched.iconID == nil then
            enriched.iconID = snapshot.iconID
        end
        if enriched.affiliation == nil then
            enriched.affiliation = snapshot.affiliation
        end
        if snapshot.faction ~= nil and tostring(snapshot.faction) ~= "" then
            enriched.faction = snapshot.faction
        end
        if enriched.ownerUsername == nil then
            enriched.ownerUsername = snapshot.ownerUsername
        end
        if enriched.ownerCharacterUUID == nil then
            enriched.ownerCharacterUUID = snapshot.ownerCharacterUUID
        end
    end
    if type(record) == "table" then
        enriched.record = record
        if record.tacticalClass ~= nil and tostring(record.tacticalClass) ~= ""
            and (enriched.tacticalClass == nil or tostring(enriched.tacticalClass) == "" or tostring(enriched.tacticalClass) == "neutral")
        then
            enriched.tacticalClass = record.tacticalClass
        end
        if record.recruited == true or enriched.recruited == nil then
            enriched.recruited = record.recruited
        end
        if record.colonyOwned == true or enriched.colonyOwned == nil then
            enriched.colonyOwned = record.colonyOwned
        end
        if enriched.orderKind == nil
            and type(record.orderSpec) == "table"
        then
            enriched.orderKind = record.orderSpec.kind
        end
        if enriched.alive == nil then
            enriched.alive = record.alive
        end
        if enriched.affiliation == nil then
            enriched.affiliation = record.affiliation
        end
        if record.faction ~= nil and tostring(record.faction) ~= "" then
            enriched.faction = record.faction
        end
        if enriched.ownerUsername == nil then
            enriched.ownerUsername = record.ownerUsername
        end
        if enriched.ownerCharacterUUID == nil then
            enriched.ownerCharacterUUID = record.ownerCharacterUUID
        end
    end
    -- Fallback: infer colonist ownership from Core ActorExtension or owner fields
    -- so colonists never flash yellow before a roster snapshot arrives.
    if enriched.recruited ~= true and enriched.colonyOwned ~= true then
        local ext = type(entry.extensions) == "table"
            and entry.extensions["ProjectHoomans.ActorExtension"] or nil
        if type(ext) == "table" and ext.recruited == true then
            enriched.recruited = true
            enriched.colonyOwned = true
            if enriched.orderKind == nil and type(ext.orderSpec) == "table" then
                enriched.orderKind = ext.orderSpec.kind
            end
        elseif (enriched.ownerUsername ~= nil and tostring(enriched.ownerUsername) ~= "")
            or (enriched.ownerCharacterUUID ~= nil and tostring(enriched.ownerCharacterUUID) ~= "")
        then
            enriched.recruited = true
            enriched.colonyOwned = true
        end
    end
    return enriched
end

local function displayLabel(entry)
    local id = actorID(entry)
    local roleTag = entry and (entry.role or entry.roleTag) or ""
    local rev = tostring(entry and entry.revision or "")
    local cacheKey = id .. "|" .. rev .. "|" .. tostring(roleTag)
    Presentation.LabelCache = Presentation.LabelCache or {}
    local cached = Presentation.LabelCache[cacheKey]
    if cached ~= nil then return cached end

    local known = true
    if Identity and type(Identity.IsNameKnown) == "function" then
        known = Identity.IsNameKnown(entry) == true
    end
    if not known then
        Presentation.LabelCache[cacheKey] = ""
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
        Presentation.LabelCache[cacheKey] = ""
        return ""
    end

    if roleTag ~= "" then
        name = name .. " [" .. tostring(roleTag) .. "]"
    end
    Presentation.LabelCache[cacheKey] = name
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

            local enriched = resolveHoomansContext(entry)
            local resolvedType = Palette.ResolveType(enriched)

            -- Preserve DynamicTrading's commercial marker only for alive,
            -- neutral, trade-capable merchants. Never let trader styling
            -- override colonists, followers, hostiles, dead NPCs, or
            -- non-merchant group escorts/guards.
            if style.hoverMetadata
                and style.hoverMetadata.traderID
                and style.hoverMetadata.tradeAvailable ~= false
                and resolvedType == "neutral"
            then
                return style
            end

            style.label = displayLabel(enriched)
            style.color = Palette.Get(resolvedType)
            style.size = 9
            style.icon = iconFor(enriched, style.color)
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
