if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then
    return
end

local Extensions = PNC.SurvivorWorldExtensions
local I = Extensions.Internal

local function communityExtension(community)
    local supplies = type(community.supplies) == "table"
        and community.supplies or {}
    return {
        renamePending = community.renamePending == true,
        archiveReason = community.archiveReason,
        destroyReason = community.destroyReason,
        capacity = I.Copy(community.capacity),
        suppliesExtra = {
            tools = tonumber(supplies.tools) or 0,
        },
    }
end

function Extensions.CaptureCommunities()
    local output = {}
    local registry = PNC.Communities
        and PNC.Communities.Registry
    for communityID, community in pairs(
        registry and registry.byID or {}
    ) do
        output[communityID] =
            communityExtension(community)
    end
    return output, I.Copy(
        registry and registry.sitesByID or {}
    )
end

local function rawCommunity(coreCommunity, extension)
    extension = type(extension) == "table"
        and extension or {}
    local resources = type(coreCommunity.resources) == "table"
        and coreCommunity.resources or {}
    local extra = type(extension.suppliesExtra) == "table"
        and extension.suppliesExtra or {}

    return {
        id = coreCommunity.id,
        factionID = coreCommunity.factionID,
        name = coreCommunity.name,
        renamePending = extension.renamePending == true,
        mode = coreCommunity.mode,
        status = coreCommunity.status,
        createdAt = coreCommunity.createdAt,
        archivedAt = coreCommunity.archivedAt,
        destroyedAt = coreCommunity.destroyedAt,
        archiveReason = extension.archiveReason,
        destroyReason = extension.destroyReason,
        home = I.Copy(coreCommunity.home),
        siteID = coreCommunity.siteID,
        leaderNPCID = coreCommunity.leaderActorID,
        memberIDs = I.SetFromArray(
            coreCommunity.memberActorIDs
        ),
        capacity = I.Copy(extension.capacity),
        security = coreCommunity.security,
        morale = coreCommunity.morale,
        supplies = {
            food = tonumber(resources.food) or 0,
            medicine = tonumber(resources.medical) or 0,
            ammunition = tonumber(resources.ammo) or 0,
            tools = tonumber(extra.tools) or 0,
            materials = tonumber(resources.materials) or 0,
        },
        revision = coreCommunity.revision,
    }
end

function Extensions.RebuildCommunities(coreSnapshot)
    local raw = {
        schemaVersion =
            PNC.CommunityConstants.REGISTRY_SCHEMA_VERSION,
        revision = tonumber(coreSnapshot.revision) or 0,
        byID = {},
        sitesByID = I.Copy(
            Extensions.Registry.sitesByID or {}
        ),
    }
    local extensions = Extensions.Registry.communities or {}
    for communityID, coreCommunity in pairs(
        coreSnapshot.communities or {}
    ) do
        raw.byID[communityID] = rawCommunity(
            coreCommunity,
            extensions[communityID]
        )
    end
    return PNC.CommunityTypes.NormalizeRegistry(raw)
end

return Extensions
