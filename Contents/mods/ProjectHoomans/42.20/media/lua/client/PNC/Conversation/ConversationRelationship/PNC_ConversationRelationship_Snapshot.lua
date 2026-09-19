-- Project complete relationship summaries into bounded client snapshots.
local Previews = require "PNC/Conversation/ConversationRelationship/PNC_ConversationRelationship_Previews"
local Snapshot = {}

function Snapshot.Copy(summary)
    return {
        npcID = tostring(summary.npcID or ""),
        exists = summary.exists == true,
        approval = tonumber(summary.approval) or 0,
        respect = tonumber(summary.respect) or 0,
        familiarity = tonumber(summary.familiarity) or 0,
        state = summary.state,
        previousState = summary.previousState,
        revision = tonumber(summary.revision) or 0,
        interactionRevision = tonumber(summary.interactionRevision) or 0,
        socialRevision = tonumber(summary.socialRevision) or 0,
        identityKey = summary.identityKey,
        relationshipLookup = summary.relationshipLookup,
        recruitmentPreview = Previews.CopyRecruitmentPreview(
            summary.recruitmentPreview
        ),
        departurePreview = Previews.CopyDeparturePreview(summary.departurePreview),
        settlementVisit = summary.settlementVisit and {
            active = summary.settlementVisit.active == true,
            kind = summary.settlementVisit.kind,
            visitID = summary.settlementVisit.visitID,
            communityID = summary.settlementVisit.communityID,
            settlementFactionID = summary.settlementVisit.settlementFactionID,
            startedAt = tonumber(summary.settlementVisit.startedAt) or 0,
            expiresAt = tonumber(summary.settlementVisit.expiresAt) or 0,
            revision = tonumber(summary.settlementVisit.revision) or 0,
        } or nil,
        ambientVisitPreview = Previews.CopyAmbientVisitPreview(
            summary.ambientVisitPreview
        ),
    }
end

function Snapshot.Same(left, right)
    if type(left) ~= "table" or type(right) ~= "table" then
        return false
    end
    return (tonumber(left.revision) or 0) == (tonumber(right.revision) or 0)
        and (tonumber(left.approval) or 0) == (tonumber(right.approval) or 0)
        and (tonumber(left.respect) or 0) == (tonumber(right.respect) or 0)
        and (tonumber(left.familiarity) or 0)
            == (tonumber(right.familiarity) or 0)
        and tostring(left.state or "") == tostring(right.state or "")
        and tostring(left.previousState or "")
            == tostring(right.previousState or "")
        and (tonumber(left.interactionRevision) or 0)
            == (tonumber(right.interactionRevision) or 0)
        and (tonumber(left.socialRevision) or 0)
            == (tonumber(right.socialRevision) or 0)
        and Previews.SameRecruitmentPreview(left, right)
        and Previews.SameDeparturePreview(left, right)
        and Previews.SameSettlementVisit(left, right)
        and Previews.SameAmbientVisitPreview(left, right)
end

Snapshot.SameSettlementVisit = Previews.SameSettlementVisit
Snapshot.SameAmbientVisitPreview = Previews.SameAmbientVisitPreview

return Snapshot
