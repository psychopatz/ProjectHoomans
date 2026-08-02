-- Reusable server-authoritative faction/community group generator.
--
-- This is deliberately event-driven. It creates persistent NPC records in
-- abstract state first, then optionally asks the existing presence system to
-- materialize them when the selected site is loaded.

if isClient and isClient() and (not isServer or not isServer()) then
    return
end

PNC = PNC or {}
PNC.CommunityDirector = PNC.CommunityDirector or {}

local Director = PNC.CommunityDirector
local Constants = PNC.CommunityConstants
local Communities = PNC.Communities
local Resolver = PNC.CommunitySiteResolver
local Factions = PNC.Factions
local Core = PNC.Core

local function worldAge(value)
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

local function normalizedGroupSize(value)
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

local function normalizedPresenceMode(value)
    return Constants.VALID_GROUP_PRESENCE_MODES[value]
        and value or "auto"
end

local ROLE_ORDER = {
    settler = {
        "leader", "guard", "medic", "farmer",
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
        "leader", "medic", "guard", "caregiver",
        "scavenger",
    },
}

local function factionRole(archetypeID, index)
    local ordered = ROLE_ORDER[archetypeID] or {}
    return ordered[index]
        or PNC.FactionArchetypes.GetDefaultRole(
            archetypeID
        )
end

local function communityRole(index)
    if index == 1 then return "resident" end
    if index == 2 then return "guard" end
    if index == 3 then return "medic" end
    return "resident"
end

local function npcArchetype(factionArchetypeID)
    if factionArchetypeID == "looter" then
        return "Scavenger"
    end
    return "General"
end

local function findActiveCommunity(factionID)
    local values = Communities.GetForFaction(factionID)
    for _, community in ipairs(values) do
        if community.status == "active" then
            return community
        end
    end
    return nil
end

local function createCommunity(
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

local function resolveCommunity(
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
        community = findActiveCommunity(faction.id)
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
    return createCommunity(faction, site, spec, at)
end

local function rollbackNPC(record, factionID, at)
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

function Director.GenerateForFaction(factionID, spec)
    if not Core.IsAuthority() then
        return false, "not_authority"
    end
    spec = type(spec) == "table" and spec or {}
    local faction = Factions.Get(factionID)
    if not faction then return false, "faction_not_found" end
    if faction.status ~= "active" then
        return false, "faction_not_active"
    end
    -- A mobile group only carries a transient primitive staging site. It is
    -- not a community and must never reserve a building or acquire a home.
    if Factions.IsMobileGroup
        and Factions.IsMobileGroup(faction)
    then
        return false, "mobile_faction_cannot_create_community"
    end
    local at = worldAge(spec.worldAgeHours)
    local preferredCommunity = spec.communityID
        and Communities.Get(spec.communityID) or nil
    if not preferredCommunity
        and spec.useExisting ~= false
    then
        preferredCommunity =
            findActiveCommunity(faction.id)
    end
    local primitiveSite = type(spec.siteSpec) == "table"
        and Core.DeepCopy(spec.siteSpec) or nil
    if primitiveSite
        and not PNC.CommunityTypes.IsValidSiteID(
            primitiveSite.id
        )
    then
        primitiveSite.id =
            Communities.BuildSiteID(primitiveSite)
    end
    local site = preferredCommunity
        and preferredCommunity.site
        or primitiveSite
        and PNC.CommunityTypes.NormalizeSite(
            primitiveSite,
            primitiveSite.id
        ) or nil
    local siteReason = preferredCommunity and site
        and "existing_community_site"
        or site and "primitive_site" or nil
    if not site then
        if spec.siteSelection == "random_house" then
            site, siteReason = Resolver.FindRandomHouse({
                z = spec.z,
                createdAt = at,
                randomIndex = spec.randomHouseIndex,
            })
        else
            site, siteReason = Resolver.FindAvailableNear(
                spec.x,
                spec.y,
                spec.z,
                {
                radius = spec.radius,
                createdAt = at,
                searchRadius = spec.searchRadius,
                }
            )
        end
    end
    if not site then return false, siteReason end
    local community
    local reason
    local createdCommunity
    community, reason, createdCommunity = resolveCommunity(
        faction,
        site,
        spec,
        at
    )
    if not community then return false, reason end
    if faction.archetypeID == "looter"
        and community.mode == "settled"
        and Factions.MarkTerritorialTollFaction
    then
        Factions.MarkTerritorialTollFaction(
            faction.id,
            "settled_looter_community_generated"
        )
        faction = Factions.Get(faction.id) or faction
    end
    site = community.site or site
    local count = normalizedGroupSize(spec.groupSize)
    local presenceMode =
        normalizedPresenceMode(spec.presenceMode)
    local siteLoaded = Resolver.IsSiteLoaded(site)
    local requestLive = presenceMode == "live"
        or presenceMode == "auto"
            and siteLoaded
            and spec.allowLive ~= false
    local points = Resolver.FindSpawnPoints(site, count)
    local created = {}
    local liveCount = 0
    local abstractCount = 0
    local index
    for index = 1, count do
        local point = points[index]
        local role = factionRole(
            faction.archetypeID,
            index
        )
        local record = PNC.API.Spawn({
            faction = "neutral",
            archetypeID = npcArchetype(
                faction.archetypeID
            ),
            x = point.x,
            y = point.y,
            z = point.z,
            anchorX = site.home.x,
            anchorY = site.home.y,
            anchorZ = site.home.z,
            orderSpec = {
                kind = PNC.Const.ORDER_ROAM,
                roamMode = PNC.Const.ROAM_MODE_AREA,
                x = site.home.x,
                y = site.home.y,
                z = site.home.z,
                radius = site.home.radius,
            },
            forceLive = requestLive and siteLoaded,
            equipmentSpawnMode =
                faction.archetypeID == "looter"
                    and "both" or nil,
            organizationalFactionID = faction.id,
            membershipStatus = "member",
            factionRole = role,
            factionJoinedAt = at,
            debug = spec.debug == true,
        })
        if not record then
            for _, prior in ipairs(created) do
                rollbackNPC(prior, faction.id, at)
            end
            if createdCommunity then
                Communities.Destroy(
                    community.id,
                    "group_generation_failed",
                    at
                )
            end
            return false, "npc_spawn_failed"
        end
        local added
        added, reason = Communities.AddNPC(
            community.id,
            record.id,
            {
                communityRole = communityRole(index),
                joinedAt = at,
                strictCapacity = spec.strictCapacity == true,
            }
        )
        if not added then
            rollbackNPC(record, faction.id, at)
            for _, prior in ipairs(created) do
                rollbackNPC(prior, faction.id, at)
            end
            if createdCommunity then
                Communities.Destroy(
                    community.id,
                    "group_generation_failed",
                    at
                )
            end
            return false, reason
        end
        if presenceMode == "abstract" then
            record.runtime.forceAbstract = true
            if record.presenceState == PNC.Const.PRESENCE_LIVE then
                PNC.Presence.Abstract(
                    record,
                    "director_force_abstract"
                )
            end
        end
        if record.presenceState == PNC.Const.PRESENCE_LIVE then
            liveCount = liveCount + 1
        else
            abstractCount = abstractCount + 1
        end
        created[#created + 1] = record
    end
    if created[1] then
        Factions.SetLeader(
            faction.id,
            created[1].id,
            at
        )
        Communities.SetLeader(
            community.id,
            created[1].id,
            at
        )
    end
    local ids = {}
    for _, record in ipairs(created) do
        ids[#ids + 1] = record.id
    end
    return true, "group_generated", {
        factionID = faction.id,
        communityID = community.id,
        siteID = site.id,
        siteKind = site.kind,
        siteLoaded = siteLoaded,
        siteSelectionReason = siteReason,
        presenceMode = presenceMode,
        requestedCount = count,
        createdCount = #ids,
        liveCount = liveCount,
        abstractCount = abstractCount,
        npcIDs = ids,
    }
end

return Director
