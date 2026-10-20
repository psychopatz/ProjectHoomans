local T = require "tests/support/test"

T.load("tests/pnc_npc_foundation_parity_baseline_smoke.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Travel/PNC_Travel.lua")
local Fixtures = require
    "tests/support/pnc_npc_foundation_import_plan_fixtures"
local Core = require "PsychopatzCore/Actors/PsychopatzActors"
local Adapter = PNC.Persistence.CoreSocial

T.truthy(Adapter, "Core social adapter was not registered")
local sourceRecord, targetKey = Fixtures.PrepareContinuitySourceRecord(
    "npc:p4:social")
local originalSocial = PNC.Persistence.ImportPlan.Copy(sourceRecord.social)
local projected, projectReason = Adapter.Project(sourceRecord, PsychopatzCore)
T.truthy(projected, projectReason)
T.equal(projected.relationships[targetKey].memories[1].id,
    "memory:p0b:friend", "relationship memory projected")
T.equal(projected.relationships[targetKey].targetKey, targetKey,
    "relationship direction projected")
T.equal(projected.revision, sourceRecord.social.revision,
    "social revision projected")
T.truthy(projected.personality, "personality projected")
T.truthy(Fixtures.EqualValue(sourceRecord.social, originalSocial),
    "projection changed Hoomans source social state")

local event = {
    targetKey = targetKey,
    eventID = "event:p4:authorized",
    type = "conversation_completed",
    approvalDelta = 6,
    respectDelta = 2,
    familiarityDelta = 5,
    createdAt = 88,
    authority = "server",
    authorized = true,
}
local approvalBeforeEvent = projected.relationships[targetKey].approval
local applied, eventReason = Adapter.RecordAuthorizedEvent(projected,
    PsychopatzCore, event)
T.truthy(applied, eventReason)
T.equal(applied.relationships[targetKey].approval,
    approvalBeforeEvent + 6,
    "authorized approval delta")
T.equal(applied.relationships[targetKey].memories[#applied.relationships[
    targetKey].memories].id, event.eventID, "authorized event memory")

local duplicate, duplicateReason = Adapter.RecordAuthorizedEvent(applied,
    PsychopatzCore, event)
T.equal(duplicate, nil, "duplicate social event accepted")
T.equal(duplicateReason, "duplicate_event", "duplicate social event reason")

local unauthorized, unauthorizedReason = Adapter.RecordAuthorizedEvent(
    projected, PsychopatzCore, {
        targetKey = targetKey,
        eventID = "event:p4:client",
        authority = "client",
        authorized = false,
    })
T.equal(unauthorized, nil, "unauthorized social event accepted")
T.equal(unauthorizedReason, "server_authority_required",
    "unauthorized social event reason")

local missing, missingReason = Adapter.Project({}, PsychopatzCore)
T.equal(missing, nil, "missing social source accepted")
T.equal(missingReason, "source_social_missing", "missing social reason")

T.finish("pnc_npc_foundation_social_adapter_smoke")
