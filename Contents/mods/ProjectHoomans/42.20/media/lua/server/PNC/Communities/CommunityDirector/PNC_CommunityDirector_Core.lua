if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local H = PNC.CommunityDirector.Internal
local Constants = PNC.CommunityConstants
local Communities = PNC.Communities
local Factions = PNC.Factions

function H.WorldAge(value)
    value = tonumber(value)
    if value and value == value
        and value ~= math.huge
        and value ~= -math.huge
    then
        return math.max(0, value)
    end
    local gameTime = getGameTime and getGameTime() or nil
    return gameTime and gameTime.getWorldAgeHours
        and math.max(
            0,
            tonumber(gameTime:getWorldAgeHours()) or 0
        ) or 0
end

function H.NormalizedGroupSize(value)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        value = Constants.GROUP_SIZE_DEFAULT
    end
    return math.max(
        Constants.GROUP_SIZE_MIN,
        math.min(
            Constants.GROUP_SIZE_MAX,
            math.floor(value)
        )
    )
end

function H.NormalizedPresenceMode(value)
    return Constants.VALID_GROUP_PRESENCE_MODES[value]
        and value or "auto"
end

-- Settlement rosters are positional: member spawn index -> Project Hoomans
-- faction role. Every trading archetype lists its trader explicitly so a
-- settlement of that archetype is staffed with one, and members past the end of
-- the list fall back to the archetype default role (civilian: a member with no
-- specific job).
local ROLE_ORDER = {
    settler = {
        "leader", "trader", "guard", "medic", "farmer",
        "builder", "scavenger", "cook", "mechanic",
    },
    looter = {
        "leader", "raider", "enforcer", "scavenger",
        "guard", "medic",
    },
    trader = {
        "leader", "trader", "guard", "medic",
        "mechanic", "scavenger", "laborer",
    },
    refugee = {
        "leader", "trader", "guard", "medic",
        "caregiver", "scavenger",
    },
}

function H.FactionRole(archetypeID, index)
    local ordered = ROLE_ORDER[archetypeID] or {}
    return ordered[index]
        or PNC.FactionArchetypes.GetDefaultRole(
            archetypeID
        )
end

-- The community role is derived from the faction role instead of a second
-- positional table, so a settlement has one roster with one authority. `leader`
-- is never emitted: the community service normalizes it to a resident role and
-- tracks its leader through community.leaderNPCID. Faction roles that carry no
-- community meaning (trader, farmer, civilian, ...) are plain residents.
local COMMUNITY_ROLE_BY_FACTION_ROLE = {
    leader = "resident",
    guard = "guard",
    medic = "medic",
}

function H.CommunityRole(factionRole)
    return COMMUNITY_ROLE_BY_FACTION_ROLE[factionRole] or "resident"
end

function H.NPCArchetype(factionArchetypeID)
    if factionArchetypeID == "looter" then
        return "Scavenger"
    end
    return "General"
end

function H.FindActiveCommunity(factionID)
    local values = Communities.GetForFaction(factionID)
    for _, community in ipairs(values) do
        if community.status == "active" then
            return community
        end
    end
    return nil
end

function H.CreateCommunity(
    faction,
    site,
    spec,
    at
)
    local mode = spec.communityMode == "camped"
        and "camped" or "settled"
    local generatedName = PNC.FactionNameGenerator
        and PNC.FactionNameGenerator.GenerateCommunityName
        and PNC.FactionNameGenerator.GenerateCommunityName(
            faction.archetypeID,
            faction.name,
            tostring(faction.id) .. ":" .. tostring(site.id)
        )
        or faction.name .. (
            mode == "camped" and " Camp" or " Hideout"
        )
    local name = tostring(
        spec.communityName or generatedName
    )
    local ok
    local reason
    local community
    ok, reason, community = Communities.Create({
        factionID = faction.id,
        name = name,
        mode = mode,
        home = site.home,
        createdAt = at,
    })
    if not ok then return nil, reason end
    ok, reason = Communities.ReserveSite(
        community.id,
        site,
        at
    )
    if not ok then
        Communities.Destroy(
            community.id,
            "site_reservation_failed",
            at
        )
        return nil, reason
    end
    local created = Communities.Get(community.id)
    return created, nil, true
end

function H.ResolveCommunity(
    faction,
    site,
    spec,
    at
)
    local community = spec.communityID
        and Communities.Get(spec.communityID) or nil
    if community and community.factionID ~= faction.id then
        return nil, "community_faction_mismatch"
    end
    if not community and spec.useExisting ~= false then
        community = H.FindActiveCommunity(faction.id)
    end
    if community then
        if community.status ~= "active" then
            return nil, "community_not_active"
        end
        if not community.siteID then
            local ok
            local reason
            ok, reason = Communities.ReserveSite(
                community.id,
                site,
                at
            )
            if not ok then return nil, reason end
            community = Communities.Get(community.id)
        end
        return community, nil, false
    end
    return H.CreateCommunity(faction, site, spec, at)
end

function H.RollbackNPC(record, factionID, at)
    if Factions and Factions.RemoveNPC then
        Factions.RemoveNPC(
            factionID,
            record.id,
            "group_generation_rollback",
            at
        )
    end
    if PNC.API and PNC.API.Despawn then
        PNC.API.Despawn(record.id)
    end
end
