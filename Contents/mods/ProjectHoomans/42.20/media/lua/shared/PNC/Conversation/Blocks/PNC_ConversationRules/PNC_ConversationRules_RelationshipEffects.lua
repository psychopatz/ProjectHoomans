local Registry = PNC.Conversation.Registry

local DERIVED_FIELDS = {
    admire = true,
    admiration = true,
    pity = true,
    fear = true,
    despise = true,
    attitude = true,
    relationshipstate = true,
    like = true,
    hate = true,
    contempt = true,
    morale = true,
}

local EFFECT_FIELDS = {
    type = true,
    approval = true,
    respect = true,
    familiarity = true,
    decayPerDay = true,
    permanent = true,
    shareable = true,
}

local function personalRelationshipCommands()
    local relationships = PNC.Relationships
    local personal = relationships and relationships.Personal
    return personal and personal.Commands or relationships
end

local function validateRelationshipDeltas(effect, strict)
    local key
    local normalized
    local raw
    local value
    if type(effect) ~= "table" then return false, "invalid_effect" end
    for key in pairs(effect) do
        normalized = type(key) == "string" and string.lower(key) or key
        if DERIVED_FIELDS[normalized] then
            return false, "derived_relationship_effect_forbidden"
        end
        if strict and EFFECT_FIELDS[key] ~= true then
            return false, "unknown_relationship_effect_field"
        end
    end
    for _, key in ipairs({ "approval", "respect", "familiarity" }) do
        raw = effect[key]
        value = raw ~= nil and tonumber(raw) or 0
        if raw ~= nil and (value == nil or value ~= value) then
            return false, "relationship_delta_not_numeric"
        end
        if value < -100 or value > 100 then
            return false, "relationship_delta_out_of_range"
        end
    end
    return true
end

local function registerNoneEffect()
    if Registry.effectHandlers["pnc:none"] then return end
    Registry.RegisterEffectHandler("pnc:none", {
        validate = function(_, effect)
            return type(effect) == "table", "invalid_effect"
        end,
        apply = function() return true, "no_effect" end,
        simulate = function() return {} end,
        builtin = true,
    })
end

local function registerRelationshipEffect()
    if Registry.effectHandlers["pnc:relationship"] then return end
    Registry.RegisterEffectHandler("pnc:relationship", {
        validate = function(context, effect)
            if not context.npcID or not context.playerEntityKey then
                return false, "relationship_context_unavailable"
            end
            return validateRelationshipDeltas(effect, true)
        end,
        apply = function(context, effect)
            local commands = personalRelationshipCommands()
            if not commands or not commands.ApplyConversationEffect then
                return false, "relationship_service_unavailable"
            end
            return commands.ApplyConversationEffect(
                context.npcID,
                context.playerEntityKey,
                effect,
                {
                    blockID = context.blockID,
                    choiceID = context.choiceID,
                    outcomeID = context.outcomeID,
                    worldAgeHours = context.worldAgeHours,
                }
            )
        end,
        simulate = function(_, effect)
            return {
                relationship = {
                    approval = tonumber(effect.approval) or 0,
                    respect = tonumber(effect.respect) or 0,
                    familiarity = tonumber(effect.familiarity) or 0,
                },
            }
        end,
        builtin = true,
    })
end

local function validateMemory(context, effect)
    local valid
    local reason
    if not context.npcID or not context.playerEntityKey then
        return false, "relationship_context_unavailable"
    end
    valid, reason = validateRelationshipDeltas(effect)
    if not valid then return false, reason end
    if effect.familiarity ~= nil then
        return false, "memory_familiarity_effect_forbidden"
    end
    if type(effect.memoryID) ~= "string" or effect.memoryID == ""
        or type(effect.memoryType) ~= "string"
        or effect.memoryType == ""
    then
        return false, "memory_identity_required"
    end
    return true
end

local function applyMemory(context, effect)
    local commands = personalRelationshipCommands()
    if not commands or not commands.AddMemory then
        return false, "relationship_service_unavailable"
    end
    return commands.AddMemory(
        context.npcID,
        context.playerEntityKey,
        {
            id = effect.memoryID,
            type = effect.memoryType,
            createdAt = context.worldAgeHours,
            lastEvaluatedAt = context.worldAgeHours,
            approvalEffect = tonumber(effect.approval) or 0,
            respectEffect = tonumber(effect.respect) or 0,
            moraleEffect = 0,
            strength = tonumber(effect.strength) or 1,
            decayPerDay = tonumber(effect.decayPerDay) or 0,
            permanent = effect.permanent == true,
            shareable = effect.shareable == true,
            knowledgeSource = effect.knowledgeSource or "experienced",
            sourceKey = context.playerEntityKey,
            tags = effect.tags,
        }
    )
end

local function registerMemoryEffect()
    if Registry.effectHandlers["pnc:memory"] then return end
    Registry.RegisterEffectHandler("pnc:memory", {
        validate = validateMemory,
        apply = applyMemory,
        simulate = function(_, effect)
            return {
                memory = {
                    id = effect.memoryID,
                    type = effect.memoryType,
                },
            }
        end,
        builtin = true,
    })
end


registerNoneEffect()
registerRelationshipEffect()
registerMemoryEffect()
