-- Identity-exchange candidate projection and context checks.

local function identityKnown(context)
    context = type(context) == "table" and context or {}
    if context.identityState == "known"
        or context.identityKnown == true
    then
        return true
    end
    local actor = type(context.actorConversationContext) == "table"
        and context.actorConversationContext or {}
    local roles = type(actor.roles) == "table" and actor.roles or {}
    return roles.companion == true and roles.owned == true
        and roles.authorityEligible == true
end

local function identityFacetKnown(context, facet)
    context = type(context) == "table" and context or {}
    local knowledge = type(context.npcKnowledge) == "table"
        and context.npcKnowledge or {}
    local identity = type(knowledge.identity) == "table"
        and knowledge.identity or {}
    local value = identity[facet]
    if facet == "nickname" then
        value = value or knowledge.knownNickname
    elseif facet == "surname" then
        value = value or knowledge.knownSurname
    elseif facet == "factionName" then
        value = value or knowledge.factionName or knowledge.factionID
        if not value and knowledge.factionKnown == true then
            return true
        end
    end
    return value ~= nil and tostring(value) ~= ""
end

local function pendingIdentity(context)
    local state = context and context.semanticContextState
    return context and context.pendingIdentityExchange
        or state and state.pendingIdentityExchange
        or context and context.semanticDialogueContext
        and context.semanticDialogueContext.pendingIdentityExchange
end

local function trimText(value)
    return string.gsub(tostring(value or ""), "^%s*(.-)%s*$", "%1")
end

local function activeLanguage()
    local manager = CustomTranslationManager
        or (PsychopatzCore and PsychopatzCore.CustomTranslationManager)
    if type(manager) == "table" and type(manager.getLanguage) == "function" then
        local ok, lang = pcall(manager.getLanguage)
        if ok and type(lang) == "string" and lang ~= "" then
            return string.upper(lang)
        end
    end
    if Translator and type(Translator.getLanguage) == "function" then
        local lang = Translator.getLanguage()
        if lang and type(lang.toString) == "function" then
            return string.upper(tostring(lang:toString()))
        end
    end
    return "EN"
end

local function composeDescriptorName(forename, surname)
    forename = trimText(forename)
    surname = trimText(surname)
    if forename == "" and surname == "" then return "" end
    if forename ~= "" and surname ~= "" then
        return forename .. " " .. surname
    end
    return forename ~= "" and forename or surname
end

local function canonicalPlayerName(context)
    context = type(context) == "table" and context or {}
    for _, key in ipairs({ "canonicalPlayerName", "playerCanonicalName" }) do
        local candidate = trimText(context[key])
        if candidate ~= "" then return candidate end
    end
    local player = context.player
    if type(player) == "table" then
        local display = trimText(player.displayName or player.fullName)
        if display ~= "" then return display end
        local composed = composeDescriptorName(player.forename, player.surname)
        if composed ~= "" then return composed end
    elseif player ~= nil then
        if type(player.getDescriptor) == "function" then
            local descriptor = player:getDescriptor()
            if descriptor then
                local forename = type(descriptor.getForename) == "function"
                    and descriptor:getForename() or nil
                local surname = type(descriptor.getSurname) == "function"
                    and descriptor:getSurname() or nil
                local composed = composeDescriptorName(forename, surname)
                if composed ~= "" then return composed end
            end
        end
        if type(player.getDisplayName) == "function" then
            local display = trimText(player:getDisplayName())
            if display ~= "" then return display end
        end
    end
    return trimText(context.playerName)
end

local function resolveIdentitySeed(context, choice, claimedName)
    local explicit = trimText(context.realizationSeed or context.seed)
    if explicit ~= "" then
        return explicit .. ":" .. tostring(choice or "")
    end
    local result = type(context.dialogueResult) == "table"
        and context.dialogueResult or nil
    local state = result and type(result.state) == "table" and result.state
        or (type(context.semanticDialogueState) == "table"
            and context.semanticDialogueState or nil)
    local turnToken = context.sequence
        or (result and result.sequence)
        or (state and state.sequence)
        or context.revision
        or context.turn
        or context.requestRevision
        or 0
    return table.concat({
        tostring(context.conversationID or ""),
        tostring(turnToken),
        tostring(context.characterUUID or context.playerIdentitySeed or ""),
        tostring(context.saveSeed or ""),
        tostring(choice or ""),
        tostring(claimedName or ""),
    }, ":")
end

local function loadIdentityPlan(familyID)
    local registry = PNC and PNC.ConvoEngine and PNC.ConvoEngine.Registry
    if type(registry) ~= "table" or type(registry.CONVO_PLANS) ~= "table" then
        registry = require "PNC/ConvoEngine/Registry"
    end
    local plan = registry and registry.CONVO_PLANS and registry.CONVO_PLANS[familyID]
    if type(plan) == "table" then
        return plan
    end
    local plans = require "PNC/ConvoEngine/Dialogue/StaticSuggestionText"
    if type(plans) == "table" then
        for _, item in ipairs(plans) do
            if type(item) == "table" and item.id == familyID then
                return item
            end
        end
    end
    return nil
end

local function realizeIdentityChoiceText(familyID, slotValue, context, choice, claimedName)
    local plan = loadIdentityPlan(familyID)
    if type(plan) ~= "table" then
        return nil, nil, "identity_plan_missing"
    end
    local affordance = PsychopatzCore and PsychopatzCore.ConvoEngine
        and PsychopatzCore.ConvoEngine.Affordance
        or require "PsychopatzCore/ConvoEngine/Affordance"
    local slotContext = slotValue and {
        slot = {
            identity_claim = slotValue,
            identityClaim = slotValue,
        },
    } or {}
    local options = {
        seed = resolveIdentitySeed(context, choice, claimedName),
        index = tonumber(context.identityRealizationIndex or context.realizationIndex),
        language = context.language or activeLanguage(),
    }
    local labelText = affordance.RenderRoleText(plan, "button_label", slotContext, options)
    local enLabelText = options.language == "EN" and labelText
        or affordance.RenderRoleText(plan, "button_label", slotContext, {
            seed = options.seed,
            index = options.index,
            language = "EN",
        })
    local speechText, speechErr = affordance.RenderRoleText(
        plan, "spoken_action", slotContext, options
    )
    if type(speechText) ~= "string" or trimText(speechText) == "" then
        return nil, labelText, speechErr or "initiating_say_missing", enLabelText
    end
    return speechText, labelText, nil, enLabelText
end

local function identityChoiceCandidate(
    Provider, id, labelKey, labelFallback, utteranceKey, utteranceFallback,
    choice, frame, labelDisplay
)
    return {
        id = id,
        topic = "identity",
        groupID = "topic:identity",
        providerID = Provider.id,
        rank = choice,
        semanticOwner = "projecthoomans.semantic.identity",
        eligibility = {
            status = "allowed",
            allowed = true,
            reason = "identity_exchange_pending",
        },
        source = {
            kind = Provider.sourceKind,
            providerID = Provider.id,
            reason = "identity_exchange_pending",
        },
        frame = frame,
        display = {
            labelKey = labelKey,
            labelFallback = labelFallback,
            label = labelDisplay or labelFallback,
            utteranceKey = utteranceKey,
            utteranceFallback = utteranceFallback,
            utterance = utteranceFallback,
        },
        visibility = "player",
    }
end

local function buildIdentityOption(Provider, context, spec)
    local slotValue = spec.claimMode and {
        mode = spec.claimMode,
        name = spec.claimedName,
    } or nil
    local speechText, realizedLabel, _err, enLabel = realizeIdentityChoiceText(
        spec.familyID, slotValue, context, spec.choice, spec.claimedName
    )
    if type(speechText) ~= "string" or trimText(speechText) == "" then
        return nil
    end
    local labelFallback = (type(enLabel) == "string" and trimText(enLabel) ~= "")
        and enLabel or spec.fallbackLabel
    local labelDisplay = (type(realizedLabel) == "string" and trimText(realizedLabel) ~= "")
        and realizedLabel or labelFallback
    local socialContext = {}
    if spec.intent == "INFORM" then socialContext.identityClaim = true end
    local frame = {
        kind = "semantic_click_frame",
        candidateID = spec.id,
        topic = "identity",
        pattern = "pnc.identity.choice." .. spec.choice,
        intent = spec.intent,
        speechAct = spec.intent,
        subject = "IDENTITY",
        slots = slotValue and {
            identityClaim = {
                mode = spec.claimMode,
                name = spec.claimedName,
            },
        } or {},
        socialContext = socialContext,
        extensions = {
            route = "semantic_provider",
            providerID = Provider.id,
            identityChoice = spec.choice,
            identityClaimMode = spec.claimMode,
            identityResponseStyle = spec.responseStyle,
            realizationFamilyID = spec.familyID,
        },
        textKey = nil,
        textFallback = speechText,
        utteranceFallback = speechText,
        utterance = speechText,
        labelKey = spec.labelKey,
        labelFallback = labelFallback,
    }
    return identityChoiceCandidate(
        Provider,
        spec.id,
        spec.labelKey,
        labelFallback,
        nil,
        speechText,
        spec.rank,
        frame,
        labelDisplay
    )
end

local function identityChoiceCandidates(context, Provider, IdentityAlias)
    context = type(context) == "table" and context or {}
    local playerName = canonicalPlayerName(context)
    local source = {
        characterUUID = context.characterUUID
            or context.playerIdentitySeed,
        gender = context.playerGender,
        playerName = playerName ~= "" and playerName or nil,
        saveSeed = context.saveSeed,
    }
    local alias = "Alex Reed"
    if IdentityAlias and type(IdentityAlias.Generate) == "function" then
        local ok, generated = pcall(IdentityAlias.Generate, source)
        if ok and tostring(generated or "") ~= "" then
            alias = tostring(generated)
        end
    end
    local specs = {
        {
            id = "identity.choice.real_name",
            familyID = "ui.suggestion.identity.real",
            intent = "INFORM",
            choice = "real_name",
            claimMode = "canonical",
            claimedName = source.playerName,
            responseStyle = nil,
            labelKey = "UI_PNC_Conversation_Suggestion_Identity_Real_Label",
            fallbackLabel = "Say your real name",
            rank = 10,
        },
        {
            id = "identity.choice.refuse_name",
            familyID = "ui.suggestion.identity.rude",
            intent = "REFUSE",
            choice = "refuse_name",
            claimMode = nil,
            claimedName = nil,
            responseStyle = "rude",
            labelKey = "UI_PNC_Conversation_Suggestion_Identity_Rude_Label",
            fallbackLabel = "Don't tell your name",
            rank = 20,
        },
        {
            id = "identity.choice.lie_name",
            familyID = "ui.suggestion.identity.lie",
            intent = "INFORM",
            choice = "lie_name",
            claimMode = "generated",
            claimedName = alias,
            responseStyle = nil,
            labelKey = "UI_PNC_Conversation_Suggestion_Identity_Lie_Label",
            fallbackLabel = "Lie about your name",
            rank = 30,
        },
    }
    local candidates = {}
    for _, spec in ipairs(specs) do
        if spec.claimMode == nil or (type(spec.claimedName) == "string" and trimText(spec.claimedName) ~= "") then
            local candidate = buildIdentityOption(Provider, context, spec)
            if candidate then
                candidates[#candidates + 1] = candidate
            end
        end
    end
    return candidates
end

return {
    identityKnown = identityKnown,
    identityFacetKnown = identityFacetKnown,
    pendingIdentity = pendingIdentity,
    identityChoiceCandidates = identityChoiceCandidates,
}
