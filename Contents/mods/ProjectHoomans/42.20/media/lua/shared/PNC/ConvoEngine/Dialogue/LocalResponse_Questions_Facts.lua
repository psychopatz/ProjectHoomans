-- Deterministic fact-backed question responses.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Response = PNC.ConvoEngine.LocalResponse
local Internal = Response and Response.Internal or {}
Response.Internal = Internal
local RepeatAsk = require "PNC/ConvoEngine/Dialogue/LocalResponse_RepeatAsk"
local AboutYou = require "PNC/ConvoEngine/Suggestions/AboutYouCatalog"
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

local CORROBORATING_PROVENANCE = {
    experienced = true,
    witnessed = true,
    public = true,
    faction = true,
    environmental = true,
}

local UNCERTAIN_PROVENANCE = {
    radio = true,
    told = true,
    inferred = true,
}

local WORLD_KNOWLEDGE_PROVENANCE = {
    experienced = true,
    witnessed = true,
    public = true,
    faction = true,
    environmental = true,
    radio = true,
    told = true,
    inferred = true,
}

local function resolveEpistemic(fact)
    if type(fact) ~= "table" then return "unknown" end
    local wk = PNC.WorldKnowledge
    local coreWKG = PsychopatzCore and PsychopatzCore.WorldKnowledge
    local ref = type(fact.reference) == "table" and fact.reference or fact
    if wk and type(wk.ResolveEpistemicStatus) == "function" then
        return wk.ResolveEpistemicStatus(fact, ref)
    end
    if coreWKG and type(coreWKG.ResolveEpistemicStatus) == "function" then
        return coreWKG.ResolveEpistemicStatus(fact, ref)
    end
    if fact.corroborated == true or CORROBORATING_PROVENANCE[fact.provenance]
        or (ref and (ref.corroborated == true or CORROBORATING_PROVENANCE[ref.provenance]))
    then
        return "known"
    end
    if UNCERTAIN_PROVENANCE[fact.provenance] or (ref and UNCERTAIN_PROVENANCE[ref.provenance]) then
        return "uncertain"
    end
    return "unknown"
end

local function isWorldKnowledgeFact(fact)
    if type(fact) ~= "table" then return false end
    if fact.epistemicStatus ~= nil or fact.factID ~= nil or type(fact.reference) == "table" then
        return true
    end
    return WORLD_KNOWLEDGE_PROVENANCE[fact.provenance] == true
end

local function factResponse(templateID, fallback, poolID, fact, topic, refs)
    local uncertainty = "unknown"
    if type(fact) == "table" then
        if fact.epistemicStatus == "known" or fact.status == "known" then
            uncertainty = "known"
        elseif fact.epistemicStatus == "uncertain"
            or fact.status == "uncertain"
            or fact.status == "suspected"
        then
            uncertainty = fact.epistemicStatus == "uncertain" and "uncertain" or fact.status
        end
    end
    return {
        templateID = templateID,
        fallback = fallback,
        sourcePoolID = poolID,
        dialogueAct = "FACT_ANSWER",
        topic = topic,
        groundedFactRefs = refs or {},
        uncertainty = uncertainty,
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
            fallback = "I live at " .. tostring(label) .. ".",
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
        "I don't have a confirmed home to tell you about.",
        "semantic.question.residence",
        fact,
        "RESIDENCE"
    )
end

local function resolveHealthStateQuestion(ir, state, context)
    local fact = factFor(ir)
    local value = tostring(fact and fact.value or "")
    local fallback
    local templateID
    if fact and fact.status == "known" then
        if value == "injured" or value == "wounded" or value == "critical" then
            templateID = "question.health_state.injured"
            fallback = "I'm hurt, but I'm managing."
        elseif value == "healthy" or value == "normal" then
            templateID = "question.health_state.healthy"
            fallback = "I'm doing okay."
        end
        if templateID then
            return factResponse(
                templateID,
                fallback,
                "semantic.question.health_state",
                fact,
                "MEDICAL",
                { "npc.healthState" }
            )
        end
    end
    return factResponse(
        "question.health_state.unknown",
        "I can't confirm my health status right now.",
        "semantic.question.health_state",
        fact,
        "MEDICAL"
    )
end

local function worldKnowledgeFactFromContext(topic, context)
    if type(context) ~= "table" then return nil end
    local wk = PNC.WorldKnowledge
    if wk and type(wk.QueryActorFact) == "function"
        and type(context.npcRecord) == "table"
    then
        local queried = wk.QueryActorFact(context.npcRecord, { topic = topic })
        if type(queried) == "table" and queried.fact then
            return {
                status = queried.status,
                epistemicStatus = queried.epistemicStatus,
                provenance = queried.provenance,
                factID = queried.fact.factID,
                reference = queried.reference,
                value = queried.epistemicStatus ~= "unknown",
                answer = queried.summary,
                topic = topic,
            }
        end
    end
    local wkContext = type(context.worldKnowledge) == "table"
        and context.worldKnowledge or nil
    local candidates = wkContext and wkContext.candidates or nil
    if type(candidates) == "table" then
        local wanted = string.lower(tostring(topic or ""))
        for i = 1, #candidates do
            local cand = candidates[i]
            if type(cand) == "table" and cand.factID then
                local fid = string.lower(tostring(cand.factID))
                if wanted == "" or string.find(fid, wanted, 1, true) then
                    return {
                        epistemicStatus = cand.epistemicStatus,
                        provenance = cand.provenance,
                        factID = cand.factID,
                        reference = { provenance = cand.provenance },
                        value = cand.epistemicStatus ~= "unknown",
                        topic = topic,
                    }
                end
            end
        end
    end
    return nil
end

local function resolveKnowledgeQuestion(ir, state, context)
    local fact = factFor(ir)
    local topic = factTopic(ir, fact)
    if not fact then
        fact = worldKnowledgeFactFromContext(topic, context)
    end

    local epistemic = "unknown"
    if type(fact) == "table" then
        if isWorldKnowledgeFact(fact) then
            epistemic = resolveEpistemic(fact)
            if fact.value == false then epistemic = "unknown" end
        elseif fact.status == "known" and fact.value == true then
            epistemic = "known"
        elseif fact.status == "suspected" or fact.status == "uncertain" then
            epistemic = "uncertain"
        end
    end

    local answer = tostring(fact and (fact.answer or fact.summary) or "")
    local refID = (fact and fact.factID) or "npc.knowledge.topic"
    local provenance = fact and (fact.provenance
        or (type(fact.reference) == "table" and fact.reference.provenance))
        or nil

    if epistemic == "known" then
        local prefix = (provenance == "experienced" or provenance == "witnessed")
            and ("I saw it myself regarding " .. topic .. ".")
            or ("I know about " .. topic .. ".")
        local fallback = answer ~= "" and (prefix .. " " .. answer) or prefix
        local response = factResponse(
            "question.knowledge.known",
            fallback,
            "semantic.question.knowledge",
            fact,
            "KNOWLEDGE",
            { refID }
        )
        response.uncertainty = "known"
        response.epistemicStatus = "known"
        response.provenance = provenance
        response.args = copyArgs({
            topic = answer ~= ""
                and (topic .. ". " .. string.gsub(answer, "[%s%.!?]+$", ""))
                or topic,
            ["target.name"] = answer ~= ""
                and (topic .. ". " .. string.gsub(answer, "[%s%.!?]+$", ""))
                or topic,
        })
        response.referenceTopic = topic
        return response
    end

    if epistemic == "uncertain" then
        local fallback = "I only heard a rumor about " .. topic
            .. ", so I can't confirm it."
        if answer ~= "" then fallback = fallback .. " " .. answer end
        local response = factResponse(
            "question.knowledge.uncertain",
            fallback,
            "semantic.question.knowledge",
            fact,
            "KNOWLEDGE",
            { refID }
        )
        response.uncertainty = "uncertain"
        response.epistemicStatus = "uncertain"
        response.provenance = provenance
        response.tone = "cautious"
        response.args = copyArgs({
            topic = topic,
            ["target.name"] = topic,
        })
        response.referenceTopic = topic
        return response
    end

    local response = factResponse(
        "question.knowledge.unknown",
        "I don't have reliable information about " .. topic .. ".",
        "semantic.question.knowledge",
        { status = "unknown" },
        "KNOWLEDGE"
    )
    response.uncertainty = "unknown"
    response.epistemicStatus = "unknown"
    response.args = copyArgs({
        topic = topic,
        ["target.name"] = topic,
    })
    return response
end

local function resolveBackstoryQuestion(ir, state, context)
    local fact = factFor(ir)
    local content = fact and (fact.content or fact.value) or nil
    local kind = fact and fact.kind
        or ir and ir.slots and ir.slots.backstoryKind or "backstory"
    local refs = fact and fact.factID and { fact.factID } or {}
    local response
    local knownFallback = "Before all this, I was "
        .. tostring(content or "someone else") .. "."
    if kind == "hometown" then
        knownFallback = "I grew up in " .. tostring(content or "there") .. "."
    elseif kind == "former_job" then
        knownFallback = "I worked as a "
            .. tostring(content or "something else") .. " before all this."
    elseif kind == "education" then
        knownFallback = "I studied " .. tostring(content or "that") .. "."
    elseif kind == "hobby" then
        knownFallback = "I used to enjoy " .. tostring(content or "that") .. "."
    elseif kind == "family_background" then
        knownFallback = "My family was " .. tostring(content or "like that") .. "."
    elseif kind == "fear" then
        knownFallback = "I have always been afraid of "
            .. tostring(content or "that") .. "."
    elseif kind == "tragedy" then
        knownFallback = "Something happened: "
            .. tostring(content or "I lost people") .. "."
    end
    if fact and fact.status == "known"
        and type(content) == "string" and content ~= ""
    then
        local facetDef = AboutYou.FindByKey("backstory:" .. tostring(kind))
        if facetDef and AboutYou.IsFacetKnown(context, facetDef) then
            local repeatResp = RepeatAsk.BuildKnownRepeatResponse(
                facetDef.facetKey, content, context, state
            )
            repeatResp.topic = "NPC_BACKSTORY"
            repeatResp.groundedFactRefs = refs
            repeatResp.args = copyArgs({ kind = kind, content = content })
            return repeatResp
        end
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
            knownFallback,
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
            "I think it was " .. content .. ", but I could be mistaken.",
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
            "Which part of my past do you mean?",
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
        "I'm not ready to talk about that yet.",
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
