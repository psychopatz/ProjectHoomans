if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.DebugCompanionRecruit = PNC.DebugCompanionRecruit or {}
PNC.Recruitment = PNC.Recruitment or PNC.DebugCompanionRecruit
PNC.DebugCompanionRecruitInternal =
    PNC.DebugCompanionRecruitInternal or {}

local Recruit = PNC.DebugCompanionRecruit
local H = PNC.DebugCompanionRecruitInternal
local Const = PNC.Const
local Core = PNC.Core
local Factions = PNC.Factions
local Registry = PNC.Registry
local Graph = PNC.RelationshipGraph

function H.SynchronizeRecordMembership(record, faction, community)
    if not record or not faction or not community then return false end
    record.affiliation = record.affiliation or {}
    local changed = tostring(record.affiliation.factionID or "")
            ~= tostring(faction.id or "")
        or tostring(record.affiliation.communityID or "")
            ~= tostring(community.id or "")
        or tostring(record.factionId or "") ~= tostring(faction.id or "")
        or tostring(record.communityId or "") ~= tostring(community.id or "")
    record.affiliation.factionID = faction.id
    record.affiliation.factionId = faction.id
    record.affiliation.communityID = community.id
    record.affiliation.communityId = community.id
    record.factionId = faction.id
    record.communityId = community.id
    if changed and Registry and Registry.MarkDirty then
        Registry.MarkDirty(record, "canonical_membership_sync")
    end
    return changed
end

-- Recruitment crosses three authoritative stores: the NPC record, faction
-- membership, and community membership. Commit all three at the successful
-- boundary so a restart cannot expose a half-recruited NPC or recreate the
-- first-colony naming prompt from stale ModData.
function H.SaveRecruitment()
    if Registry and Registry.Save then Registry.Save() end
    if Factions and Factions.Save then Factions.Save() end
    if PNC.Communities and PNC.Communities.Save then
        PNC.Communities.Save()
    end
    if GlobalModData and GlobalModData.save then GlobalModData.save() end
end


-- Shared authoritative assignment boundary used by both normal/debug
-- recruitment and character-start companions. Eligibility belongs to the
-- caller; this function owns the cross-store faction/community transaction.

return Recruit

