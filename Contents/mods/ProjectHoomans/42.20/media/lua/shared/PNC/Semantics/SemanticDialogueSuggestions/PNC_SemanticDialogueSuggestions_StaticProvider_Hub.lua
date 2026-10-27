-- Hub-avenue candidate projection for static suggestions.

return function(Provider, definition, contextReason, uiNode)
    local Content = PNC.Semantics.DialogueContentRegistry
        or require "PNC/Semantics/Generated/DialogueContent/Registry"
    local content = uiNode and Content.PlayerChoice
        and Content.PlayerChoice(uiNode.contentID) or {}
    local labelKey = content.labelKey or ""
    local utteranceKey = content.choiceKey or ""
    local labelFallback = content.labelFallback or labelKey
    local utteranceFallback = content.choiceFallback or utteranceKey
    local extensions = {}
    for key, value in pairs(type(definition.extensions) == "table"
        and definition.extensions or {}) do
        extensions[key] = value
    end
    extensions.route = "semantic_provider"
    extensions.providerID = Provider.id
    extensions.hubID = uiNode and uiNode.semanticDestination
        and uiNode.semanticDestination.hubID or "whats_up"
    extensions.hubAvenue = true
    return {
        id = definition.id,
        topic = definition.topic,
        groupID = "semantic_hub.whats_up",
        rank = uiNode and uiNode.order or definition.order,
        providerID = Provider.id,
        semanticOwner = definition.semanticOwner
            or "projecthoomans.semantic." .. tostring(definition.topic),
        contextReason = contextReason,
        eligibility = {
            status = "allowed",
            allowed = true,
            reason = contextReason,
        },
        source = {
            kind = Provider.sourceKind,
            providerID = Provider.id,
            reason = "semantic_hub_avenue",
        },
        frame = {
            kind = "semantic_click_frame",
            candidateID = definition.id,
            topic = definition.topic,
            pattern = definition.patternID,
            intent = definition.intent,
            speechAct = definition.speechAct,
            action = definition.action,
            subject = definition.subject,
            target = definition.target,
            slots = definition.slots,
            modifiers = definition.modifiers,
            socialContext = definition.socialContext,
            extensions = extensions,
            textKey = utteranceKey,
            textFallback = utteranceFallback,
            labelKey = labelKey,
        },
        display = {
            labelKey = labelKey,
            labelFallback = labelFallback,
            utteranceKey = utteranceKey,
            utteranceFallback = utteranceFallback,
        },
        visibility = "player",
    }
end
