--[[
    PNC Network Snapshots - Presentation
    Serializes travel, map, identity, and faction presentation state.
]]

local Network = PNC.Network
local Parts = Network.Internal.SnapshotParts
local Core = PNC.Core
local IdentityVerifier = PNC.Identity and PNC.Identity.Verifier

function Parts.BuildIdentityOwnershipSummary(record)
    local affiliation = type(record) == "table"
        and type(record.affiliation) == "table"
        and record.affiliation or {}
    local factionID = affiliation.factionID
    local recruited = record and record.recruited == true or false
    local ownerUsername = record and record.ownerUsername or nil
    local ownerOnlineID = record and record.ownerOnlineID or nil
    if IdentityVerifier and IdentityVerifier.BuildOwnershipSummary then
        local ownership = IdentityVerifier.BuildOwnershipSummary(record)
        factionID = ownership.factionID
        recruited = ownership.recruited
        ownerUsername = ownership.ownerUsername
        ownerOnlineID = ownership.ownerOnlineID
        return {
            factionID = factionID,
            recruited = recruited,
            colonyOwned = ownership.colonyOwned,
            ownerUsername = ownerUsername,
            ownerOnlineID = ownerOnlineID,
        }
    end
    return {
        factionID = factionID,
        recruited = recruited,
        colonyOwned = IdentityVerifier
            and IdentityVerifier.IsColonyOwnedNPC(record)
            or recruited,
        ownerUsername = ownerUsername,
        ownerOnlineID = ownerOnlineID,
    }
end

function Parts.BuildTravelSummary(record, includeRoute)
    return PNC.Travel
        and PNC.Travel.Model
        and PNC.Travel.Model.BuildSummary
        and PNC.Travel.Model.BuildSummary(record and record.travel, includeRoute)
        or nil
end

function Parts.BuildMapPresentationSummary(record)
    return PNC.MapPresentation
        and PNC.MapPresentation.BuildSummary
        and PNC.MapPresentation.BuildSummary(
            record and record.mapPresentation
        )
        or nil
end

function Parts.BuildIdentitySummary(record)
    local summary = PNC.Identity and PNC.Identity.GetCharacterSummary and PNC.Identity.GetCharacterSummary(record) or {}
    return {
        displayName = summary.displayName or record.name,
        archetypeID = summary.archetypeID or record.archetypeID,
        archetypeLabel = summary.archetypeLabel or record.archetypeLabel,
        identitySeed = summary.identitySeed or record.identitySeed,
        isFemale = summary.isFemale == true or record.isFemale == true,
        survivor = Core.DeepCopy(summary.survivor or {}),
    }
end

function Parts.BuildOrganizationalFactionSummary(record)
    local affiliation = type(record) == "table"
        and record.affiliation or nil
    local factionID = IdentityVerifier
        and IdentityVerifier.GetFactionID(record)
        or type(affiliation) == "table"
            and affiliation.factionID or nil
    if not factionID then return nil end
    local faction
    if PNC.Factions and PNC.Factions.GetPresentation then
        faction = PNC.Factions.GetPresentation(factionID)
    elseif PNC.Factions and PNC.Factions.Get then
        faction = PNC.Factions.Get(factionID)
    end
    return {
        id = tostring(factionID),
        factionID = tostring(factionID),
        name = faction and tostring(faction.name)
            or tostring(factionID),
        archetypeID = faction
            and faction.archetypeID or nil,
        emblem = faction
            and Core.DeepCopy(faction.emblem) or nil,
        membershipStatus =
            affiliation.membershipStatus,
        role = affiliation.role,
        rank = affiliation.rank,
    }
end

function Parts.BuildWorldDiscoverySummary(record)
    local affiliation = type(record) == "table"
        and type(record.affiliation) == "table"
        and record.affiliation or {}
    local generation = type(record) == "table"
        and type(record.generation) == "table"
        and record.generation or {}
    local source = tostring(generation.source or "")
    local populationGenerated = string.find(
        source, "WORLD_POPULATION_", 1, true
    ) == 1
    if not populationGenerated and affiliation.factionID
        and PNC.Factions and PNC.Factions.Get
    then
        local faction = PNC.Factions.Get(affiliation.factionID)
        populationGenerated = faction and faction.tags
            and faction.tags.populationGenerated == true or false
    end
    if not populationGenerated then return nil end
    return {
        populationGenerated = true,
        communityID = affiliation.communityID,
        factionID = affiliation.factionID,
    }
end

return Parts
