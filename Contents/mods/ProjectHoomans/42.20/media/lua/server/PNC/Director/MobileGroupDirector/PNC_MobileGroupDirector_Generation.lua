if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.MobileGroupDirector = PNC.MobileGroupDirector or {}
PNC.MobileGroupDirectorInternal = PNC.MobileGroupDirectorInternal or {}

local Director = PNC.MobileGroupDirector
local H = PNC.MobileGroupDirectorInternal
local Constants = PNC.FactionConstants
local CommunityConstants = PNC.CommunityConstants
local Factions = PNC.Factions
local Resolver = PNC.CommunitySiteResolver
local Core = PNC.Core
local Const = PNC.Const

function Director.GenerateForFaction(factionID, spec)
    if not H.Authority() then return false, "not_authority" end
    spec = type(spec) == "table" and spec or {}
    local faction = Factions.Get(factionID)
    local UniqueRegistry = PNC.UniqueNPCRegistry
    if not faction then return false, "faction_not_found" end
    if faction.status ~= "active" then
        return false, "faction_not_active"
    end
    if faction.archetypeID ~= "looter"
        and faction.archetypeID ~= "trader"
        and faction.archetypeID ~= "refugee"
    then
        return false, "mobile_archetype_not_allowed"
    end
    local at = H.WorldAge(spec.worldAgeHours)
    local mode = H.PathMode(
        spec.mobilePathMode,
        faction.mobile and faction.mobile.pathMode
    )
    local controlMode = spec.mobileControlMode
        or spec.mobilePathMode and (
            mode == Constants.MOBILE_PATH_PLAYER
                and Constants.MOBILE_CONTROL_STRATEGIC
                or Constants.MOBILE_CONTROL_AMBIENT
        )
        or faction.mobile and faction.mobile.controlMode
        or mode == Constants.MOBILE_PATH_PLAYER
            and Constants.MOBILE_CONTROL_STRATEGIC
        or Constants.MOBILE_CONTROL_AMBIENT
    local site, siteReason = H.ResolveSite(
        faction,
        spec,
        at,
        false
    )
    if not site then return false, siteReason end
    local count = H.GroupSize(spec.groupSize)
    local requestedPresence = H.PresenceMode(spec.presenceMode)
    local siteLoaded = Resolver.IsSiteLoaded(site)
    local requestLive = requestedPresence == "live"
        or requestedPresence == "auto" and siteLoaded
            and spec.allowLive ~= false
    local points = Resolver.FindSpawnPoints(site, count)
    local created = {}
    local liveCount = 0
    local abstractCount = 0
    local uniqueClaim
    local uniqueDefinition
    local defaultArchetypeID = H.NPCArchetype(faction)
    local function rollbackCreated(reason)
        local prior
        for _, priorRecord in ipairs(created) do
            prior = priorRecord
            if PNC.Factions and PNC.Factions.RemoveNPC then
                PNC.Factions.RemoveNPC(
                    faction.id,
                    prior.id,
                    "group_generation_rollback",
                    at
                )
            end
            if PNC.API and PNC.API.Despawn then
                PNC.API.Despawn(prior.id)
            end
        end
        if uniqueClaim and UniqueRegistry
            and UniqueRegistry.RollbackSpawn
        then
            UniqueRegistry.RollbackSpawn(uniqueClaim, reason)
        end
    end
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
            orderSpec = H.MobileOrder(faction, {
                pathMode = mode,
            }, site),
            forceLive = requestLive and siteLoaded,
            equipmentSpawnMode = faction.archetypeID == "looter"
                and "both" or nil,
            factionID = faction.id,
            membershipStatus = "member",
            factionRole = H.FactionRole(faction, index),
            factionJoinedAt = at,
            debug = spec.debug == true,
            generation = spec.generation,
        }
        if index == 1 and uniqueDefinition then
            local resolved = Core.DeepCopy(uniqueDefinition)
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
            rollbackCreated("npc_spawn_failed")
            return false, "npc_spawn_failed"
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
                created[#created + 1] = record
                rollbackCreated(commitReason or "unique_commit_failed")
                return false, "unique_commit_failed"
            end
        end
        if requestedPresence == "abstract" then
            record.runtime.forceAbstract = true
            if record.presenceState == Const.PRESENCE_LIVE
                and PNC.Presence and PNC.Presence.Abstract
            then
                PNC.Presence.Abstract(
                    record,
                    "mobile_director_force_abstract"
                )
            end
        end
        if record.presenceState == Const.PRESENCE_LIVE then
            liveCount = liveCount + 1
        else
            abstractCount = abstractCount + 1
        end
        created[#created + 1] = record
    end
    local previous = faction.mobile
    local state = H.BuildMobileState(
        site,
        mode,
        at,
        previous,
        previous ~= nil,
        controlMode
    )
    local ok, reason, mobile = Factions.SetMobileGroup(
        faction.id,
        state,
        "mobile_group_generated"
    )
    if not ok then
        rollbackCreated(reason or "mobile_group_commit_failed")
        return false, reason
    end
    if not faction.leaderNPCID and created[1] then
        Factions.SetLeader(faction.id, created[1].id, at)
    end
    if PNC.AbstractGroups and PNC.AbstractGroups.ImportMobileFaction then
        PNC.AbstractGroups.ImportMobileFaction(Factions.Get(faction.id))
    end
    local ids = {}
    for _, record in ipairs(created) do
        ids[#ids + 1] = record.id
    end
    return true, "mobile_group_generated", {
        factionID = faction.id,
        mobile = mobile,
        siteID = site.id,
        siteKind = site.kind,
        siteLoaded = siteLoaded,
        siteSelectionReason = siteReason,
        presenceMode = requestedPresence,
        pathMode = mode,
        requestedCount = count,
        createdCount = #ids,
        liveCount = liveCount,
        abstractCount = abstractCount,
        npcIDs = ids,
    }
end
