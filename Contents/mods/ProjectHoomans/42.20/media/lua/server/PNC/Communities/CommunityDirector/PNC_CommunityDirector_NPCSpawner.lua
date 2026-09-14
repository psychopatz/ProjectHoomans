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
    reason,
    uniqueClaim
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
    if uniqueClaim and PNC.UniqueNPCRegistry
        and PNC.UniqueNPCRegistry.RollbackSpawn
    then
        PNC.UniqueNPCRegistry.RollbackSpawn(uniqueClaim, reason)
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
    local UniqueRegistry = PNC.UniqueNPCRegistry
    local uniqueClaim
    local uniqueDefinition
    local defaultArchetypeID = H.NPCArchetype(faction.archetypeID)
    if spec.uniqueNPC ~= false and UniqueRegistry
        and UniqueRegistry.PrepareForGeneration
    then
        uniqueClaim, uniqueDefinition = UniqueRegistry.PrepareForGeneration({
            generationId = spec.generation and spec.generation.generationId,
            seed = spec.generation and spec.generation.seed or at,
            worldAgeHours = at,
            archetypeID = defaultArchetypeID,
            generation = spec.generation,
            poolChance = spec.uniquePoolChance,
            force = spec.forceUniqueNPC == true,
        })
    end
    local index
    for index = 1, count do
        local point = points[index]
        local spawnDefinition = {
            tacticalClass = "neutral",
            archetypeID = defaultArchetypeID,
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
        }
        if index == 1 and uniqueDefinition then
            local resolved = PNC.Core.DeepCopy(uniqueDefinition)
            resolved.tacticalClass = spawnDefinition.tacticalClass
            resolved.x = spawnDefinition.x
            resolved.y = spawnDefinition.y
            resolved.z = spawnDefinition.z
            resolved.anchorX = spawnDefinition.anchorX
            resolved.anchorY = spawnDefinition.anchorY
            resolved.anchorZ = spawnDefinition.anchorZ
            resolved.orderSpec = spawnDefinition.orderSpec
            resolved.forceLive = spawnDefinition.forceLive
            resolved.equipmentSpawnMode = spawnDefinition.equipmentSpawnMode
            resolved.factionID = spawnDefinition.factionID
            resolved.membershipStatus = spawnDefinition.membershipStatus
            resolved.factionRole = spawnDefinition.factionRole
            resolved.factionJoinedAt = spawnDefinition.factionJoinedAt
            resolved.debug = spawnDefinition.debug
            resolved.generation = spawnDefinition.generation
            spawnDefinition = resolved
        end
        local record = PNC.API.Spawn(spawnDefinition)
        if not record then
            return generationFailure(
                created,
                faction.id,
                community,
                createdCommunity,
                at,
                "npc_spawn_failed",
                uniqueClaim
            )
        end
        if uniqueClaim and index == 1 and UniqueRegistry
            and UniqueRegistry.CommitSpawn
        then
            local committed, commitReason = UniqueRegistry.CommitSpawn(
                uniqueClaim,
                record,
                at
            )
            if not committed then
                H.RollbackNPC(record, faction.id, at)
                return generationFailure(
                    created,
                    faction.id,
                    community,
                    createdCommunity,
                    at,
                    commitReason or "unique_commit_failed",
                    uniqueClaim
                )
            end
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
                reason,
                uniqueClaim
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
