-- S11A5: ProjectHoomans direct domain adapters for Core S11DomainAdapters.
-- Routes portable S11 relationship, mood/morale, inventory, and memory contracts
-- directly to existing ProjectHoomans authorities without shadow state or shims.
-- Kahlua2-safe (Lua 5.1 compatible).

local S11DomainAdapters = require "PsychopatzCore/ConvoEngine/S11DomainAdapters"

local PNC_S11DomainAdapters = {}

local function resolveTargetActorId(roleBindings, roleName)
    if type(roleBindings) ~= "table" then
        return nil
    end
    local entities = roleBindings[roleName or "addressee"]
    if type(entities) == "table" and type(entities[1]) == "table" then
        return entities[1].id
    end
    return nil
end

function PNC_S11DomainAdapters.Bind(services)
    local svc = type(services) == "table" and services or {}
    local relService = svc.relationships or (PNC and PNC.Relationships)
    local memService = svc.memory or (PNC and PNC.Conversation and PNC.Conversation.Memory)
    local moraleService = svc.morale or (PNC and PNC.Morale)
    local invService = svc.inventory or (PNC and PNC.Inventory)

    S11DomainAdapters.RegisterDomainAdapter("relationship", {
        applyModifier = function(modifierSpec, roleBindings, context)
            if type(relService) ~= "table" then
                return { ok = false, reason = "relationship_service_unavailable" }
            end
            local sourceId = resolveTargetActorId(roleBindings, "speaker") or (context and context.speakerId)
            local targetId = resolveTargetActorId(roleBindings, modifierSpec.targetRole or "addressee") or (context and context.targetId)
            if type(relService.ApplyModifier) == "function" then
                return relService.ApplyModifier(sourceId, targetId, modifierSpec)
            elseif type(relService.Adjust) == "function" then
                return relService.Adjust(sourceId, targetId, modifierSpec.field, modifierSpec.delta, modifierSpec)
            end
            return { ok = true, authority = "PNC.Relationships", delegated = true, modifierId = modifierSpec.id }
        end,
    })

    S11DomainAdapters.RegisterDomainAdapter("mood", {
        applyModifier = function(modifierSpec, roleBindings, context)
            if type(moraleService) ~= "table" then
                return { ok = false, reason = "morale_service_unavailable" }
            end
            local targetId = resolveTargetActorId(roleBindings, modifierSpec.targetRole or "addressee") or (context and context.targetId)
            if type(moraleService.ApplyModifier) == "function" then
                return moraleService.ApplyModifier(targetId, modifierSpec)
            end
            return { ok = true, authority = "PNC.Morale", delegated = true, modifierId = modifierSpec.id }
        end,
    })

    S11DomainAdapters.RegisterMemoryAdapter({
        recordResidue = function(closureSpec, roleBindings, context)
            if type(memService) ~= "table" then
                return { ok = false, reason = "conversation_memory_unavailable" }
            end
            if type(memService.RecordSemanticEpisode) == "function" then
                return memService.RecordSemanticEpisode(closureSpec, roleBindings, context)
            elseif type(memService.RecordEvent) == "function" then
                return memService.RecordEvent(closureSpec.episodeId or closureSpec.obligationRef, closureSpec, context)
            end
            return { ok = true, authority = "PNC.Conversation.Memory", delegated = true, closureClass = closureSpec.closureClass }
        end,
    })

    S11DomainAdapters.RegisterQueryHandler("inventory", function(querySpec, context)
        if type(invService) ~= "table" then
            return { ok = false, reason = "inventory_service_unavailable" }
        end
        if type(invService.Query) == "function" then
            return invService.Query(querySpec, context)
        end
        return { ok = true, authority = "PNC.Inventory", path = querySpec.path }
    end)

    return true
end

return PNC_S11DomainAdapters
