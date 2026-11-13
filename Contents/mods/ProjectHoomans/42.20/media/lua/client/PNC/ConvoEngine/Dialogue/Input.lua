-- Hybrid conversation input. Lua handles deterministic utterances first;
-- only the policy's explicit fallback route may call PBrainZ.
-- The widget is an optional client presentation integration. Semantic parsing,
-- policy, and conversation browsing must remain loadable in headless previews
-- and deterministic tests when the native UI package is unavailable.
pcall(require, "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationLLMInput")
require "PsychopatzCore/ConvoEngine/DialogueRouter"
require "PNC/Semantics/PNC_SemanticDiagnostics"
local DialogueRuntime = PNC and PNC.ConvoEngine.SemanticDialogueRuntime or nil
if type(DialogueRuntime) ~= "table" then
    local loadedDialogueRuntime = require
        "PNC/ConvoEngine/Dialogue/Runtime"
    DialogueRuntime = type(loadedDialogueRuntime) == "table"
        and loadedDialogueRuntime
        or PNC and PNC.ConvoEngine.SemanticDialogueRuntime
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
require "PNC/ConvoEngine/Dialogue/Policy"
require "PNC/ConvoEngine/Dialogue/ResponseCatalog"
require "PNC/Semantics/PNC_SemanticCommandAdapter"
require "PNC/Semantics/PNC_SemanticTaskAdapter"
require "PNC/Semantics/PNC_SemanticInventoryQueryAdapter"

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Policy = PNC.ConvoEngine.DialoguePolicy
local Text = PsychopatzCore.Conversation.Text
local ResponseCatalog = PNC.ConvoEngine.ResponseCatalog
local LocalResponse = PNC.ConvoEngine.LocalResponse
local Diagnostics = PNC.Semantics.SemanticDiagnostics
local Input = PNC.ConvoEngine.DialogueInput or {}
PNC.ConvoEngine.DialogueInput = Input

local InteractionLifecycle = PNC.ConvoEngine.InteractionLifecycle
if type(InteractionLifecycle) ~= "table" then
    local loaded = require
        "PNC/ConvoEngine/Interaction/Lifecycle"
    InteractionLifecycle = type(loaded) == "table" and loaded or nil
end

if Policy and type(Policy.RegisterTextFallbacks) == "function" then
    Policy.RegisterTextFallbacks()
end
if ResponseCatalog and type(ResponseCatalog.RegisterTextFallbacks) == "function" then
    -- History may contain semantic keys written before keyed fallbacks were
    -- persisted. Register the current catalog before a full-screen session
    -- loads that history so those old rows remain readable as well.
    ResponseCatalog.RegisterTextFallbacks()
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

require "PNC/ConvoEngine/Dialogue/Input_Context"
require "PNC/ConvoEngine/Dialogue/Input_Recovery"
require "PNC/ConvoEngine/Dialogue/Input_QuestResults"
require "PNC/ConvoEngine/Dialogue/Input_Presentation"
require "PNC/ConvoEngine/Dialogue/Input_Actions"
require "PNC/ConvoEngine/Dialogue/Input_GiftPresentation"
require "PNC/ConvoEngine/Dialogue/Input_Gifts"
require "PNC/ConvoEngine/Dialogue/Input_Inventory"
require "PNC/ConvoEngine/Dialogue/Input_Tasks"
require "PNC/ConvoEngine/Dialogue/Input_Trace"
require "PNC/ConvoEngine/Dialogue/Input_ProviderFallback"
require "PNC/ConvoEngine/Dialogue/Input_Lifecycle"
local Suggestions = PNC.ConvoEngine.DialogueSuggestions
if type(Suggestions) ~= "table" then
    require "PNC/ConvoEngine/Dialogue/Suggestions"
    Suggestions = PNC.ConvoEngine.DialogueSuggestions
end
Suggestions = type(Suggestions) == "table" and Suggestions or {}

local Internal = Input.Internal

Internal.DialogueRuntime = DialogueRuntime
Internal.Text = Text
Internal.InteractionLifecycle = InteractionLifecycle
Internal.Suggestions = Suggestions

require "PNC/ConvoEngine/Dialogue/Input_FrameSupport"
require "PNC/ConvoEngine/Dialogue/Input_NavigationFrames"
require "PNC/ConvoEngine/Dialogue/Input_SubmissionFrames"
require "PNC/ConvoEngine/Dialogue/Input_State"

return Input
