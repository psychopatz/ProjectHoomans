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
local Content = PNC.Semantics.DialogueContentRegistry
    or require "PNC/Semantics/Generated/DialogueContent/Registry"
local UIRegistry = PNC.Semantics.ConversationUIRegistry
    or require "PNC/Semantics/Generated/ConversationUI/Registry"
local semanticChoices = require
    "PNC/Semantics/SemanticDialogueSuggestions/PNC_SemanticDialogueSuggestions_StaticProvider_SemanticChoices"

Provider.Definitions = {}
for _, definition in ipairs(semanticChoices) do
    local enriched = {}
    for key, value in pairs(definition) do enriched[key] = value end
    local node = UIRegistry.Node("conversation.choice:" .. tostring(definition.id))
    local contentID = node and node.contentID
        or "conversation.choice:" .. tostring(definition.id)
    local content = Content.PlayerChoice
        and Content.PlayerChoice(contentID) or {}
    enriched.labelKey = content.labelKey
    enriched.labelFallback = content.labelFallback
    enriched.utteranceKey = content.choiceKey
    enriched.utteranceFallback = content.choiceFallback
    Provider.Definitions[#Provider.Definitions + 1] = enriched
end

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
