-- Builds the identity, trait, and ownership projection of a detailed snapshot.
-- The serializer owns the final payload assembly and network contract.

if not PNC or not PNC.Network
    or not PNC.Network.Internal
    or not PNC.Network.Internal.DetailedPayload
then return end

local Network = PNC.Network
local H = Network.Internal.DetailedPayload
if not H then return Network end

local Core = H.Core
local Parts = H.Parts
local buildOrganizationalFactionSummary = H.buildOrganizationalFactionSummary

function H.BuildIdentityProjection(record, state)
    local identity = state.identity
    local ownership = state.ownership
    return {
        interestDetailed = true,
        id = record.id,
        displayName = identity.displayName,
        identitySeed = identity.identitySeed,
        portrait = PNC.Identity
            and PNC.Identity.BuildPortraitSummary
            and PNC.Identity.BuildPortraitSummary(record)
            or nil,
        archetypeID = identity.archetypeID,
        archetypeLabel = identity.archetypeLabel,
        vanillaTraits = PNC.PlayerNeedsModel
            and PNC.PlayerNeedsModel.NormalizeTraits(record.vanillaTraits)
            or {},
        vanillaTraitsAuthored = record.vanillaTraitsAuthored == true,
        vanillaTraitsGenerationVersion = math.max(0, math.floor(
            tonumber(record.vanillaTraitsGenerationVersion) or 0
        )),
        dynamicTraits = PNC.ConditionStats
            and PNC.ConditionStats.NormalizeTraits(record.dynamicTraits) or {},
        dynamicTraitsAuthored = record.dynamicTraitsAuthored == true,
        npcTraits = PNC.NPCTraits
            and PNC.NPCTraits.NormalizeSet(record.npcTraits) or {},
        npcTraitFingerprint = tostring(record.npcTraitFingerprint or ""),
        conditionStats = PNC.ConditionStats
            and PNC.ConditionStats.NormalizeState(record.conditionStats, 0)
            or {},
        morale = record.social and record.social.morale or 0,
        recruited = ownership.recruited,
        relationshipCategory = record.generation
                and record.generation.relationshipKind == "lover"
            and "Lover" or nil,
        startingRelationship = record.generation
            and record.generation.source == "starting_companion_trait"
            and {
                kind = record.generation.relationshipKind,
                since = record.generation.relationshipSince,
            } or nil,
        persist = record.persist ~= false,
        tacticalClass = record.tacticalClass,
        factionID = ownership.factionID,
        colonyOwned = ownership.colonyOwned,
        -- Tactical class remains separate from factionID. Replicate explicit
        -- hostility flags so MP clients never infer player hostility from a
        -- coarse class value alone.
        hostility = Core.DeepCopy(record.hostility or {}),
        organizationalFaction = buildOrganizationalFactionSummary(record),
        worldDiscovery = Parts.BuildWorldDiscoverySummary(record),
        visualProfile = record.visualProfile,
        isFemale = identity.isFemale,
        identity = {
            isFemale = identity.isFemale,
            survivor = identity.survivor,
        },
        x = record.x,
        y = record.y,
        z = record.z,
        orderKind = record.orderSpec and record.orderSpec.kind or nil,
        attackType = record.attackType or "auto",
        ownerUsername = ownership.ownerUsername,
        ownerOnlineID = ownership.ownerOnlineID,
    }
end

return Network
