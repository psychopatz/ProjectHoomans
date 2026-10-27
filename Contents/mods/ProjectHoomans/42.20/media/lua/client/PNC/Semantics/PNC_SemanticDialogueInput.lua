-- Hybrid conversation input. Lua handles deterministic utterances first;
-- only the policy's explicit fallback route may call PBrainZ.
-- The widget is an optional client presentation integration. Semantic parsing,
-- policy, and conversation browsing must remain loadable in headless previews
-- and deterministic tests when the native UI package is unavailable.
pcall(require, "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationLLMInput")
require "PsychopatzCore/Semantics/PsychopatzSemanticDialogueRouter"
require "PNC/Semantics/PNC_SemanticDiagnostics"
local DialogueRuntime = PNC and PNC.Semantics
    and PNC.Semantics.SemanticDialogueRuntime or nil
if type(DialogueRuntime) ~= "table" then
    local loadedDialogueRuntime = require
        "PNC/Semantics/PNC_SemanticDialogueRuntime"
    DialogueRuntime = type(loadedDialogueRuntime) == "table"
        and loadedDialogueRuntime
        or PNC and PNC.Semantics
            and PNC.Semantics.SemanticDialogueRuntime
        or {
            IsEnabled = function() return true end,
        }
end
-- Optional module boundary: a legacy package must keep its ordinary
-- deterministic conversation path if this diagnostic spoke is absent.
local handshakeLoaded, SemanticCapabilityHandshake = pcall(require,
    "PNC/Semantics/PNC_SemanticCapabilityHandshake")
if not handshakeLoaded or type(SemanticCapabilityHandshake) ~= "table" then
    SemanticCapabilityHandshake = nil
end
-- The semantic input is a client entry point as well as a shared-composition
-- consumer. Load the Hoomans vocabulary here so a partial composition cannot
-- silently fall through to the generic LLM wait path.
require "PNC/Semantics/PNC_SemanticCatalog"
require "PNC/Semantics/PNC_SemanticConsumptionCatalog"
require "PNC/Semantics/PNC_SemanticDialoguePolicy"
require "PNC/Semantics/PNC_SemanticDialogueResponseCatalog"
require "PNC/Semantics/PNC_SemanticCommandAdapter"
require "PNC/Semantics/PNC_SemanticTaskAdapter"
require "PNC/Semantics/PNC_SemanticInventoryQueryAdapter"

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Policy = PNC.Semantics.DialoguePolicy
local Text = PsychopatzCore.Conversation.Text
local ResponseCatalog = PNC.Semantics.ResponseCatalog
local LocalResponse = PNC.Semantics.LocalResponse
local Diagnostics = PNC.Semantics.SemanticDiagnostics
local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input

local InteractionLifecycle = PNC.Semantics.InteractionLifecycle
if type(InteractionLifecycle) ~= "table" then
    local loaded = require
        "PNC/Semantics/PNC_SemanticInteractionLifecycle"
    InteractionLifecycle = type(loaded) == "table" and loaded or nil
end

if SemanticCapabilityHandshake
    and type(SemanticCapabilityHandshake.Report) == "function"
then
    SemanticCapabilityHandshake.Report()
elseif Diagnostics
    and type(Diagnostics.IsEnabled) == "function"
    and Diagnostics.IsEnabled() == true
    and type(Diagnostics.Record) == "function"
then
    Diagnostics.Record("semantic.capability_handshake", {
        ok = false,
        sourceMarker = "missing",
        failures = { "capability_handshake_module_unavailable" },
    }, { dedupeKey = "semantic-capability-handshake" })
end

Input.VERSION = 2
Input.MAX_INPUT_LENGTH = 4000
Input.Internal = Input.Internal or {}

require "PNC/Semantics/PNC_SemanticDialogueInput_Context"
require "PNC/Semantics/PNC_SemanticDialogueInput_Recovery"
require "PNC/Semantics/PNC_SemanticDialogueInput_QuestResults"
require "PNC/Semantics/PNC_SemanticDialogueInput_Presentation"
require "PNC/Semantics/PNC_SemanticDialogueInput_Actions"
require "PNC/Semantics/PNC_SemanticDialogueInput_GiftPresentation"
require "PNC/Semantics/PNC_SemanticDialogueInput_Gifts"
require "PNC/Semantics/PNC_SemanticDialogueInput_Inventory"
require "PNC/Semantics/PNC_SemanticDialogueInput_Tasks"
require "PNC/Semantics/PNC_SemanticDialogueInput_Trace"
require "PNC/Semantics/PNC_SemanticDialogueInput_ProviderFallback"
require "PNC/Semantics/PNC_SemanticDialogueInput_Lifecycle"
local Suggestions = PNC.Semantics.DialogueSuggestions
if type(Suggestions) ~= "table" then
    require "PNC/Semantics/PNC_SemanticDialogueSuggestions"
    Suggestions = PNC.Semantics.DialogueSuggestions
end
Suggestions = type(Suggestions) == "table" and Suggestions or {}

local Internal = Input.Internal

Internal.DialogueRuntime = DialogueRuntime
Internal.Text = Text
Internal.InteractionLifecycle = InteractionLifecycle
Internal.Suggestions = Suggestions

require "PNC/Semantics/PNC_SemanticDialogueInput_FrameSupport"
require "PNC/Semantics/PNC_SemanticDialogueInput_NavigationFrames"
require "PNC/Semantics/PNC_SemanticDialogueInput_SubmissionFrames"
require "PNC/Semantics/PNC_SemanticDialogueInput_State"

return Input
