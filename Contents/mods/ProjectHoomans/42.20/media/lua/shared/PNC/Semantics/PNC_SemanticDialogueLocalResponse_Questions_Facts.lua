-- Deterministic fact-backed question responses.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Response = PNC.Semantics.LocalResponse
local Internal = Response and Response.Internal or {}
Response.Internal = Internal
local copyArgs = Internal.CopyArgs
local catalogResponse = Internal.CatalogResponse
local factFor = Internal.FactFor

local function resolveMedicalBiteStatus(ir, state, context)
    local fact = factFor(ir)
    local poolID = "semantic.question.medical_bite.unknown"
    if fact and fact.status == "known" then
        if fact.value == true then
            poolID = "semantic.question.medical_bite.positive"
        elseif fact.value == false then
            poolID = "semantic.question.medical_bite.negative"
        end
    end
    return catalogResponse(poolID, ir, state, context, {
        factStatus = fact and fact.status or "unknown",
        factProvider = fact and fact.provider,
        factRef = fact and fact.factRef,
    })
end

local function factTopic(ir, fact)
    local target = ir and ir.target
    local slot = ir and ir.slots and ir.slots.topic
    local value = fact and fact.topic
        or type(target) == "table" and (target.text or target.value)
        or target
        or type(slot) == "table" and (slot.text or slot.value)
        or slot
    value = tostring(value or "")
    return value ~= "" and value or "that"
end

local function factResponse(templateID, poolID, fact, topic, refs)
    return {
        templateID = templateID,
        sourcePoolID = poolID,
        dialogueAct = "FACT_ANSWER",
        topic = topic,
        groundedFactRefs = refs or {},
        uncertainty = fact and fact.status == "known" and "known"
            or "unknown",
        tone = "direct",
        selectionSource = "fact_provider",
        referenceTopic = topic,
    }
end

local function resolveResidenceQuestion(ir, state, context)
    local fact = factFor(ir)
    local value = fact and fact.value
    local label = type(value) == "table" and value.label or nil
    if fact and fact.status == "known" and label then
        return {
            templateID = "semantic.question.residence.known",
            args = copyArgs({ location = label }),
            sourcePoolID = "semantic.question.residence",
            dialogueAct = "FACT_ANSWER",
            topic = "RESIDENCE",
            groundedFactRefs = { "npc.residence" },
            uncertainty = "known",
            tone = "direct",
            selectionSource = "fact_provider",
        }
    end
    return factResponse(
        "semantic.question.residence.unknown",
        "semantic.question.residence",
        fact,
        "RESIDENCE"
    )
end

local function resolveHealthStateQuestion(ir, state, context)
    local fact = factFor(ir)
    local value = tostring(fact and fact.value or "")
    local templateID
    if fact and fact.status == "known" then
        if value == "injured" or value == "wounded" or value == "critical" then
            templateID = "semantic.question.health_state.injured"
        elseif value == "healthy" or value == "normal" then
            templateID = "semantic.question.health_state.healthy"
        end
        if templateID then
            return factResponse(
                templateID,
                "semantic.question.health_state",
                fact,
                "MEDICAL",
                { "npc.healthState" }
            )
        end
    end
    return factResponse(
        "semantic.question.health_state.unknown",
        "semantic.question.health_state",
        fact,
        "MEDICAL"
    )
end

local function resolveKnowledgeQuestion(ir, state, context)
    local fact = factFor(ir)
    local topic = factTopic(ir, fact)
    if fact and fact.status == "known" and fact.value == true then
        local answer = tostring(fact.answer or "")
        local response = factResponse(
            "semantic.question.knowledge.known",
            "semantic.question.knowledge",
            fact,
            "KNOWLEDGE",
            { "npc.knowledge.topic" }
        )
        response.args = copyArgs({
            topic = answer ~= ""
                and (topic .. ". " .. string.gsub(answer, "[%s%.!?]+$", ""))
                or topic,
        })
        response.referenceTopic = topic
        return response
    end
    local response = factResponse(
        "semantic.question.knowledge.unknown",
        "semantic.question.knowledge",
        fact,
        "KNOWLEDGE"
    )
    response.args = copyArgs({ topic = topic })
    return response
end

local function resolveBackstoryQuestion(ir, state, context)
    local fact = factFor(ir)
    local content = fact and (fact.content or fact.value) or nil
    local kind = fact and fact.kind
        or ir and ir.slots and ir.slots.backstoryKind or "backstory"
    local refs = fact and fact.factID and { fact.factID } or {}
    local response
    if fact and fact.status == "known"
        and type(content) == "string" and content ~= ""
    then
        local extensions = ir and type(ir.extensions) == "table"
            and ir.extensions or {}
        local authoredPool = extensions.responsePoolID
        local responseArgs = {
            kind = kind,
            content = content,
        }
        -- A generated interaction may supply its reviewed response pool. Use
        -- it only after the fact provider has returned an authorized known
        -- value; refusal and suspected branches retain their safe catalog
        -- responses and cannot turn an authored template into disclosure.
        if type(authoredPool) == "string" and authoredPool ~= "" then
            response = catalogResponse(
                authoredPool, ir, state, context, responseArgs
            )
        end
        local generatedPool = "semantic.question.backstory.known." .. tostring(kind)
        if not response then response = catalogResponse(
            generatedPool, ir, state, context, responseArgs
        ) end
        if not response then
            response = catalogResponse(
                "semantic.question.backstory.known", ir, state, context,
                responseArgs
            )
        end
        if response then
            response.dialogueAct = "FACT_ANSWER"
            response.topic = "NPC_BACKSTORY"
            response.groundedFactRefs = refs
            response.uncertainty = "known"
            response.tone = "direct"
            response.selectionSource = "fact_provider_catalog"
            return response
        end
        response = factResponse(
            "semantic.question.backstory.known",
            "semantic.question.backstory",
            fact,
            "NPC_BACKSTORY",
            refs
        )
        response.args = copyArgs({ kind = kind, content = content })
        return response
    end
    if fact and fact.status == "suspected"
        and type(content) == "string" and content ~= ""
    then
        response = catalogResponse(
            "semantic.question.backstory.suspected", ir, state, context, {
                kind = kind,
                content = content,
            }
        )
        if response then
            response.dialogueAct = "FACT_ANSWER"
            response.topic = "NPC_BACKSTORY"
            response.groundedFactRefs = refs
            response.uncertainty = "suspected"
            response.tone = "direct"
            response.selectionSource = "fact_provider_catalog"
            return response
        end
        response = factResponse(
            "semantic.question.backstory.suspected",
            "semantic.question.backstory",
            fact,
            "NPC_BACKSTORY",
            refs
        )
        response.uncertainty = "suspected"
        response.args = copyArgs({ kind = kind, content = content })
        return response
    end
    if fact and fact.status == "ambiguous" then
        response = catalogResponse(
            "semantic.question.backstory.ambiguous", ir, state, context
        )
        if response then
            response.dialogueAct = "FACT_ANSWER"
            response.topic = "NPC_BACKSTORY"
            response.uncertainty = "ambiguous"
            response.tone = "cautious"
            response.selectionSource = "fact_provider_catalog"
            return response
        end
        return factResponse(
            "semantic.question.backstory.ambiguous",
            "semantic.question.backstory",
            fact,
            "NPC_BACKSTORY"
        )
    end
    response = catalogResponse(
        "semantic.question.backstory.refusal", ir, state, context
    )
    if response then
        response.dialogueAct = "FACT_ANSWER"
        response.topic = "NPC_BACKSTORY"
        response.uncertainty = "pending"
        response.tone = "guarded"
        response.selectionSource = "fact_provider_catalog"
        return response
    end
    return factResponse(
        "semantic.question.backstory.refusal",
        "semantic.question.backstory",
        fact,
        "NPC_BACKSTORY"
    )
end

Internal.ResolveMedicalBiteStatus = resolveMedicalBiteStatus
Internal.FactTopic = factTopic
Internal.FactResponse = factResponse
Internal.ResolveResidenceQuestion = resolveResidenceQuestion
Internal.ResolveHealthStateQuestion = resolveHealthStateQuestion
Internal.ResolveKnowledgeQuestion = resolveKnowledgeQuestion
Internal.ResolveBackstoryQuestion = resolveBackstoryQuestion

return Response
