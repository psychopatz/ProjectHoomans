if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then
    return
end

local Extensions = PNC.SurvivorWorldExtensions
local I = Extensions.Internal

local GROUP_EXTENSION_FIELDS = {
    "action",
    "previousMission",
    "behaviorProfile",
    "recentAvoidedLocations",
    "recentHostileGroups",
    "activeEncounterId",
    "recentEncounterId",
    "knowledge",
    "visited",
    "simulation",
    "combatProfile",
    "combatProfileDirty",
    "combatProfileReason",
    "combatProfileSignature",
    "mobileAmbient",
    "ambientObjective",
    "diagnostics",
}

local LOCATION_EXTENSION_FIELDS = {
    "occupants",
    "visitHistory",
    "sourceSite",
    "populationHistory",
}

local function pick(source, fields)
    local output = {}
    for _, field in ipairs(fields) do
        if source[field] ~= nil then
            output[field] = I.Copy(source[field])
        end
    end
    return output
end

function Extensions.CaptureAbstract()
    local store = PNC.AbstractWorldStore
    local registry = store and store.Registry or {}
    local groups = {}
    local locations = {}

    for groupID, group in pairs(registry.groupsByID or {}) do
        groups[groupID] = pick(
            group,
            GROUP_EXTENSION_FIELDS
        )
    end
    for locationID, location in pairs(
        registry.locationsByID or {}
    ) do
        locations[locationID] = pick(
            location,
            LOCATION_EXTENSION_FIELDS
        )
    end

    return groups, locations, {
        encounters = I.Copy(registry.encounters or {}),
        encounterCooldowns = I.Copy(
            registry.encounterCooldowns or {}
        ),
        nextEncounterSerial = math.max(
            1,
            math.floor(
                tonumber(registry.nextEncounterSerial) or 1
            )
        ),
        uniqueNPCsByID = I.Copy(
            registry.uniqueNPCsByID or {}
        ),
    }
end

local function rawPopulation(core)
    core = type(core) == "table" and core or {}
    local output = {
        nextGenerationSerial =
            core.nextGenerationSerial,
        bootstrapCompleted =
            core.bootstrapCompleted == true,
        bootstrapCompletedAt =
            core.bootstrapCompletedAt,
        starterSettlementId =
            core.starterCommunityID,
        starterAttempts = core.starterAttempts,
        worldSeed = core.worldSeed,
        worldSeedString = core.worldSeedString,
        sectors = {},
        siteHistory = {},
        provenance = I.Copy(core.provenance or {}),
        committedGenerationIds = {},
        committedOrder = I.Copy(
            core.committedOrder or {}
        ),
    }

    for id, sector in pairs(core.sectors or {}) do
        output.sectors[id] = {
            id = id,
            discovered = sector.discovered == true,
            hadGroups = sector.hadGroups == true,
            hadSettlements =
                sector.hadCommunities == true,
            groupGenerationCooldownUntil =
                sector.groupGenerationCooldownUntil,
            settlementGenerationCooldownUntil =
                sector.communityGenerationCooldownUntil,
            lastReconciledAt =
                sector.lastReconciledAt,
        }
    end
    for id, history in pairs(core.siteHistory or {}) do
        output.siteHistory[id] = {
            formerSettlement =
                history.formerCommunity == true,
            destroyedAt = history.destroyedAt,
            regenerationBlockedUntil =
                history.regenerationBlockedUntil,
        }
    end
    for _, id in ipairs(output.committedOrder) do
        output.committedGenerationIds[id] = true
    end
    return output
end

local function rawLocation(core, extension)
    local output = I.Copy(extension or {})
    output.id = core.id
    output.type = core.kind
    output.x, output.y, output.z =
        core.x, core.y, core.z
    output.tags = I.Copy(core.tags or {})
    output.resourcePotential =
        I.Copy(core.resources or {})
    output.scavengedLevel = core.scavengedLevel
    output.danger = core.danger
    output.revision = core.revision
    return output
end

local function rawGroup(core, extension)
    local output = I.Copy(extension or {})
    output.id = core.id
    output.factionId = core.factionID
    output.homeCommunityId = core.homeCommunityID
    output.groupType = core.groupType
    output.memberIds =
        I.Copy(core.memberActorIDs or {})
    output.leaderId = core.leaderActorID
    output.mission = core.mission
    output.state = core.state
    output.location = I.Copy(core.location)
    output.targetLocation =
        I.Copy(core.targetLocation)
    output.journey = I.Copy(core.journey)
    output.stateStartedAt = core.stateStartedAt
    output.stateEndsAt = core.stateEndsAt
    output.missionStartedAt =
        core.missionStartedAt
    output.resources = I.Copy(core.resources or {})
    output.morale = core.morale
    output.revision = core.revision
    output.generation = I.Copy(core.generation)
    return output
end

function Extensions.RebuildAbstract(coreSnapshot)
    local extension = Extensions.Registry
    local abstract = extension.abstract or {}
    local raw = {
        schemaVersion = PNC.DirectorConfig.SCHEMA_VERSION,
        revision = tonumber(coreSnapshot.revision) or 0,
        groupsByID = {},
        locationsByID = {},
        encounters = I.Copy(abstract.encounters or {}),
        encounterCooldowns = I.Copy(
            abstract.encounterCooldowns or {}
        ),
        nextEncounterSerial = math.max(
            1,
            math.floor(
                tonumber(abstract.nextEncounterSerial) or 1
            )
        ),
        uniqueNPCsByID = I.Copy(
            abstract.uniqueNPCsByID or {}
        ),
        population = rawPopulation(
            coreSnapshot.population
        ),
    }

    for locationID, coreLocation in pairs(
        coreSnapshot.locations or {}
    ) do
        raw.locationsByID[locationID] = rawLocation(
            coreLocation,
            extension.locations
                and extension.locations[locationID]
        )
    end
    for groupID, coreGroup in pairs(
        coreSnapshot.groups or {}
    ) do
        raw.groupsByID[groupID] = rawGroup(
            coreGroup,
            extension.groups
                and extension.groups[groupID]
        )
    end

    return PNC.AbstractWorldTypes.NormalizeRegistry(raw)
end

return Extensions
