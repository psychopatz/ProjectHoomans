-- Semantic response template-key resolver.
--
-- Dialogue Content derives the only first-party semantic-template → wording
-- join. Runtime aliases are generated from that source for already-emitted
-- packet keys; this module contains no authored key catalog.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input
local Internal = Input.Internal or {}
Input.Internal = Internal

local Registry = PNC.Semantics.DialogueContentRegistry
    or require "PNC/Semantics/Generated/DialogueContent/Registry"

local function semanticTranslationKey(response)
    local templateID = tostring(response and response.templateID or "")
    if type(Registry) ~= "table" then return nil end
    if string.sub(templateID, 1, 7) == "UI_PNC_"
        and type(Registry.RUNTIME_ALIASES) == "table"
        and Registry.RUNTIME_ALIASES[templateID] ~= nil
    then
        return templateID
    end
    if string.sub(templateID, 1, 28)
        == "UI_PNC_Conversation_Content_"
    then
        return templateID
    end
    local args = response and response.args or nil
    local resolvedID = templateID
    if templateID == "semantic.question.backstory.known"
        and type(args) == "table" and type(args.kind) == "string"
        and args.kind ~= ""
    then
        resolvedID = templateID .. "." .. args.kind
    end
    if type(Registry.KeyFor) == "function" then
        return Registry.KeyFor(
            resolvedID,
            response and response.realizationVariant or nil
        )
    end
    return nil
end

Internal.SemanticTranslationKey = semanticTranslationKey

return semanticTranslationKey

