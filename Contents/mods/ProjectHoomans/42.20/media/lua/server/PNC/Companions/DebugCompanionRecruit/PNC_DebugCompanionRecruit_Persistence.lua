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
    record.affiliation.factionID = faction.id
    record.affiliation.communityID = community.id
    if changed and Registry and Registry.MarkDirty then
        Registry.MarkDirty(record, "canonical_membership_sync")
    end
    return changed
end

function H.RollbackMembership(record, previous, at)
    local communities = PNC.Communities
    local current = record.affiliation or {}
    previous = previous or {}
    if current.communityID and current.communityID ~= previous.communityID then
        local ok, reason = communities.RemoveNPC(current.communityID, record.id)
        if not ok then return false, reason end
    end
    if current.factionID ~= previous.factionID then
        local ok, reason
        if previous.factionID then
            local options = Core.DeepCopy(previous)
            options.deferBehavior = true
            ok, reason = Factions.TransferNPC(record.id, previous.factionID, options)
        else
            ok, reason = Factions.RemoveNPC(current.factionID, record.id, "unknown", at)
        end
        if not ok and reason ~= "unchanged" then return false, reason end
    end
    if previous.communityID and record.affiliation.communityID ~= previous.communityID then
        local ok, reason = communities.AddNPC(previous.communityID, record.id, previous)
        if not ok and reason ~= "unchanged" then return false, reason end
    end
    record.affiliation = previous
    return true
end

function H.SaveRecruitment()
    if PNC.PersistenceCoordinator and PNC.PersistenceCoordinator.Commit then
        PNC.PersistenceCoordinator.Commit("recruitment")
    end
end

return Recruit
