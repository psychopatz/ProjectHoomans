-- Build 42.20 NPC presentation palette implementation.
PNC = PNC or {}
PNC.NPCTypePalette = PNC.NPCTypePalette or {}

local Palette = PNC.NPCTypePalette

Palette.COLORS = Palette.COLORS or {
    colonist = { r = 0.08, g = 0.42, b = 0.16 },
    follower = { r = 0.15, g = 0.90, b = 0.25 },
    dead = { r = 0.55, g = 0.55, b = 0.55 },
    deadColonist = { r = 0.55, g = 0.55, b = 0.55 },
    neutral = { r = 0.95, g = 0.75, b = 0.20 },
    hostile = { r = 1.00, g = 0.25, b = 0.20 },
}

local function firstValue(...)
    local index
    for index = 1, select("#", ...) do
        local value = select(index, ...)
        if value ~= nil and tostring(value) ~= "" then
            return value
        end
    end
    return nil
end

local function entryFacts(entry)
    entry = type(entry) == "table" and entry or {}
    local snapshot = type(entry.snapshot) == "table" and entry.snapshot or {}
    local record = type(entry.record) == "table" and entry.record or {}
    local orderSpec = type(record.orderSpec) == "table"
        and record.orderSpec or {}
    local corpseState = PNC.Const
        and PNC.Const.PRESENCE_CORPSE
    local verifier = PNC.Identity
        and PNC.Identity.Verifier or nil
    local tacticalClass = string.lower(tostring(firstValue(
        entry.tacticalClass,
        snapshot.tacticalClass,
        record.tacticalClass,
        "neutral"
    )))
    local colonist = verifier
        and verifier.IsColonyOwnedNPC
        and verifier.IsColonyOwnedNPC(entry)
        or entry.colonyOwned == true
        or entry.recruited == true
        or snapshot.colonyOwned == true
        or snapshot.recruited == true
        or record.colonyOwned == true
        or record.recruited == true
    local deathMarker = entry.deathMarker == true
        or snapshot.deathMarker == true
        or record.deathMarker == true
        or entry.alive == false
        or snapshot.alive == false
        or record.alive == false
        or corpseState ~= nil and (
            entry.presenceState == corpseState
            or snapshot.presenceState == corpseState
            or record.presenceState == corpseState
        )
    local orderKind = string.lower(tostring(firstValue(
        entry.orderKind,
        snapshot.orderKind,
        orderSpec.kind,
        ""
    )))
    return tacticalClass, colonist, deathMarker, orderKind
end

function Palette.ResolveType(entry)
    local tacticalClass, colonist, deathMarker, orderKind = entryFacts(entry)
    if deathMarker then
        return colonist and "deadColonist" or "dead"
    end
    if colonist
        and orderKind
            == string.lower(tostring(
                PNC.Const and PNC.Const.ORDER_FOLLOW or "follow"
            ))
    then
        return "follower"
    end
    if colonist then return "colonist" end
    if Palette.COLORS[tacticalClass] then return tacticalClass end
    return "neutral"
end

function Palette.Get(typeID)
    return Palette.COLORS[tostring(typeID or "")]
        or Palette.COLORS.neutral
end

function Palette.Resolve(entry)
    return Palette.Get(Palette.ResolveType(entry))
end

function Palette.BuildConversationTheme(entry)
    local typeID = Palette.ResolveType(entry)
    local color = Palette.Get(typeID)
    return {
        id = typeID,
        accent = {
            r = color.r,
            g = color.g,
            b = color.b,
        },
    }
end

return Palette
