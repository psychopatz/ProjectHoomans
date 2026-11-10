if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then
    return
end

local Extensions = PNC.SurvivorWorldExtensions
local I = Extensions.Internal

local GENERIC_RELATION_FIELDS = {
    standing = true,
    trust = true,
    fear = true,
    grievance = true,
    state = true,
    previousState = true,
    atWar = true,
    allied = true,
    truceUntil = true,
    warStartedAt = true,
    warEndedAt = true,
    revision = true,
    targetFactionID = true,
    schemaVersion = true,
}

local function hasEntries(value)
    if type(value) ~= "table" then return false end
    for _ in pairs(value) do
        return true
    end
    return false
end

local function relationDetails(relation)
    local output = {}
    for key, value in pairs(
        type(relation) == "table" and relation or {}
    ) do
        if not GENERIC_RELATION_FIELDS[key] then
            output[key] = I.Copy(value)
        end
    end
    return output
end

local function factionExtension(faction)
    local details = {}
    for targetID, relation in pairs(
        type(faction.relations) == "table"
            and faction.relations or {}
    ) do
        local extra = relationDetails(relation)
        if hasEntries(extra) then details[targetID] = extra end
    end
    return {
        ownerPlayerKey = faction.ownerPlayerKey,
        playerMemberKeys = I.Copy(faction.playerMemberKeys or {}),
        policy = I.Copy(faction.policy),
        provision = I.Copy(faction.provision),
        emblem = I.Copy(faction.emblem),
        playerPacifications = I.Copy(
            faction.playerPacifications or {}
        ),
        excursion = I.Copy(faction.excursion),
        mobile = I.Copy(faction.mobile),
        needs = I.Copy(faction.needs),
        relationDetails = details,
    }
end

function Extensions.CaptureFactions()
    local output = {}
    local registry = PNC.Factions and PNC.Factions.Registry
    for factionID, faction in pairs(
        registry and registry.byID or {}
    ) do
        output[factionID] = factionExtension(faction)
    end
    return output
end

local function mergeRelation(coreRelation, detail)
    local output = I.Copy(detail or {})
    for key, value in pairs(coreRelation or {}) do
        if key ~= "targetFactionID" then
            output[key] = I.Copy(value)
        end
    end
    return output
end

local function rawFaction(coreFaction, extension)
    extension = type(extension) == "table" and extension or {}
    local output = I.Copy(extension)
    output.relationDetails = nil
    output.id = coreFaction.id
    output.name = coreFaction.name
    output.archetypeID = coreFaction.archetypeID
    output.status = coreFaction.status
    output.createdAt = coreFaction.createdAt
    output.archivedAt = coreFaction.archivedAt
    output.leaderNPCID = coreFaction.leaderActorID
    output.memberIDs = I.SetFromArray(
        coreFaction.memberActorIDs
    )
    output.tags = I.Copy(coreFaction.tags or {})
    output.revision = coreFaction.revision
    output.relations = {}

    for targetID, relation in pairs(
        coreFaction.relations or {}
    ) do
        output.relations[targetID] = mergeRelation(
            relation,
            extension.relationDetails
                and extension.relationDetails[targetID]
        )
    end
    return output
end

function Extensions.RebuildFactions(coreSnapshot)
    local raw = {
        schemaVersion =
            PNC.FactionConstants.REGISTRY_SCHEMA_VERSION,
        revision = tonumber(coreSnapshot.revision) or 0,
        byID = {},
    }
    local extensions = Extensions.Registry.factions or {}
    for factionID, coreFaction in pairs(
        coreSnapshot.factions or {}
    ) do
        if Extensions.IsCoreFactionProjectable(coreFaction) then
            raw.byID[factionID] = rawFaction(
                coreFaction,
                extensions[factionID]
            )
        end
    end
    return PNC.FactionTypes.NormalizeFactionRegistry(raw)
end

return Extensions
