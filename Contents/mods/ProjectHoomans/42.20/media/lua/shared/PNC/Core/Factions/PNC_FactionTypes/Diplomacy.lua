PNC = PNC or {}
PNC.FactionTypes = PNC.FactionTypes or {}
PNC.FactionTypes.Internal = PNC.FactionTypes.Internal or {}

local Types = PNC.FactionTypes
local Internal = Types.Internal
local Constants = PNC.FactionConstants
local EntityRef = PNC.EntityRef

function Internal.IsValidPlayerKey(value)
    return EntityRef and EntityRef.IsPlayer
        and EntityRef.IsPlayer(value) == true
end

function Types.MakeDiplomacyKey(firstFactionID, secondFactionID)
    if not Types.IsValidFactionID(firstFactionID)
        or not Types.IsValidFactionID(secondFactionID)
        or firstFactionID == secondFactionID
    then
        return nil
    end
    if firstFactionID < secondFactionID then
        return firstFactionID .. "|" .. secondFactionID
    end
    return secondFactionID .. "|" .. firstFactionID
end

function Types.NormalizeDiplomacy(value, pairKey)
    local source = type(value) == "table" and value or {}
    local first = Types.IsValidFactionID(source.factionAID)
        and source.factionAID or nil
    local second = Types.IsValidFactionID(source.factionBID)
        and source.factionBID or nil
    local expected = Types.MakeDiplomacyKey(first, second)
    if not expected or (pairKey ~= nil and pairKey ~= expected) then
        return nil
    end
    if second < first then
        first, second = second, first
    end
    return {
        factionAID = first,
        factionBID = second,
        state = Constants.VALID_DIPLOMACY_STATES[source.state]
            and source.state or Constants.DIPLOMACY_PEACE,
        changedAt = Internal.Timestamp(source.changedAt, 0),
        reason = Internal.SafeString(
            source.reason,
            Constants.DIPLOMACY_REASON_MAX_LENGTH
        ) or "unspecified",
        instigatorFactionID =
            (
                source.instigatorFactionID == first
                or source.instigatorFactionID == second
            ) and source.instigatorFactionID or nil,
        revision = Internal.Revision(source.revision),
    }
end
