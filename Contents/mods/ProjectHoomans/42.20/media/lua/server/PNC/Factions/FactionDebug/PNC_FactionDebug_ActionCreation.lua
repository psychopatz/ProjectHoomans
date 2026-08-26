if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FactionDebug = PNC.FactionDebug or {}
PNC.FactionDebug.Internal = PNC.FactionDebug.Internal or {}

local Debug = PNC.FactionDebug
local Internal = Debug.Internal
local Factions = PNC.Factions
local Archetypes = PNC.FactionArchetypes
local Types = PNC.FactionTypes
local Core = PNC.Core
local Balance = PNC.FactionBalance


local generatedFactionName = Internal.generatedFactionName
local groupSpec = Internal.groupSpec
local mobileGroupSpec = Internal.mobileGroupSpec

function Internal.handleCreationAction(player, args, action, context)
    local ok
    local reason
    if action == "create" then
        local archetypeID = tostring(args and args.archetypeID or "")
        local archetype = Archetypes.Get(archetypeID)
        if not archetype then
            context.targetFactionID = nil
            return true, false, "unknown_archetype"
        end
        local tags = { debugCreated = true }
        local mobileGroup = args and args.creationKind == "mobile_group"
            or archetypeID == "refugee"
        if archetypeID == "settler" then
            tags.settlementType = "friendly"
        elseif archetypeID == "looter" and not mobileGroup then
            tags.settlementType = "looter_toll"
            tags.territorialToll = true
        end
        if mobileGroup then
            tags.mobileGroup = true
            tags.mobilePathMode = tostring(
                args and args.mobilePathMode or "random")
            if args and args.mobileControlMode then
                tags.mobileControlMode = tostring(
                    args.mobileControlMode)
            end
        end
        ok, reason, context.value = Factions.Create({
            name = generatedFactionName(archetypeID, context.at),
            archetypeID = archetypeID,
            createdAt = context.at,
            tags = tags,
        })
        if ok then
            context.factionID = context.value.id
            if mobileGroup then
                ok, reason, context.groupResult =
                    PNC.MobileGroupDirector.GenerateForFaction(
                        context.factionID,
                        mobileGroupSpec(player, args, context.at))
                if ok and args and args.refreshMobileObjective
                    and PNC.MobileGroupDirector.RefreshFactionObjective
                then
                    ok, reason, context.objectiveResult =
                        PNC.MobileGroupDirector.RefreshFactionObjective(
                            context.factionID, context.at)
                end
            else
                ok, reason, context.groupResult =
                    PNC.CommunityDirector.GenerateForFaction(
                        context.factionID,
                        groupSpec(player, args, context.at))
            end
        end
    elseif action == "create_player_faction" then
        ok, reason, context.value = Factions.CreatePlayerFaction(player, {
            name = generatedFactionName("settler", context.at),
            archetypeID = "settler",
            createdAt = context.at,
            tags = { debugCreated = true },
            emblem = args and args.emblem,
        })
        if ok and context.value then
            context.factionID = context.value.id
            ok, reason, context.groupResult =
                PNC.CommunityDirector.GenerateForFaction(
                    context.factionID,
                    groupSpec(player, args, context.at))
        end
    elseif action == "set_emblem" then
        ok, reason, context.value = Factions.SetPlayerFactionEmblem(
            player, args and args.emblem)
        if ok and context.value then
            context.factionID = context.value.id
        end
    elseif action == "generate_group" then
        local faction = context.factionID
            and Factions.Get(context.factionID)
        if faction and Factions.IsMobileGroup(faction) then
            ok, reason, context.groupResult =
                PNC.MobileGroupDirector.GenerateForFaction(
                    context.factionID,
                    mobileGroupSpec(player, args, context.at))
            if ok and args and args.refreshMobileObjective
                and PNC.MobileGroupDirector.RefreshFactionObjective
            then
                ok, reason, context.objectiveResult =
                    PNC.MobileGroupDirector.RefreshFactionObjective(
                        context.factionID, context.at)
            end
        else
            ok, reason, context.groupResult =
                PNC.CommunityDirector.GenerateForFaction(
                    context.factionID,
                    groupSpec(player, args, context.at))
        end
    elseif action == "mobile_path_mode" then
        ok, reason, context.value = PNC.MobileGroupDirector.SetPathMode(
            context.factionID, args and args.mobilePathMode)
        if ok and args and args.refreshMobileObjective
            and PNC.MobileGroupDirector.RefreshFactionObjective
        then
            ok, reason, context.objectiveResult =
                PNC.MobileGroupDirector.RefreshFactionObjective(
                    context.factionID, context.at)
        end
    elseif action == "mobile_control_mode" then
        ok, reason, context.value =
            PNC.MobileGroupDirector.SetControlMode(
                context.factionID, args and args.mobileControlMode)
        if ok and args and args.refreshMobileObjective
            and PNC.MobileGroupDirector.RefreshFactionObjective
        then
            ok, reason, context.objectiveResult =
                PNC.MobileGroupDirector.RefreshFactionObjective(
                    context.factionID, context.at)
        end
    elseif action == "mobile_refresh" then
        ok, reason, context.objectiveResult =
            PNC.MobileGroupDirector.RefreshFactionObjective(
                context.factionID, context.at)
    elseif action == "mobile_relocate" then
        ok, reason, context.value =
            PNC.MobileGroupDirector.RelocateFaction(
                context.factionID, context.at, true)
    else
        return false
    end
    return true, ok, reason
end

return Debug
