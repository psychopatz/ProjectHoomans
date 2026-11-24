-- Immersive branching for "Tell me about yourself", relationship-gated
-- identity refusals, and repeat-ask annoyance when the player keeps asking
-- for facts the NPC already disclosed.
-- All authored prose lives in repeat_ask_and_about_you.convo (ConvoDSL).

local RepeatAsk = {}

local function getCatalog()
    local catalog = PNC and PNC.ConvoEngine and PNC.ConvoEngine.ResponseCatalog or nil
    if type(catalog) ~= "table" then
        local loaded = require "PNC/ConvoEngine/Dialogue/ResponseCatalog"
        catalog = type(loaded) == "table" and loaded or nil
    end
    return catalog
end

local function getLexicon()
    local lex = PNC and PNC.ConvoEngine and PNC.ConvoEngine.Lexicon or nil
    if type(lex) ~= "table" then
        local loaded = require "PNC/ConvoEngine/Lexicon"
        lex = type(loaded) == "table" and loaded or nil
    end
    return lex
end

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

local function resolveSocialStyle(context)
    local personality = type(context) == "table" and context.npcPersonality or nil
    local style = type(personality) == "table"
        and string.lower(tostring(personality.socialStyle or "")) or ""
    if style == "friendly" or style == "protective" then return style, "warm" end
    if style == "withdrawn" or style == "guarded" or style == "hostile" then
        return style, "guarded"
    end
    if style == "cautious" then return "guarded", "guarded" end
    local actor = type(context) == "table" and context.actorConversationContext or nil
    local rel = actor and type(actor.relationship) == "table" and actor.relationship
        or (type(context) == "table" and type(context.relationship) == "table"
            and context.relationship) or nil
    local familiarity = rel and (tonumber(rel.familiarity) or tonumber(rel.trust)) or 0
    if familiarity >= 45 then return "friendly", "warm" end
    if familiarity < 15 then return "guarded", "guarded" end
    return "neutral", "neutral"
end

local function selectPool(poolID, selCtx, tokens, salt)
    local catalog = getCatalog()
    if not catalog or type(catalog.Select) ~= "function" then return nil end
    local selected = catalog.Select(poolID, selCtx, salt)
    if type(selected) ~= "table" then return nil end
    local text = selected.fallback
    if type(text) == "string" and string.find(text, "{", 1, true) then
        local lex = getLexicon()
        if lex and type(lex.Expand) == "function" then
            text = lex.Expand(text, selCtx, tokens, { salt = salt })
        end
    end
    return selected, text
end

function RepeatAsk.ResolveAboutYou(ir, state, context)
    local style, tone = resolveSocialStyle(context)
    local salt = tostring(state and state.sequence or 0) .. ":about_you"
    local selected, text = selectPool(
        "semantic.question.about_you",
        {
            npcID = type(context) == "table" and context.npcID or nil,
            socialStyle = style,
        },
        nil,
        salt
    )
    return {
        templateID = selected and selected.templateID or ("semantic.question.about_you." .. tone),
        fallback = text,
        sourcePoolID = "semantic.question.about_you",
        dialogueAct = "PROMPT",
        topic = "about_you",
        tone = tone,
        selectionSource = "catalog",
        selectionID = selected and selected.id or nil,
    }
end

function RepeatAsk.ResolveRelationshipGate(facetKey, minFamiliarity, context)
    local style = resolveSocialStyle(context)
    local key = tostring(facetKey or "personal")
    local selected, text = selectPool(
        "semantic.question.about_you.gated",
        {
            npcID = type(context) == "table" and context.npcID or nil,
            socialStyle = style,
            topic = key,
        },
        nil,
        "about_you_gate:" .. key
    )
    return {
        templateID = selected and selected.templateID or ("semantic.question.about_you.gated." .. key),
        fallback = text,
        sourcePoolID = "semantic.question.about_you.gated",
        dialogueAct = "REFUSAL",
        topic = "about_you",
        uncertainty = "gated",
        tone = "guarded",
        minFamiliarity = minFamiliarity,
        selectionSource = "catalog",
        selectionID = selected and selected.id or nil,
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
    local key = tostring(facetKey or "identity")
    local value = tostring(displayValue or "")
    local tone = count == 1 and "direct" or (count == 2 and "pointed" or "annoyed")
    local tokens = { ["slot.known_value"] = value }
    local selected, text = selectPool(
        "semantic.question.repeat_known",
        {
            npcID = type(context) == "table" and context.npcID or nil,
            topic = key,
            npcAnnoyed = count == 2,
            npcFedUp = count >= 3,
        },
        tokens,
        "repeat_known:" .. key .. ":" .. tostring(count)
    )
    return {
        templateID = selected and selected.templateID or ("semantic.question.repeat_known." .. key .. "." .. tone),
        fallback = text,
        args = tokens,
        sourcePoolID = "semantic.question.repeat_known",
        dialogueAct = "FACT_ANSWER",
        topic = key,
        uncertainty = "known",
        tone = tone,
        repeatCount = count,
        selectionSource = "catalog",
        selectionID = selected and selected.id or nil,
    }
end

return RepeatAsk
