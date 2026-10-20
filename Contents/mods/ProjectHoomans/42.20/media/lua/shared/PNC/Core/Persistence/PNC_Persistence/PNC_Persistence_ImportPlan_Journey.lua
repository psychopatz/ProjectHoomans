-- Location and journey provenance validation for the P0B planner.

local Utils = require
    "PNC/Core/Persistence/PNC_Persistence/PNC_Persistence_ImportPlan_Utils"

local Journey = {}
local JOURNEY_SCHEMA = tonumber(PNC.Const and PNC.Const.TRAVEL_SCHEMA_VERSION)
    or 1

local function add(decisions, ...)
    return Utils.AddDecision(decisions, ...)
end

local function locationValue(raw, source, key, xKey)
    if raw and type(raw[key]) == "table" then return Utils.Copy(raw[key]) end
    if source and source[xKey] ~= nil then
        local yKey
        local zKey
        if key == "position" then
            yKey, zKey = "y", "z"
        elseif key == "spawn" then
            yKey, zKey = "spawnY", "spawnZ"
        else
            yKey, zKey = "anchorY", "anchorZ"
        end
        if source[yKey] == nil or source[zKey] == nil then return nil end
        return { x = source[xKey], y = source[yKey], z = source[zKey] }
    end
    return nil
end

function Journey.Build(raw, source, decisions)
    local position = locationValue(raw, source, "position", "x")
    local spawn = locationValue(raw, source, "spawn", "spawnX")
    local anchor = locationValue(raw, source, "anchor", "anchorX")
    local rawJourney = raw and type(raw.travel) == "table"
        and raw.travel or nil
    local sourceJourney = source and type(source.travel) == "table"
        and source.travel or nil
    local journey = rawJourney or sourceJourney
    local values = {
        { "location.position", position, "position" },
        { "location.spawn", spawn, "spawn" },
        { "location.anchor", anchor, "anchor" },
    }
    local output = {
        position = position,
        spawn = spawn,
        anchor = anchor,
        journey = Utils.Copy(journey),
    }
    local i
    for i = 1, #values do
        if type(values[i][2]) ~= "table" then
            add(decisions, values[i][1], "quarantined", values[i][3],
                "location_value_missing")
        end
    end
    if not journey then return output end

    local rawSignature = rawJourney
        and table.concat({
            tostring(rawJourney.journeyId or ""),
            tostring(rawJourney.revision or ""),
            tostring(rawJourney.state or ""),
        }, ":") or nil
    local sourceSignature = sourceJourney
        and table.concat({
            tostring(sourceJourney.journeyId or ""),
            tostring(sourceJourney.revision or ""),
            tostring(sourceJourney.state or ""),
        }, ":") or nil
    local blocked = false
    if rawJourney and sourceJourney
        and (rawJourney.journeyId == nil
            or rawJourney.revision == nil
            or rawJourney.state == nil
            or sourceJourney.journeyId == nil
            or sourceJourney.revision == nil
            or sourceJourney.state == nil)
    then
        blocked = true
        add(decisions, "location.journey", "quarantined", "travel",
            "journey_provenance_incomplete")
    elseif rawJourney and sourceJourney
        and rawSignature ~= sourceSignature
    then
        blocked = true
        add(decisions, "location.journey", "quarantined", "travel",
            "journey_source_conflict")
    elseif journey.journeyId == nil or journey.revision == nil
        or journey.state == nil
    then
        blocked = true
        add(decisions, "location.journey", "quarantined", "travel",
            "journey_provenance_incomplete")
    elseif journey.schemaVersion ~= nil
        and tonumber(journey.schemaVersion) ~= JOURNEY_SCHEMA
    then
        blocked = true
        add(decisions, "location.journey", "quarantined",
            "travel.schemaVersion", "journey_schema_unsupported")
    else
        if journey.metadata ~= nil and type(journey.metadata) ~= "table" then
            blocked = true
            add(decisions, "location.journey.metadata", "quarantined",
                "travel.metadata", "journey_metadata_unrepresentable")
        elseif journey.metadata ~= nil then
            if not (sourceJourney and sourceJourney.metadata
                and rawJourney and rawJourney.metadata
                and Utils.Canonical(sourceJourney.metadata)
                    ~= Utils.Canonical(rawJourney.metadata))
            then
                add(decisions, "location.journey.metadata", "copied",
                    "travel.metadata", nil)
            end
        end
        if journey.arrivalAction ~= nil
            and type(journey.arrivalAction) ~= "table"
        then
            blocked = true
            add(decisions, "location.journey.arrivalAction",
                "quarantined", "travel.arrivalAction",
                "journey_arrival_action_unrepresentable")
        end
        if sourceJourney and sourceJourney.metadata
            and rawJourney and rawJourney.metadata
            and Utils.Canonical(sourceJourney.metadata)
                ~= Utils.Canonical(rawJourney.metadata)
        then
            blocked = true
            add(decisions, "location.journey.metadata", "quarantined",
                "travel.metadata", "opaque_nested_field_not_serialized")
        end
        if sourceJourney and sourceJourney.opaque ~= nil
            and (not rawJourney or rawJourney.opaque == nil)
        then
            blocked = true
            add(decisions, "location.journey.opaque", "quarantined",
                "travel.opaque", "opaque_nested_field_not_serialized")
        elseif journey.opaque ~= nil and type(journey.opaque) ~= "table" then
            blocked = true
            add(decisions, "location.journey.opaque", "quarantined",
                "travel.opaque", "opaque_nested_field_unrepresentable")
        elseif journey.opaque ~= nil then
            add(decisions, "location.journey.opaque", "copied",
                "travel.opaque", nil)
        end
        if not blocked then
            add(decisions, "location.journey", "copied",
                rawJourney and "travel" or "source.travel", nil)
        end
    end
    return output
end

return Journey
