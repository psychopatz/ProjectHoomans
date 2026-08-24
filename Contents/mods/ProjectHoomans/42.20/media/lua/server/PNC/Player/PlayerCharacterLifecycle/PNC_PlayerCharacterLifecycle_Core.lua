if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local H = PNC.PlayerCharacterLifecycle.Internal

function H.WorldAgeHours()
    if getGameTime and getGameTime() and getGameTime().getWorldAgeHours then
        return math.max(0,
            tonumber(getGameTime():getWorldAgeHours()) or 0)
    end
    return 0
end

function H.Service()
    return PNC.PlayerCharacters
end

function H.EnsureIdentityAndProfile(player, callback, at)
    local identity = H.Service()
    local uuid
    local reason
    if not identity then return nil, "service_unavailable" end
    local context
    context, reason = PNC.PlayerContext.Resolve(player, callback)
    uuid = context and context.characterUUID or nil
    if uuid and PNC.SocialProfiles
        and PNC.SocialProfiles.EnsurePlayerProfile
    then
        PNC.SocialProfiles.EnsurePlayerProfile(player, at)
    end
    if uuid and PNC.Factions
        and PNC.Factions.EnsurePlayerDiplomacyFaction
    then
        PNC.Factions.EnsurePlayerDiplomacyFaction(
            player, { worldAgeHours = at })
    end
    if uuid and PNC.Factions and PNC.Factions.GetPlayerDiplomacyFaction
        and PNC.FactionBehavior and PNC.FactionBehavior.ReconcileFaction
    then
        local faction = PNC.Factions.GetPlayerDiplomacyFaction(player)
        if faction then
            PNC.FactionBehavior.ReconcileFaction(
                faction.id, "player_identity_bound")
        end
    end
    if uuid and PNC.StartingCompanions and PNC.StartingCompanions.Ensure then
        local granted = PNC.StartingCompanions.Ensure(player, uuid, at)
        if granted == true and PNC.Network
            and PNC.Network.SendColonyManagement and PNC.ColonyManagement
            and PNC.ColonyManagement.BuildSnapshot
        then
            PNC.Network.SendColonyManagement(player,
                PNC.ColonyManagement.BuildSnapshot(player))
        end
    end
    return uuid, reason
end

function H.CallbackPlayer(first, second)
    if first and first.getModData then return first end
    if second and second.getModData then return second end
    if type(first) == "number" and getSpecificPlayer then
        return getSpecificPlayer(first)
    end
    return nil
end

return H
