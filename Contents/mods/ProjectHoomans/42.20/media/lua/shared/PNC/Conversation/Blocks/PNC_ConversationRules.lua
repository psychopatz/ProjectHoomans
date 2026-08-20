require "PNC/Conversation/Blocks/PNC_ConversationRegistry"

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Registry = PNC.Conversation.Registry
local Rules = PNC.Conversation.Rules or {}
PNC.Conversation.Rules = Rules

local function personalRelationshipCommands()
    local relationships = PNC.Relationships
    local personal = relationships and relationships.Personal
    return personal and personal.Commands or relationships
end

local function compare(actual, operator, expected)
    operator = operator or ">="
    if operator == "==" then return actual == expected end
    if operator == "~=" then return actual ~= expected end
    actual = tonumber(actual)
    expected = tonumber(expected)
    if actual == nil or expected == nil then return false end
    if operator == ">=" then return actual >= expected end
    if operator == "<=" then return actual <= expected end
    if operator == ">" then return actual > expected end
    if operator == "<" then return actual < expected end
    return false
end

local function tableValue(root, key)
    return type(root) == "table" and root[key] or nil
end

local function skillLevel(context, gate)
    local actor = gate.actor == "npc" and "npc" or "player"
    local values = context[actor .. "Skills"]
    local level = tableValue(values, gate.skill)
    if level ~= nil then return tonumber(level) or 0 end
    if actor == "npc" and PNC.Skills and PNC.Skills.GetLevel
        and context.npcRecord
    then return tonumber(PNC.Skills.GetLevel(context.npcRecord, gate.skill)) or 0 end
    local player = context.player
    if actor == "player" and player and player.getPerkLevel then
        local perk = gate.perk
        if not perk and Perks and Perks.FromString then
            perk = Perks.FromString(tostring(gate.skill or ""))
        end
        if perk then return tonumber(player:getPerkLevel(perk)) or 0 end
    end
    return 0
end

local function personalityValue(context, gate)
    local actor = gate.actor == "player" and "player" or "npc"
    local values = actor == "npc"
        and (context.npcPersonality
            or context.npcRecord and context.npcRecord.personality)
        or (context.playerPersonality or context.playerSocialProfile)
    return tableValue(values, gate.key or gate.dimension)
end

local function hasTrait(context, gate)
    local traits
    if gate.actor == "npc" then
        traits = context.npcTraits
    else
        traits = context.playerTraits
            or context.playerSocialProfile
                and context.playerSocialProfile.sourceTraits
    end
    if type(traits) == "table" then
        if traits[gate.trait] == true then return true end
        for _, value in ipairs(traits) do
            if value == gate.trait then return true end
        end
    end
    local player = context.player
    return gate.actor ~= "npc" and player and player.HasTrait
        and player:HasTrait(gate.trait) == true or false
end

local function timeMatches(context, gate)
    local hour = tonumber(context.hour)
    if hour == nil then
        hour = (tonumber(context.worldAgeHours) or 0) % 24
    end
    local first = tonumber(gate.startHour) or 0
    local last = tonumber(gate.endHour) or 24
    if first <= last then return hour >= first and hour < last end
    return hour >= first or hour < last
end

local function historyMatches(context, gate)
    local entry = context.historyEntry
    if type(context.historyLookup) == "function" then
        entry = context.historyLookup(gate.subjectID, gate.scope)
    end
    entry = type(entry) == "table" and entry or {}
    if gate.maxUses ~= nil
        and (tonumber(entry.useCount) or 0) >= tonumber(gate.maxUses)
    then return false end
    if gate.cooldownHours ~= nil and entry.lastUsedWorldHour ~= nil
        and (tonumber(context.worldAgeHours) or 0)
            < tonumber(entry.lastUsedWorldHour) + tonumber(gate.cooldownHours)
    then return false end
    return true
end

local BUILTINS = {
    ["pnc:skill"] = function(context, gate)
        return compare(skillLevel(context, gate), gate.operator, gate.value)
    end,
    ["pnc:trait"] = function(context, gate)
        return hasTrait(context, gate) == (gate.present ~= false)
    end,
    ["pnc:personality"] = function(context, gate)
        return compare(personalityValue(context, gate), gate.operator, gate.value)
    end,
    ["pnc:relationship"] = function(context, gate)
        local relationship = context.relationship or {}
        local actual = relationship[gate.axis or gate.key]
        return compare(actual, gate.operator, gate.value)
    end,
    ["pnc:relationship_state"] = function(context, gate)
        return tostring(context.relationshipState or "")
            == tostring(gate.value or "")
    end,
    ["pnc:audience"] = function(context, gate)
        return context.audiences
            and context.audiences[tostring(gate.value or gate.audience)] == true
            or false
    end,
    ["pnc:time"] = timeMatches,
    ["pnc:history"] = historyMatches,
    ["pnc:base_not_established"] = function(context)
        return context.baseEstablished ~= true
    end,
}

for id, evaluate in pairs(BUILTINS) do
    if not Registry.conditionHandlers[id] then
        Registry.RegisterConditionHandler(id, { evaluate = evaluate, builtin = true })
    end
end

local function noEffectValidate(_, effect)
    return type(effect) == "table", "invalid_effect"
end

local function noEffectApply()
    return true, "no_effect"
end

local DERIVED_RELATIONSHIP_FIELDS = {
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

local RELATIONSHIP_EFFECT_FIELDS = {
    type = true,
    approval = true,
    respect = true,
    familiarity = true,
    decayPerDay = true,
    permanent = true,
    shareable = true,
}

local function validateRelationshipDeltas(effect, strict)
    if type(effect) ~= "table" then return false, "invalid_effect" end
    for key in pairs(effect) do
        local normalized = type(key) == "string" and string.lower(key) or key
        if DERIVED_RELATIONSHIP_FIELDS[normalized] then
            return false, "derived_relationship_effect_forbidden"
        end
        if strict and RELATIONSHIP_EFFECT_FIELDS[key] ~= true then
            return false, "unknown_relationship_effect_field"
        end
    end
    for _, key in ipairs({ "approval", "respect", "familiarity" }) do
        local raw = effect[key]
        local value = raw ~= nil and tonumber(raw) or 0
        if raw ~= nil and (value == nil or value ~= value) then
            return false, "relationship_delta_not_numeric"
        end
        if value < -100 or value > 100 then
            return false, "relationship_delta_out_of_range"
        end
    end
    return true
end

if not Registry.effectHandlers["pnc:none"] then
    Registry.RegisterEffectHandler("pnc:none", {
        validate = noEffectValidate,
        apply = noEffectApply,
        simulate = function() return {} end,
        builtin = true,
    })
end

if not Registry.effectHandlers["pnc:relationship"] then
    Registry.RegisterEffectHandler("pnc:relationship", {
        validate = function(context, effect)
            if not context.npcID or not context.playerEntityKey then
                return false, "relationship_context_unavailable"
            end
            return validateRelationshipDeltas(effect, true)
        end,
        apply = function(context, effect)
            local commands = personalRelationshipCommands()
            if not commands or not commands.ApplyConversationEffect
            then return false, "relationship_service_unavailable" end
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

if not Registry.effectHandlers["pnc:ceasefire"] then
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

if not Registry.effectHandlers["pnc:memory"] then
    Registry.RegisterEffectHandler("pnc:memory", {
        validate = function(context, effect)
            if not context.npcID or not context.playerEntityKey then
                return false, "relationship_context_unavailable"
            end
            local deltasValid, deltaReason = validateRelationshipDeltas(effect)
            if not deltasValid then return false, deltaReason end
            if effect.familiarity ~= nil then
                return false, "memory_familiarity_effect_forbidden"
            end
            if type(effect.memoryID) ~= "string" or effect.memoryID == ""
                or type(effect.memoryType) ~= "string" or effect.memoryType == ""
            then return false, "memory_identity_required" end
            return true
        end,
        apply = function(context, effect)
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
        end,
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

if not Registry.effectHandlers["pnc:knowledge_disclosure"] then
    Registry.RegisterEffectHandler("pnc:knowledge_disclosure", {
        validate = function(context, effect)
            if not context.characterUUID or not context.npcID then
                return false, "knowledge_context_unavailable"
            end
            if type(effect.descriptorID) ~= "string"
                or effect.descriptorID == ""
            then return false, "descriptor_id_required" end
            if not PNC.NPCKnowledge or not PNC.NPCKnowledge.CanDisclose then
                return false, "knowledge_service_unavailable"
            end
            return PNC.NPCKnowledge.CanDisclose(
                context.characterUUID,
                context.npcID,
                effect.descriptorID
            )
        end,
        apply = function(context, effect)
            if not PNC.NPCKnowledge or not PNC.NPCKnowledge.Disclose then
                return false, "knowledge_service_unavailable"
            end
            local result, reason = PNC.NPCKnowledge.Disclose(
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
        end,
        simulate = function(_, effect)
            return { knowledgeDisclosure = effect.descriptorID }
        end,
        builtin = true,
    })
end

if not Registry.effectHandlers["pnc:open_territory_claim"] then
    Registry.RegisterEffectHandler("pnc:open_territory_claim", {
        validate = function(context)
            return context.baseEstablished ~= true
                and context.audiences and context.audiences.member == true,
                "territory_claim_unavailable"
        end,
        apply = function()
            return true, "territory_claim_ready", { openClaim = true }
        end,
        simulate = function() return { openClaim = true } end,
        builtin = true,
    })
end

local function invokeCondition(handler, context, gate)
    if handler.builtin == true then
        return handler.evaluate(context, gate)
    end
    -- A registered addon callback is an unavoidable external failure boundary.
    -- Ordinary validation has already rejected unsafe block data.
    local ok, passed, reason = pcall(handler.evaluate, context, gate)
    if not ok then return false, "condition_handler_error" end
    return passed == true, reason
end

function Rules.EvaluateGate(gate, context)
    if type(gate) ~= "table" then return false, "invalid_gate" end
    if gate.type == "all" then
        return Rules.EvaluateAll(gate.gates, context)
    end
    if gate.type == "any" then
        local reason = gate.reasonKey or "no_gate_matched"
        for _, child in ipairs(gate.gates or {}) do
            local passed = Rules.EvaluateGate(child, context)
            if passed then return true end
        end
        return false, reason
    end
    if gate.type == "not" then
        local passed = Rules.EvaluateGate(gate.gate, context)
        return not passed, gate.reasonKey
    end
    local handler = Registry.conditionHandlers[gate.type]
    if not handler then return false, "unknown_condition" end
    local passed, reason = invokeCondition(handler, context or {}, gate)
    if passed then return true end
    return false, gate.reasonKey or reason or "gate_failed"
end

function Rules.EvaluateAll(gates, context)
    for _, gate in ipairs(gates or {}) do
        local passed, reason = Rules.EvaluateGate(gate, context)
        if not passed then return false, reason, gate end
    end
    return true
end

function Rules.MatchesAudience(block, context)
    for _, audience in ipairs(block and block.audiences or {}) do
        if context and context.audiences and context.audiences[audience] == true then
            return true
        end
    end
    return false
end

function Rules.CheckRepeat(policy, entry, worldAgeHours)
    if type(policy) ~= "table" then return true end
    entry = type(entry) == "table" and entry or {}
    if policy.oncePerDay == true and entry.lastUsedWorldHour ~= nil
        and math.floor((tonumber(entry.lastUsedWorldHour) or 0) / 24)
            == math.floor((tonumber(worldAgeHours) or 0) / 24)
    then return false, "once_per_day_used" end
    if policy.maxUses ~= nil
        and (tonumber(entry.useCount) or 0) >= tonumber(policy.maxUses)
    then return false, "max_uses_reached" end
    if policy.cooldownHours ~= nil and entry.lastUsedWorldHour ~= nil
        and (tonumber(worldAgeHours) or 0)
            < tonumber(entry.lastUsedWorldHour) + tonumber(policy.cooldownHours)
    then return false, "cooldown_active" end
    return true
end

function Rules.ValidateEffects(effects, context)
    for _, effect in ipairs(effects or {}) do
        local handler = Registry.effectHandlers[effect.type]
        if not handler then return false, "unknown_effect" end
        local ok, reason
        if handler.builtin == true then
            ok, reason = handler.validate(context, effect)
        else
            -- Addon effect validation is isolated at the external callback boundary.
            local called
            called, ok, reason = pcall(handler.validate, context, effect)
            if not called then return false, "effect_handler_error" end
        end
        if ok ~= true then return false, reason or "effect_rejected" end
    end
    return true
end

function Rules.ApplyEffects(effects, context)
    local results = {}
    for _, effect in ipairs(effects or {}) do
        local handler = Registry.effectHandlers[effect.type]
        local ok, reason, result
        if handler.builtin == true then
            ok, reason, result = handler.apply(context, effect)
        else
            -- Addon effect application is isolated at the external callback boundary.
            local called
            called, ok, reason, result = pcall(handler.apply, context, effect)
            if not called then return false, "effect_handler_error" end
        end
        if ok ~= true then return false, reason or "effect_failed", result end
        results[#results + 1] = {
            type = effect.type,
            result = result,
        }
    end
    return true, "applied", results
end

function Rules.SimulateEffects(effects, context)
    local output = {}
    for _, effect in ipairs(effects or {}) do
        local handler = Registry.effectHandlers[effect.type]
        if handler and handler.simulate then
            local result
            if handler.builtin == true then
                result = handler.simulate(context or {}, effect)
            else
                -- Debug simulation also crosses an addon-owned callback boundary.
                local ok
                ok, result = pcall(handler.simulate, context or {}, effect)
                if not ok then result = { error = "effect_handler_error" } end
            end
            output[#output + 1] = result
        end
    end
    return output
end

return Rules
