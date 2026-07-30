-- Pure relationship-state thresholds and hysteresis.

PNC = PNC or {}
PNC.RelationshipStates = PNC.RelationshipStates or {}

local States = PNC.RelationshipStates
local Constants = PNC.RelationshipConstants

function States.ResolveState(relationship)
    local source = type(relationship) == "table" and relationship or {}
    local approval = tonumber(source.approval) or 0
    local respect = tonumber(source.respect) or 0
    local familiarity = tonumber(source.familiarity) or 0
    local current = Constants.VALID_STATES[tostring(source.state or "")]
        and tostring(source.state) or Constants.STATE_UNKNOWN

    if familiarity < Constants.UNKNOWN_FAMILIARITY_EXIT then
        return Constants.STATE_UNKNOWN
    end

    if current == Constants.STATE_FRIEND
        and approval >= Constants.FRIEND_APPROVAL_EXIT
        and respect >= Constants.FRIEND_RESPECT_EXIT
    then
        return Constants.STATE_FRIEND
    end
    if current == Constants.STATE_RIVAL
        and approval <= Constants.RIVAL_APPROVAL_EXIT
        and respect >= Constants.RIVAL_RESPECT_EXIT
    then
        return Constants.STATE_RIVAL
    end
    if current == Constants.STATE_ENEMY
        and approval <= Constants.ENEMY_APPROVAL_EXIT
    then
        return Constants.STATE_ENEMY
    end

    if approval >= Constants.FRIEND_APPROVAL_ENTER
        and respect >= Constants.FRIEND_RESPECT_ENTER
    then
        return Constants.STATE_FRIEND
    end
    if approval <= Constants.RIVAL_APPROVAL_ENTER
        and respect >= Constants.RIVAL_RESPECT_ENTER
    then
        return Constants.STATE_RIVAL
    end
    if approval <= Constants.ENEMY_APPROVAL_ENTER
        and respect < Constants.ENEMY_RESPECT_MAX_ENTER
    then
        return Constants.STATE_ENEMY
    end
    return Constants.STATE_NEUTRAL
end

return States
