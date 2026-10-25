-- Hub-avenue candidate projection for static suggestions.

return function(Provider, definition, contextReason)
    local extensions = {}
    for key, value in pairs(type(definition.extensions) == "table"
        and definition.extensions or {}) do
        extensions[key] = value
    end
    extensions.route = "semantic_provider"
    extensions.providerID = Provider.id
    extensions.hubID = "whats_up"
    extensions.hubAvenue = true
    return {
        id = definition.id,
        topic = definition.topic,
        groupID = "semantic_hub.whats_up",
        rank = definition.order,
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
            textKey = definition.utteranceKey,
            textFallback = definition.utteranceFallback,
            labelKey = definition.labelKey,
        },
        display = {
            labelKey = definition.labelKey,
            labelFallback = definition.labelFallback,
            utteranceKey = definition.utteranceKey,
            utteranceFallback = definition.utteranceFallback,
        },
        visibility = "player",
    }
end
