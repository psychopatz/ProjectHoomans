-- Canonical client-side portrait spec builder for Project Hoomans UI surfaces.
--
-- Map hover cards, conversation portraits, and character windows all build
-- their PsychopatzPortraitPanel specs through this module so:
--   1. Every surface renders the exact same live appearance, gender, clothing,
--      and wornVisuals tints (eliminating Core-vs-Hoomans portrait drift).
--   2. Every surface produces identical content-addressed Descriptor keys and
--      reuses the shared SurvivorDesc LRU cache in PsychopatzPortraitPanel
--      without duplicate allocations.
--   3. Appearance or clothing changes automatically produce a new key and
--      refresh the portrait without forced 500ms rebuilds.

PNC = PNC or {}
PNC.ClientPortraitSpec = PNC.ClientPortraitSpec or {}

local Spec = PNC.ClientPortraitSpec

local function actorIDFor(value)
    if type(value) == "table" then
        value = value.actorID or value.id or value.npcId
    end
    value = tostring(value or "")
    return value ~= "" and value or nil
end

local function resolveRecord(id, suppliedRecord)
    if type(suppliedRecord) == "table" then return suppliedRecord end
    local isClientOnly = PNC.Core
        and type(PNC.Core.IsClientOnly) == "function"
        and PNC.Core.IsClientOnly() == true
    if isClientOnly or not id then return nil end
    if PNC.Registry and type(PNC.Registry.Get) == "function" then
        return PNC.Registry.Get(id)
    end
    return nil
end

local function resolveSnapshot(id, suppliedSnapshot)
    if type(suppliedSnapshot) == "table" then return suppliedSnapshot end
    if not id then return nil end
    local state = PNC.Network and PNC.Network.ClientState or nil
    return state and type(state.snapshots) == "table"
        and state.snapshots[id] or nil
end

local function hasNonEmptyTable(tbl)
    if type(tbl) ~= "table" then return false end
    for _ in pairs(tbl) do return true end
    return false
end

local function resolveHoomansSummary(id, record, snapshot, entry)
    local summary
    local revision

    if type(record) == "table"
        and PNC.Identity
        and type(PNC.Identity.BuildPortraitSummary) == "function"
    then
        summary = PNC.Identity.BuildPortraitSummary(record)
        if type(summary) == "table" then
            revision = summary.revision
            return summary, revision
        end
    end

    if type(snapshot) == "table" and type(snapshot.portrait) == "table" then
        return snapshot.portrait, snapshot.portrait.revision
    end

    if id and PNC.Client and type(PNC.Client.GetRosterPortrait) == "function"
        and not (entry and entry.deathMarker)
    then
        local hasRef = type(snapshot) == "table" and snapshot.portraitRef ~= nil
        local needsRoster = hasRef or not (type(snapshot) == "table"
            and hasNonEmptyTable(snapshot.appearance))
        if needsRoster then
            summary, revision = PNC.Client.GetRosterPortrait(id)
            if type(summary) == "table" then
                return summary, revision or summary.revision
            end
        end
    end

    if type(entry) == "table" and type(entry.portrait) == "table"
        and type(entry.portrait.face) ~= "table"
    then
        return entry.portrait, entry.portrait.revision
    end

    return nil, nil
end

--- Builds a normalized PsychopatzPortraitPanel spec for any Hoomans or
--- SurvivorWorld actor. Returns nil only when no portrait data is available.
function Spec.Build(actorOrID, options)
    options = type(options) == "table" and options or {}
    local entry = type(actorOrID) == "table" and actorOrID or options.entry
    local id = actorIDFor(actorOrID) or actorIDFor(options.id)

    local record = resolveRecord(id, options.record)
    local snapshot = resolveSnapshot(id, options.snapshot)
    local payload = type(options.payload) == "table" and options.payload or nil
    local summary, summaryRevision = resolveHoomansSummary(
        id, record, snapshot, entry
    )

    local appearance
    if type(summary) == "table" and hasNonEmptyTable(summary.appearance) then
        appearance = summary.appearance
    elseif type(snapshot) == "table" and hasNonEmptyTable(snapshot.appearance) then
        appearance = snapshot.appearance
    elseif type(record) == "table" then
        if type(record.runtime) == "table"
            and type(record.runtime.appearanceCache) == "table"
        then
            appearance = record.runtime.appearanceCache
        elseif type(record.appearance) == "table" then
            appearance = type(record.appearance.resolved) == "table"
                and record.appearance.resolved or record.appearance
        end
    end

    local equipment = (payload and type(payload.equipment) == "table"
            and payload.equipment)
        or (type(summary) == "table" and type(summary.equipment) == "table"
            and summary.equipment)
        or (type(snapshot) == "table" and type(snapshot.equipmentSummary) == "table"
            and snapshot.equipmentSummary)
        or (type(record) == "table" and type(record.equipment) == "table"
            and record.equipment)
        or nil

    if type(appearance) == "table" or type(summary) == "table" then
        appearance = type(appearance) == "table" and appearance or {}
        equipment = type(equipment) == "table" and equipment or { worn = {} }

        local isFemale = false
        if type(summary) == "table" and summary.isFemale ~= nil then
            isFemale = summary.isFemale == true
        elseif type(record) == "table" and record.isFemale ~= nil then
            isFemale = record.isFemale == true
        elseif type(record) == "table" and type(record.identity) == "table"
            and record.identity.isFemale ~= nil
        then
            isFemale = record.identity.isFemale == true
        elseif type(snapshot) == "table" and snapshot.isFemale ~= nil then
            isFemale = snapshot.isFemale == true
        end

        local identitySeed = (type(summary) == "table" and summary.identitySeed)
            or (type(record) == "table" and record.identitySeed)
            or (type(snapshot) == "table" and snapshot.identitySeed)
            or 1

        local faceOnly = options.faceOnly
        if faceOnly == nil then faceOnly = true end
        local includeCurrentClothing = options.includeCurrentClothing
        if includeCurrentClothing == nil then includeCurrentClothing = true end

        return {
            id = id,
            actorID = id,
            revision = summaryRevision
                or (type(summary) == "table" and summary.revision)
                or (type(snapshot) == "table" and snapshot.presenceRevision)
                or nil,
            identitySeed = identitySeed,
            isFemale = isFemale,
            -- Live NPCs use IsoZombie carriers for engine animation/replication.
            -- Portraits render the descriptor-backed human preview so the
            -- carrier's zombie appearance is never exposed and all UIs share
            -- one bounded SurvivorDesc cache.
            preferDescriptor = true,
            faceOnly = faceOnly == true,
            includeCurrentClothing = includeCurrentClothing == true,
            clothingMode = options.clothingMode or "current",
            outfit = appearance.outfit,
            appearance = appearance,
            equipment = equipment,
        }
    end

    -- Pure Core / DTAbstract actors without a Hoomans record or snapshot fall
    -- back to PsychopatzCore's canonical SurvivorWorld portrait projection.
    local coreFallback = options.coreFallback
    if type(coreFallback) == "function" and entry then
        return coreFallback(entry)
    end
    local swClient = PsychopatzCore and PsychopatzCore.SurvivorWorldClient or nil
    if swClient and type(swClient.GetPortraitSpec) == "function" and entry then
        return swClient.GetPortraitSpec(entry)
    end
    return nil
end

return Spec
