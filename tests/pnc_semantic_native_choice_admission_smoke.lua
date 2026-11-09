local T = require "tests/support/test"
T.addPackagePaths()
PsychopatzCore = { Conversation = {} }
PNC = { Semantics = { DialogueInput = { Internal = {} } } }
local Input = PNC.Semantics.DialogueInput
local Internal = Input.Internal
local frame = { kind = "semantic_conversation_category", candidateID = "knowledge", requestRevision = 0 }
local router = { state = { sequence = 0 } }
Internal.Suggestions = { IsConversationCategoryFrame = function(f) return f.kind == frame.kind end }
Internal.Interactive = function() return true end
Internal.RouterFor = function() return router end
Internal.suggestionText = function() return "What's up?" end
Internal.suggestionTooltip = function() return "" end
Internal.authoredRootChoice = function() return nil end
Internal.preserveAuthoredValue = function(v) return v end
Internal.restoreSemanticChoices = function() end
Internal.recordSemanticChoiceClick = function() end
T.load("ProjectHoomans", "client", "PNC/Semantics/PNC_SemanticDialogueInput_FrameSupport.lua")
T.load("ProjectHoomans", "client", "PNC/Semantics/PNC_SemanticDialogueInput_Lifecycle_Presentation_Choices.lua")
local routed = 0
Input.SubmitSemanticFrame = function(view, clicked)
    local accepted, reason = Internal.BeginDirectFrame(view, clicked)
    if accepted then
        routed = routed + 1
        Internal.FinishDirectFrame(view, reason)
    end
    return accepted, reason
end
-- Use Core's actual selectChoice/clearChoices lifecycle, with only text,
-- history and widgets excluded from this headless admission test.
local nativeRequire = require
require = function() end
local Session = T.load("PsychopatzCore", "common_client",
    "PsychopatzCore/UI/Conversation/PsychopatzConversationSession.lua")
require = nativeRequire
local view = { spec = { context = {} }, semanticSuggestions = {
    candidates = { { id = "knowledge", frame = frame } },
} }
view.session = setmetatable({ conversationID = "native", choices = {}, queue = {},
    context = {}, finishPending = function() end,
    setPresentedChoices = function(self, rows) self.choices = rows end,
}, { __index = Session })
local rows = Internal.PresentSemanticChoices(view, {})
view.session.choices = rows
T.truthy(view.session:selectChoice(rows[1]), "Core accepts the visible choice")
T.equal(routed, 1, "native choice must survive Core clearing its presented rows")
T.equal(view.semanticCoreChoiceFrame, nil, "native dispatch scope is cleared")
local accepted, reason = Internal.BeginDirectFrame(view, frame)
T.falsy(accepted, "an unpresented direct frame must still be rejected")
T.equal(reason, "suggestion_not_presented", "presentation validation stays enforced")
-- Duplicate/stale frames must not acquire a second accepted receipt.
rows[1].action()
T.equal(routed, 1, "duplicate click must not execute again")
view.session.semanticSuggestionReceipts = {}
router.state.sequence = 1
rows[1].action()
T.equal(view.lastSemanticSuggestionReason, "stale_suggestion", "native dispatch still checks revision")
T.equal(routed, 1, "stale choice must not execute")
router.state.sequence = 0
view.semanticSuggestions.candidates[1].enabled = false
local disabled = Internal.PresentSemanticChoices(view, {})
T.falsy(disabled[1].action(), "disabled choice cannot enter native dispatch scope")
T.equal(routed, 1, "disabled choice must not execute")
T.finish("pnc_semantic_native_choice_admission_smoke")
