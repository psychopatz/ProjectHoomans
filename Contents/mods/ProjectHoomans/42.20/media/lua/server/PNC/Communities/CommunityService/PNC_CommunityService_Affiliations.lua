if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Communities = PNC.Communities or {}
PNC.Communities.Internal = PNC.Communities.Internal or {}

local Communities = PNC.Communities
local Internal = Communities.Internal
local Core = PNC.Core
local Constants = PNC.CommunityConstants
local Types = PNC.CommunityTypes
local CommunityMath = PNC.CommunityMath
local FactionTypes = PNC.FactionTypes
local authority = Internal.authority
local copy = Internal.copy
local worldAge = Internal.worldAge
local registryRecord = Internal.registryRecord
local npcRecord = Internal.npcRecord
local factionRecord = Internal.factionRecord
local touchCommunity = Internal.touchCommunity
local touchRegistry = Internal.touchRegistry
local commitAffiliation = Internal.commitAffiliation
local affiliationWithCommunity = Internal.affiliationWithCommunity
local clearAffiliationCommunity = Internal.clearAffiliationCommunity
local population = Internal.population
local publicCommunity = Internal.publicCommunity

function Communities.GetNPCAffiliation(npcID)
    local record, reason = npcRecord(npcID, true)
    if not record then return nil, reason end
    local affiliation =
        FactionTypes.NormalizeAffiliation(record.affiliation)
    return {
        communityID = affiliation.communityID,
        communityRole = affiliation.communityRole,
        communityJoinedAt = affiliation.communityJoinedAt,
        affiliationRevision = affiliation.revision,
    }
end

function Communities.GetNPCCommunity(npcID)
    local affiliation, reason =
        Communities.GetNPCAffiliation(npcID)
    if not affiliation then return nil, reason end
    if not affiliation.communityID then
        return nil, "no_community"
    end
    return Communities.Get(affiliation.communityID)
end

return Communities
