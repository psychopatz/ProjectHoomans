-- Debug-only mobile-group lifecycle actions. Domain state remains owned by
-- MobileGroupDirector and AbstractTraversal.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FactionDebug = PNC.FactionDebug or {}
PNC.FactionDebug.Internal = PNC.FactionDebug.Internal or {}

local Internal = PNC.FactionDebug.Internal
local Director = PNC.MobileGroupDirector
local MobileInternal = PNC.MobileGroupDirectorInternal
local Groups = PNC.AbstractGroups
local Traversal = PNC.AbstractTraversal

local function createArgs(args, archetypeID)
    return {
        archetypeID = archetypeID,
        creationKind = "mobile_group",
        groupSize = args and args.groupSize,
        presenceMode = args and args.presenceMode or "abstract",
        mobilePathMode = "random",
        mobileControlMode = "ambient",
    }
end

function Internal.handleMobileGroupAction(player, args, action, context)
    local ok
    local reason
    local factionID = context and context.factionID
    if action == "create_mobile_road_group"
        or action == "create_mobile_en_route_group"
        or action == "create_mobile_player_route_group"
        or action == "create_mobile_ai_route_group"
    then
        if action == "create_mobile_player_route_group"
            and (not MobileInternal
                or not MobileInternal.PlayerBaseCount
                or tonumber(MobileInternal.PlayerBaseCount()) < 1)
        then
            return true, false, "player_base_required"
        end
        local archetypeID = tostring(args and args.archetypeID or "looter")
        if action == "create_mobile_player_route_group" then
            archetypeID = "looter"
        elseif action == "create_mobile_ai_route_group" then
            archetypeID = "refugee"
        end
        local handled
        handled, ok, reason = Internal.handleCreationAction(
            player,
            createArgs(args, archetypeID),
            "create",
            context
        )
        if not handled then return false end
        if not ok then return true, false, reason end
        factionID = context.factionID
        ok, reason, context.objectiveResult =
            Director.ForceRoadRoaming(factionID, context.at)
        if not ok then return true, false, reason end
        if action == "create_mobile_en_route_group"
            or action == "create_mobile_player_route_group"
            or action == "create_mobile_ai_route_group"
        then
            ok, reason, context.value = Director.StartSettlementTravel(
                factionID, nil, context.at)
        end
        return true, ok, reason
    end

    if action == "force_mobile_road" then
        ok, reason, context.value = Director.ForceRoadRoaming(
            factionID, context.at)
    elseif action == "force_mobile_departure" then
        ok, reason, context.value = Director.StartSettlementTravel(
            factionID, nil, context.at)
    elseif action == "roll_mobile_departures" then
        local budget = math.max(1, math.min(24, math.floor(
            tonumber(args and args.departureBudget) or 12)))
        local moved = Director.PumpDepartures(context.at, budget)
        ok, reason, context.value = true,
            "mobile_departures_pumped_" .. tostring(moved), {
                moved = moved,
                budget = budget,
            }
    elseif action == "force_mobile_arrival" then
        local group = Groups and Groups.FindByFactionID
            and Groups.FindByFactionID(factionID) or nil
        if not group then
            ok, reason = false, "mobile_group_abstract_record_missing"
        else
            ok, reason = Traversal.ForceArrival(group.id, context.at)
        end
    elseif action == "repair_mobile_travel" then
        ok, reason, context.value = Director.ResetSettlementTravel(
            factionID, context.at)
    else
        return false
    end
    return true, ok, reason
end

return PNC.FactionDebug
