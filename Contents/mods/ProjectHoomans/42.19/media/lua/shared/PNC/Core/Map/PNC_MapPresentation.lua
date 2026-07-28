-- Persistent, relationship-agnostic map marker metadata.
--
-- Travel owns where an NPC is. This module owns whether a player may see that
-- NPC and how other systems (trading, quests, jobs) describe its map marker.

PNC = PNC or {}
PNC.MapPresentation = PNC.MapPresentation or {}

local Presentation = PNC.MapPresentation
local Const = PNC.Const

Presentation.VISIBILITY_ALL = "all"
Presentation.VISIBILITY_KNOWN = "known"
Presentation.VISIBILITY_SELECTED = "selected"
Presentation.VISIBILITY_HIDDEN = "hidden"

local VALID_VISIBILITY = {
    all = true,
    known = true,
    selected = true,
    hidden = true,
}

local function boundedString(value, maximum)
    local output
    if value == nil then return nil end
    output = tostring(value):match("^%s*(.-)%s*$")
    if output == "" then return nil end
    maximum = math.max(1, tonumber(maximum) or 64)
    if #output > maximum then
        output = string.sub(output, 1, maximum)
    end
    return output
end

local function normalizeVisibility(value)
    value = string.lower(tostring(value or Presentation.VISIBILITY_ALL))
    if VALID_VISIBILITY[value] then return value end
    return Presentation.VISIBILITY_ALL
end

local function copyKnownBy(source)
    local output = {}
    local count = 0
    local maximum = math.max(
        1,
        tonumber(Const.MAP_PRESENTATION_MAX_KNOWN_PLAYERS) or 64
    )
    local key
    local known
    if type(source) ~= "table" then return output end
    for key, known in pairs(source) do
        key = boundedString(key, 128)
        if key and known == true and count < maximum then
            output[key] = true
            count = count + 1
        end
    end
    return output
end

function Presentation.Normalize(raw)
    local source = type(raw) == "table" and raw or {}
    return {
        visibility = normalizeVisibility(source.visibility),
        knownBy = copyKnownBy(source.knownBy),
        roleTag = boundedString(
            source.roleTag,
            Const.MAP_PRESENTATION_ROLE_MAX_LENGTH
        ),
        iconID = boundedString(
            source.iconID,
            Const.MAP_PRESENTATION_ICON_MAX_LENGTH
        ),
        revision = math.max(
            0,
            math.floor(tonumber(source.revision) or 0)
        ),
    }
end

function Presentation.BuildSummary(raw)
    return Presentation.Normalize(raw)
end

function Presentation.Apply(record, spec)
    local current
    local updated
    if type(record) ~= "table" or type(spec) ~= "table" then
        return nil, "invalid_arguments"
    end
    current = Presentation.Normalize(record.mapPresentation)
    updated = Presentation.Normalize(current)
    if spec.visibility ~= nil then
        updated.visibility = normalizeVisibility(spec.visibility)
    end
    if spec.knownBy ~= nil then
        updated.knownBy = copyKnownBy(spec.knownBy)
    end
    if spec.clearRole == true then
        updated.roleTag = nil
    elseif spec.roleTag ~= nil then
        updated.roleTag = boundedString(
            spec.roleTag,
            Const.MAP_PRESENTATION_ROLE_MAX_LENGTH
        )
    end
    if spec.clearIcon == true then
        updated.iconID = nil
    elseif spec.iconID ~= nil then
        updated.iconID = boundedString(
            spec.iconID,
            Const.MAP_PRESENTATION_ICON_MAX_LENGTH
        )
    end
    updated.revision = current.revision + 1
    record.mapPresentation = updated
    return updated
end

function Presentation.SetKnown(record, playerKey, known)
    local current
    local key = boundedString(playerKey, 128)
    local count = 0
    local knownKey
    if type(record) ~= "table" or not key then
        return nil, "invalid_arguments"
    end
    current = Presentation.Normalize(record.mapPresentation)
    if known == true then
        if current.knownBy[key] ~= true then
            for knownKey in pairs(current.knownBy) do
                count = count + 1
            end
            if count >= math.max(
                1,
                tonumber(Const.MAP_PRESENTATION_MAX_KNOWN_PLAYERS) or 64
            ) then
                return nil, "known_player_limit"
            end
        end
        current.knownBy[key] = true
    else
        current.knownBy[key] = nil
    end
    current = Presentation.Normalize(current)
    current.revision = (
        tonumber(record.mapPresentation and record.mapPresentation.revision)
        or 0
    ) + 1
    record.mapPresentation = current
    return current
end

function Presentation.IsVisibleFor(raw, playerKey, selected)
    local presentation
    local key
    if selected == true then return true end
    presentation = Presentation.Normalize(raw)
    if presentation.visibility == Presentation.VISIBILITY_ALL then
        return true
    end
    if presentation.visibility ~= Presentation.VISIBILITY_KNOWN then
        return false
    end
    key = boundedString(playerKey, 128)
    return presentation.knownBy["*"] == true
        or key ~= nil and presentation.knownBy[key] == true
        or false
end

return Presentation
