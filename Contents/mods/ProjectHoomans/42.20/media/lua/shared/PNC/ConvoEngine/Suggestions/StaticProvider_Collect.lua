-- Static provider collection and context routing.
local AboutYou = require "PNC/ConvoEngine/Suggestions/AboutYouCatalog"

local ABOUT_YOU_FACET_IDS = {
    ["question.identity_nickname"] = true,
    ["question.identity_surname"] = true,
    ["question.identity_faction"] = true,
}

return function(Provider, Identity, Context, hubCandidate, IdentityAlias)
    local function available(definition, context)
        if definition.id == "question.identity" then
            return not Identity.identityKnown(context)
        end
        if ABOUT_YOU_FACET_IDS[definition.id] then
            return false
        end
        return true
    end

    function Provider.collect(context)
        context = type(context) == "table" and context or {}
        if Identity.pendingIdentity(context) then
            return Identity.identityChoiceCandidates(
                context, Provider, IdentityAlias
            )
        end
        if context.activeHubID == AboutYou.HUB_ID then
            return AboutYou.CollectHubCandidates(Provider, context, hubCandidate)
        end
        local definitions = type(Provider.GetDefinitions) == "function"
            and Provider.GetDefinitions(context) or Provider.Definitions
        if context.activeHubID ~= "whats_up" then
            local output = {}
            for _, definition in ipairs(definitions) do
                if available(definition, context) then
                    output[#output + 1] = definition
                end
            end
            if Identity.identityKnown(context)
                and AboutYou.HasRemainingFacets(context)
            then
                output[#output + 1] = AboutYou.ROOT_DEFINITION
            end
            return output
        end

        local actor = type(context.actorConversationContext) == "table"
            and context.actorConversationContext or {}
        local hostile = Context.hostileActor(actor)
        local owned = Context.ownedCompanion(actor)
        local safeGossip = Context.hasSafeGossip(context)
        local output = {}
        for _, definition in ipairs(definitions) do
            if definition.hubID == "whats_up"
                and available(definition, context)
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
                    output[#output + 1] = hubCandidate(
                        Provider, definition, contextReason
                    )
                end
            end
        end
        return output
    end
end
