-- Stable static semantic suggestion provider entry point.
-- Definitions and eligibility routing load behind the same Provider object.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Provider = PNC.Semantics.DialogueStaticChoiceProvider or {}
PNC.Semantics.DialogueStaticChoiceProvider = Provider
local IdentityAlias = PNC.IdentityAlias
if type(IdentityAlias) ~= "table" then
    local ok, loaded = pcall(require, "PNC/Core/Identity/PNC_IdentityAlias")
    IdentityAlias = PNC.IdentityAlias
    if type(IdentityAlias) ~= "table" and ok and type(loaded) == "table" then
        IdentityAlias = loaded
    end
end

Provider.id = "projecthoomans.static_questions"
Provider.sourceKind = "typed_input"
Provider.order = 50
Provider.Definitions = require
    "PNC/Semantics/Generated/Conversation/UI/StaticSuggestions"

function Provider.Find(id)
    for _, definition in ipairs(Provider.Definitions) do
        if definition.id == id then return definition end
    end
    return nil
end

local Identity = require
    "PNC/Semantics/SemanticDialogueSuggestions/PNC_SemanticDialogueSuggestions_StaticProvider_Identity"
local Context = require
    "PNC/Semantics/SemanticDialogueSuggestions/PNC_SemanticDialogueSuggestions_StaticProvider_Context"
local hubCandidate = require
    "PNC/Semantics/SemanticDialogueSuggestions/PNC_SemanticDialogueSuggestions_StaticProvider_Hub"
local installCollection = require
    "PNC/Semantics/SemanticDialogueSuggestions/PNC_SemanticDialogueSuggestions_StaticProvider_Collect"

installCollection(Provider, Identity, Context, hubCandidate, IdentityAlias)

return Provider
