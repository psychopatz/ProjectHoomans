-- Immersive branching for "Tell me about yourself", relationship-gated
-- identity refusals, and repeat-ask annoyance when the player keeps asking
-- for facts the NPC already disclosed.

local RepeatAsk = {}

local function counterStore(context, state)
    local container = (type(context) == "table" and (
        context.semanticContextState
        or context.semanticDialogueContext
        or context
    )) or (type(state) == "table" and state) or nil
    if type(container) ~= "table" then return nil end
    container.knownFacetAskCounts = type(container.knownFacetAskCounts) == "table"
        and container.knownFacetAskCounts or {}
    return container.knownFacetAskCounts
end

local function socialTone(context)
    local personality = type(context) == "table" and context.npcPersonality or nil
    local style = type(personality) == "table"
        and string.lower(tostring(personality.socialStyle or "")) or ""
    if style == "friendly" or style == "protective" then return "warm" end
    if style == "withdrawn" or style == "cautious" or style == "hostile" then
        return "guarded"
    end
    local actor = type(context) == "table" and context.actorConversationContext or nil
    local rel = actor and type(actor.relationship) == "table" and actor.relationship
        or (type(context) == "table" and type(context.relationship) == "table"
            and context.relationship) or nil
    local familiarity = rel and (tonumber(rel.familiarity) or tonumber(rel.trust)) or 0
    if familiarity >= 45 then return "warm" end
    if familiarity < 15 then return "guarded" end
    return "neutral"
end

function RepeatAsk.ResolveAboutYou(ir, state, context)
    local tone = socialTone(context)
    local fallback
    if tone == "warm" then
        fallback = "Sure thing — what do you want to know about me?"
    elseif tone == "guarded" then
        fallback = "Depends on what you're asking. What about me?"
    else
        fallback = "What do you want to know about me?"
    end
    return {
        templateID = "semantic.question.about_you." .. tone,
        fallback = fallback,
        dialogueAct = "PROMPT",
        topic = "about_you",
        tone = tone,
        selectionSource = "about_you_hub",
    }
end

function RepeatAsk.ResolveRelationshipGate(facetKey, minFamiliarity, context)
    local tone = socialTone(context)
    local fallback
    if facetKey == "faction" then
        fallback = tone == "guarded"
            and "I don't hand out who I run with to someone I barely know."
            or "We haven't known each other long enough for me to get into who I'm with."
    elseif facetKey == "surname" then
        fallback = tone == "guarded"
            and "First name's enough for now. We're not that close."
            or "Let's stick to first names until we know each other a bit better."
    else
        fallback = tone == "guarded"
            and "That's personal. We're not there yet."
            or "I'm not ready to get into that yet — maybe once we know each other better."
    end
    return {
        templateID = "semantic.question.about_you.gated." .. tostring(facetKey or "personal"),
        fallback = fallback,
        dialogueAct = "REFUSAL",
        topic = "about_you",
        uncertainty = "gated",
        tone = "guarded",
        minFamiliarity = minFamiliarity,
        selectionSource = "about_you_relationship_gate",
    }
end

function RepeatAsk.BumpCount(facetKey, context, state)
    local store = counterStore(context, state)
    local key = tostring(facetKey or "identity")
    if not store then return 1 end
    local nextCount = (tonumber(store[key]) or 0) + 1
    store[key] = nextCount
    return nextCount
end

function RepeatAsk.BuildKnownRepeatResponse(facetKey, displayValue, context, state)
    local count = RepeatAsk.BumpCount(facetKey, context, state)
    local value = tostring(displayValue or "")
    local tone = "direct"
    local fallback

    if count == 1 then
        tone = "direct"
        if facetKey == "identity" then
            fallback = "I already told you — it's " .. value .. ". Everything alright?"
        elseif facetKey == "faction" then
            fallback = "I told you before, I'm with " .. value .. "."
        elseif facetKey == "surname" then
            fallback = "Already told you — my surname is " .. value .. "."
        elseif facetKey == "nickname" then
            fallback = "I already said most people call me " .. value .. "."
        else
            fallback = "I told you already — " .. value .. "."
        end
    elseif count == 2 then
        tone = "pointed"
        if facetKey == "identity" then
            fallback = "Seriously? It's " .. value .. ". You already asked me that."
        elseif facetKey == "faction" then
            fallback = "You've asked me twice now — " .. value .. ". Are you even listening?"
        elseif facetKey == "surname" then
            fallback = "Again? It's " .. value .. ". Try to keep up."
        elseif facetKey == "nickname" then
            fallback = "Still " .. value .. ". You just asked me that."
        else
            fallback = "You already asked me that. " .. value .. "."
        end
    else
        tone = "annoyed"
        if facetKey == "identity" then
            fallback = "You don't even remember my name, do you? It's " .. value .. ". Stop asking."
        elseif facetKey == "faction" then
            fallback = "How many times are you going to ask? " .. value .. ". Drop it already."
        elseif facetKey == "surname" then
            fallback = "Do you remember anything I tell you? It's " .. value .. ". I'm not saying it again."
        elseif facetKey == "nickname" then
            fallback = "Forget it — if you can't remember " .. value .. " by now, stop asking."
        else
            fallback = "Do you even remember anything I tell you? I'm not repeating myself again."
        end
    end

    return {
        templateID = "semantic.question.known_repeat." .. tostring(facetKey) .. "." .. tone,
        fallback = fallback,
        dialogueAct = "FACT_ANSWER",
        topic = tostring(facetKey),
        uncertainty = "known",
        tone = tone,
        repeatCount = count,
        selectionSource = "known_facet_repeat_branch",
    }
end

return RepeatAsk
