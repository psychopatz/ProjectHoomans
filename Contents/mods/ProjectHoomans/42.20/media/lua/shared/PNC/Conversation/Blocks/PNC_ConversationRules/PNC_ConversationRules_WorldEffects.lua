local Registry = PNC.Conversation.Registry

local function registerCeasefireEffect()
    if Registry.effectHandlers["pnc:ceasefire"] then return end
    Registry.RegisterEffectHandler("pnc:ceasefire", {
        validate = function(context)
            return context.allowHostileParley == true,
                "ceasefire_unavailable"
        end,
        apply = function(context)
            local scene = PNC.ConversationScene
            if not scene or not scene.HandleClientCommand then
                return false, "conversation_scene_unavailable"
            end
            return scene.HandleClientCommand(
                context.player,
                scene.CMD_CEASEFIRE,
                { id = context.npcID, token = context.token }
            )
        end,
        simulate = function() return { ceasefire = true } end,
        builtin = true,
    })
end

local function validateKnowledgeDisclosure(context, effect)
    if not context.characterUUID or not context.npcID then
        return false, "knowledge_context_unavailable"
    end
    if type(effect.descriptorID) ~= "string"
        or effect.descriptorID == ""
    then
        return false, "descriptor_id_required"
    end
    if not PNC.NPCKnowledge or not PNC.NPCKnowledge.CanDisclose then
        return false, "knowledge_service_unavailable"
    end
    return PNC.NPCKnowledge.CanDisclose(
        context.characterUUID,
        context.npcID,
        effect.descriptorID
    )
end

local function applyKnowledgeDisclosure(context, effect)
    local result
    local reason
    if not PNC.NPCKnowledge or not PNC.NPCKnowledge.Disclose then
        return false, "knowledge_service_unavailable"
    end
    result, reason = PNC.NPCKnowledge.Disclose(
        context.characterUUID,
        context.npcID,
        effect.descriptorID,
        {
            sourceEventID = table.concat({
                "conversation",
                tostring(context.blockID or "block"),
                tostring(context.choiceID or "choice"),
                tostring(context.outcomeID or "outcome"),
            }, ":"),
            worldAgeHours = context.worldAgeHours,
        }
    )
    return result ~= nil, reason, result
end

local function registerKnowledgeEffect()
    if Registry.effectHandlers["pnc:knowledge_disclosure"] then return end
    Registry.RegisterEffectHandler("pnc:knowledge_disclosure", {
        validate = validateKnowledgeDisclosure,
        apply = applyKnowledgeDisclosure,
        simulate = function(_, effect)
            return { knowledgeDisclosure = effect.descriptorID }
        end,
        builtin = true,
    })
end

local function registerTerritoryEffect()
    if Registry.effectHandlers["pnc:open_territory_claim"] then return end
    Registry.RegisterEffectHandler("pnc:open_territory_claim", {
        validate = function(context)
            return context.baseEstablished ~= true
                and context.audiences
                and context.audiences.member == true,
                "territory_claim_unavailable"
        end,
        apply = function()
            return true, "territory_claim_ready", { openClaim = true }
        end,
        simulate = function() return { openClaim = true } end,
        builtin = true,
    })
end


registerCeasefireEffect()
registerKnowledgeEffect()
registerTerritoryEffect()
