-- Static provider collection and context routing.

return function(Provider, Identity, Context, hubCandidate, IdentityAlias)
    function Provider.collect(context)
        context = type(context) == "table" and context or {}
        if Identity.pendingIdentity(context) then
            return Identity.identityChoiceCandidates(
                context, Provider, IdentityAlias
            )
        end
        if context.activeHubID ~= "whats_up" then
            local output = {}
            for _, definition in ipairs(Provider.Definitions) do
                if definition.id ~= "question.identity"
                    or not Identity.identityKnown(context)
                then
                    output[#output + 1] = definition
                end
            end
            return output
        end

        local actor = type(context.actorConversationContext) == "table"
            and context.actorConversationContext or {}
        local hostile = Context.hostileActor(actor)
        local owned = Context.ownedCompanion(actor)
        local safeGossip = Context.hasSafeGossip(context)
        local output = {}
        for _, definition in ipairs(Provider.Definitions) do
            if definition.hubID == "whats_up"
                and (definition.id ~= "question.identity"
                    or not Identity.identityKnown(context))
            then
                local allowed = not hostile
                    or definition.id == "question.weather"
                local contextReason = hostile
                    and "safe_public_weather_context"
                    or "non_hostile_public_context"
                if definition.hubAudience == "owned_companion" then
                    allowed = allowed and owned
                    contextReason = owned and "owned_companion_context"
                        or "owned_companion_required"
                end
                if definition.hubRequiresSafeGossip then
                    allowed = allowed and safeGossip
                    contextReason = safeGossip and "player_safe_gossip_available"
                        or "safe_gossip_unavailable"
                end
                if allowed then
                    output[#output + 1] = hubCandidate(definition, contextReason)
                end
            end
        end
        return output
    end
end
