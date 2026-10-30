local T = require "tests/support/test"
T.addPackagePaths({ { "ProjectHoomans", "client" } })

PNC = nil
local Session = T.load("ProjectHoomans", "client",
    "PNC/Semantics/PNC_SemanticDialogueSession.lua")
T.equal(rawget(_G, "PNC"), nil, "cold seam does not initialize a global owner")
T.equal(PNC.Semantics, nil, "translation fallback gains no semantic application owner")
T.equal(Session.GetActiveView(), nil, "cold active-view query is empty")
T.equal(package.loaded["PNC/Semantics/PNC_SemanticDialogueInput"], nil,
    "session seam does not boot the semantic application")
Session.ClearWorkingState(nil)
Session.ReleaseView(nil)

local resets = 0
local queue = { "conversation-owned" }
local session = {
    semanticDialoguePending = {}, semanticDialogueRouter = {},
    semanticActorConversationService = {}, semanticDialogueState = {},
    semanticDialogueContext = { Reset = function() resets = resets + 1 end },
    queue = queue, busy = true, closed = false, conversationTopicMask = 3,
}
local view = {
    session = session, lastSemanticDialogueResult = {}, lastSemanticActionResult = {},
}
PNC = { Semantics = { DialogueInput = { ActiveView = view } } }
T.equal(Session.GetActiveView(), view, "query returns the canonical active view")
Session.ClearWorkingState(session)
T.equal(resets, 1, "semantic context resets once before its reference is released")
T.equal(session.semanticDialoguePending, nil, "pending semantic work is released")
T.equal(session.semanticDialogueRouter, nil, "router is released")
T.equal(session.semanticActorConversationService, nil, "actor service is released")
T.equal(session.semanticDialogueContext, nil, "context is released")
T.equal(session.semanticDialogueState, nil, "state is released")
T.equal(session.queue, queue, "session seam does not own conversation delivery queue")
T.truthy(session.busy, "conversation flags remain coordinator-owned")
T.falsy(session.closed, "session seam cannot close a scene")
T.equal(session.conversationTopicMask, 3, "memory facts remain coordinator-owned")
Session.ClearWorkingState(session)
T.equal(resets, 1, "repeated cleanup does not repeat context reset")
Session.ReleaseView(view)
T.equal(Session.GetActiveView(), nil, "active view is released by its owner")
T.equal(view.lastSemanticDialogueResult, nil, "semantic presentation is released")
T.equal(view.lastSemanticActionResult, nil, "action presentation is released")

local other = {}
PNC.Semantics.DialogueInput.ActiveView = other
Session.ReleaseView(view)
T.equal(Session.GetActiveView(), other, "late cleanup cannot replace a different active view")
T.finish("pnc_semantic_session_boundary_smoke")
