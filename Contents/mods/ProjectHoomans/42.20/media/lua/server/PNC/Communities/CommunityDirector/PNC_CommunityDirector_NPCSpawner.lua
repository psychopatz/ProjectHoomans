if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local H = PNC.CommunityDirector.Internal
local Communities = PNC.Communities
local Resolver = PNC.CommunitySiteResolver
local Factions = PNC.Factions

local function generationFailure(
    created,
    factionID,
    community,
    createdCommunity,
    at,
    reason
)
    for _, prior in ipairs(created) do
        H.RollbackNPC(prior, factionID, at)
    end
    if createdCommunity then
        Communities.Destroy(
            community.id,
            "group_generation_failed",
            at
        )
    end
    return nil, nil, nil, nil, reason
end

function H.SpawnCommunityMembers(
    faction,
    community,
    site,
    spec,
    at,
    presenceMode,
    siteLoaded,
    createdCommunity
)
    local count = H.NormalizedGroupSize(spec.groupSize)
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
        local record = PNC.API.Spawn({
            faction = "neutral",
            archetypeID = H.NPCArchetype(
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
            factionID = faction.id,
            membershipStatus = "member",
            factionRole = H.FactionRole(
                faction.archetypeID,
                index
            ),
            factionJoinedAt = at,
            debug = spec.debug == true,
            generation = spec.generation,
        })
        if not record then
            return generationFailure(
                created,
                faction.id,
                community,
                createdCommunity,
                at,
                "npc_spawn_failed"
            )
        end
        local added
        local reason
        added, reason = Communities.AddNPC(
            community.id,
            record.id,
            {
                communityRole = H.CommunityRole(index),
                joinedAt = at,
                strictCapacity = spec.strictCapacity == true,
            }
        )
        if not added then
            H.RollbackNPC(record, faction.id, at)
            return generationFailure(
                created,
                faction.id,
                community,
                createdCommunity,
                at,
                reason
            )
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
    return created, liveCount, abstractCount, count, nil
end
