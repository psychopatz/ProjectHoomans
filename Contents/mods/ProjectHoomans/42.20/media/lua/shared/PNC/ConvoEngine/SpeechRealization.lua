-- Shared SpeechRealization registry, resolver, and fallback boundary.
--
-- Built-in phrase content lives in cohesive domain packs. This file owns the
-- one registry and the one application path used by semantic responses.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Realization = PNC.ConvoEngine.SpeechRealization or {}
PNC.ConvoEngine.SpeechRealization = Realization

Realization.VERSION = 1
Realization.MAX_FAMILY_APPLICATIONS = 8

local Style = PNC.ConvoEngine.SpeechStyleContext
    or require "PNC/ConvoEngine/SpeechStyleContext"
local UtterancePlan = PNC.ConvoEngine.UtterancePlan
    or require "PNC/ConvoEngine/UtterancePlan"
local cachedRegistry
do
    local ok, value = pcall(require,
        "PNC/ConvoEngine/Registry")
    if ok and type(value) == "table" then cachedRegistry = value end
end
local function activeRegistry()
    return (PNC and PNC.ConvoEngine and PNC.ConvoEngine.Registry)
        or cachedRegistry
end
local COVERAGE = {
    { family = "greeting", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "wellbeing", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "needs", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "medical", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "identity", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "knowledge", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "acknowledgement", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "apology", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "offer_help", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "dispute_refusal", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "threat_hostility", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "gossip_event", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "companion_action", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "trading_entry", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "quest_commitment", supported = { "neutral", "warm", "terse", "guarded" } },
}

local function copy(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 12 then return nil end
    local output = {}
    local count = 0
    for key, item in pairs(value) do
        if count >= 128 then break end
        if type(key) == "string" or type(key) == "number" then
            output[key] = copy(item, depth + 1)
            count = count + 1
        end
    end
    return output
end

local PHRASE_MAX_HISTORY = 128
local phraseHistory = Realization.phraseHistory or {}
Realization.phraseHistory = phraseHistory
local phraseHistoryOrder = Realization.phraseHistoryOrder or {}
Realization.phraseHistoryOrder = phraseHistoryOrder

function Realization.ResetSelections()
    for key in pairs(phraseHistory) do
        phraseHistory[key] = nil
    end
    for index = #phraseHistoryOrder, 1, -1 do
        phraseHistoryOrder[index] = nil
    end
    return true
end

local function hash(value)
    local output = 0
    value = tostring(value or "")
    for index = 1, #value do
        output = (output * 31 + string.byte(value, index)) % 2147483647
    end
    return output
end

local function phraseActorID(context)
    context = type(context) == "table" and context or {}
    local npc = type(context.npcState) == "table" and context.npcState or {}
    local npcData = type(context.npcData) == "table" and context.npcData or {}
    return tostring(
        context.npcID or context.actorID or npc.npcID or npc.id
            or npcData.npcID or npcData.id or "semantic-actor"
    )
end

local function selectPhrase(templateID, styleVariant, context, salt, localSelections)
    local phraseRegistry = activeRegistry()
    if type(phraseRegistry) ~= "table"
        or type(phraseRegistry.FamilyFor) ~= "function"
    then
        return nil
    end
    local family, phrases, selectedStyle = phraseRegistry.FamilyFor(
        templateID, styleVariant
    )
    if type(family) ~= "table" or type(phrases) ~= "table" or #phrases == 0 then
        local ConvoPlanFamily = PNC.ConvoEngine and PNC.ConvoEngine.ConvoPlanFamily or nil
        if type(ConvoPlanFamily) ~= "table" then
            local ok, loaded = pcall(
                require,
                "PNC/ConvoEngine/ResponseCatalog/ConvoPlanFamily"
            )
            if ok and type(loaded) == "table" then ConvoPlanFamily = loaded end
        end
        if type(ConvoPlanFamily) == "table"
            and type(ConvoPlanFamily.install) == "function"
        then
            ConvoPlanFamily.install(templateID)
            family, phrases, selectedStyle = phraseRegistry.FamilyFor(
                templateID, styleVariant
            )
        end
    end
    if type(family) ~= "table" or type(phrases) ~= "table" or #phrases == 0 then
        return nil
    end
    local familyID = tostring(family.id or templateID)
    local style = tostring(selectedStyle or styleVariant or "neutral")
    local key = phraseActorID(context) .. ":" .. familyID .. ":" .. style
    local existing = localSelections and localSelections[key]
    if existing then return existing end

    local isSeeded = type(context) == "table" and (
        context.phraseSalt ~= nil
        or context.variationSeed ~= nil
        or context.seed ~= nil
        or context.caseID ~= nil
    )
    local isStrict = (type(context) == "table" and context.strictCanonical == true)
        or salt == "canonical"

    local previous = phraseHistory[key]
    local index
    local reason
    if previous == nil then
        if isSeeded and not isStrict then
            index = (hash(tostring(salt or "") .. ":" .. key) % #phrases) + 1
            reason = "initial_seeded"
        else
            -- The default unseeded initial turn uses the accepted canonical
            -- wording (index 1). Subsequent turns use the stable salt and anti-repeat rule.
            index = 1
            reason = "initial_canonical"
        end
    else
        index = (hash(tostring(salt or "") .. ":" .. key) % #phrases) + 1
        if #phrases > 1 and tostring(phrases[index].id) == tostring(previous) then
            index = index % #phrases + 1
            reason = "immediate_repeat_avoided"
        else
            reason = "deterministic_hash"
        end
    end
    local selected = phrases[index]
    if type(selected) ~= "table" then return nil end
    if previous == nil then
        while #phraseHistoryOrder >= PHRASE_MAX_HISTORY do
            local oldest = table.remove(phraseHistoryOrder, 1)
            phraseHistory[oldest] = nil
        end
        phraseHistoryOrder[#phraseHistoryOrder + 1] = key
    end
    phraseHistory[key] = selected.id
    local localizedFallback = selected.fallback or ""
    local resolveKey = (type(selected.lookupKey) == "string" and selected.lookupKey ~= "")
        and selected.lookupKey or selected.key
    if type(resolveKey) == "string" and resolveKey ~= ""
        and PNC and PNC.Translation and type(PNC.Translation.GetKey) == "function"
    then
        local resolved = PNC.Translation.GetKey(resolveKey, localizedFallback)
        if type(resolved) == "string" and resolved ~= "" and resolved ~= resolveKey then
            localizedFallback = resolved
        end
    elseif type(selected.translations) == "table" then
        local ConvoPlanFamily = PNC.ConvoEngine and PNC.ConvoEngine.ConvoPlanFamily or nil
        local lang = type(ConvoPlanFamily) == "table"
            and type(ConvoPlanFamily.ActiveLanguage) == "function"
            and ConvoPlanFamily.ActiveLanguage() or "EN"
        localizedFallback = selected.translations[lang] or selected.translations.EN or localizedFallback
    end
    local result = {
        familyID = familyID,
        semanticTemplateID = tostring(templateID),
        style = style,
        phraseID = tostring(selected.id or ""),
        translationKey = tostring(selected.key or ""),
        fallback = tostring(localizedFallback),
        enFallback = tostring(selected.fallback or localizedFallback),
        poolSize = #phrases,
        antiRepeatReason = reason,
    }
    if localSelections then localSelections[key] = result end
    return result
end

function Realization.PhraseCoverage()
    local phraseRegistry = activeRegistry()
    if type(phraseRegistry) ~= "table" then return {} end
    return copy({
        schema = phraseRegistry.SCHEMA,
        fingerprint = phraseRegistry.CONTENT_FINGERPRINT,
        families = phraseRegistry.PHRASE_FAMILIES,
        playerChoices = phraseRegistry.PLAYER_CHOICES,
    })
end

function Realization.GetFamilyKeys()
    local phraseRegistry = activeRegistry()
    local keys = {}
    if phraseRegistry and type(phraseRegistry.PHRASE_FAMILIES) == "table" then
        for k in pairs(phraseRegistry.PHRASE_FAMILIES) do
            keys[#keys + 1] = tostring(k)
        end
    end
    table.sort(keys)
    return keys
end

function Realization.ResetPhraseHistory()
    for key in pairs(phraseHistory) do phraseHistory[key] = nil end
    for index = #phraseHistoryOrder, 1, -1 do phraseHistoryOrder[index] = nil end
end

function Realization.Coverage()
    return copy(COVERAGE)
end

local function relationshipArgument(style, argument)
    if argument ~= "familyAddress" then return nil end
    local bond = type(style) == "table" and style.bond or nil
    local term = type(bond) == "table" and bond.term or nil
    local translation = PNC.Translation
    if type(term) == "table" and term.addressKey
        and translation and type(translation.GetKey) == "function"
    then
        local value = translation.GetKey(
            term.addressKey, tostring(bond.kind or "family")
        )
        if value ~= nil and tostring(value) ~= "" then return tostring(value) end
    end
    return term and tostring(bond.kind or "") or nil
end

local function stripResidualPlaceholders(text)
    if type(text) ~= "string" then return text end
    if not string.find(text, "%s", 1, true) and not string.find(text, "%1", 1, true) then
        return text
    end
    local cleaned = text
    cleaned = string.gsub(cleaned, "^%%[s1],%s*", "")
    cleaned = string.gsub(cleaned, ",%s*%%[s1]([%p%s]?)", "%1")
    cleaned = string.gsub(cleaned, "%%[s1]%s*", "")
    cleaned = string.gsub(cleaned, "^%s+", "")
    cleaned = string.gsub(cleaned, "%s%s+", " ")
    if cleaned ~= "" then
        cleaned = string.upper(string.sub(cleaned, 1, 1)) .. string.sub(cleaned, 2)
    end
    return cleaned
end

local function hasAnyTemplateArgs(args, translationArgs)
    if type(translationArgs) == "table" and #translationArgs > 0 then
        return true
    end
    if type(args) == "table" then
        for _, v in pairs(args) do
            if v ~= nil and tostring(v) ~= "" then
                return true
            end
        end
    end
    return false
end

local function preferredPhraseStyle(style)
    style = type(style) == "table" and style or {}
    local variant = tostring(style.variant or "neutral")
    local bond = type(style.bond) == "table" and style.bond or nil
    if bond and tostring(bond.class or "") ~= "" then
        local addr = relationshipArgument(style, "familyAddress")
        if type(addr) == "string" and addr ~= "" then
            return "bond_" .. variant, addr
        end
    end
    return variant, nil
end

function Realization.Resolve(templateID, style, semanticFallback)
    local family = FAMILIES[tostring(templateID or "")]
    if not family then return nil, "realization_family_unavailable" end
    style = type(style) == "table" and style or {}
    local selectedFamily = family
    local bond = type(style.bond) == "table" and style.bond or nil
    local bondFamily = bond and family.bond and family.bond.any or nil
    if type(bondFamily) == "table" and tostring(bond.class or "") ~= "" then
        selectedFamily = bondFamily
    end
    local selected = tostring(style.variant or "neutral")
    local value = selectedFamily[selected]
    local reason
    if type(value) ~= "table" then
        value = selectedFamily.neutral or family.neutral
        reason = "neutral_fallback"
    end
    if type(value) ~= "table" then
        return nil, "realization_neutral_unavailable"
    end
    if selected == "neutral" and not value.forceKey then
        return {
            templateID = tostring(templateID),
            fallback = tostring(semanticFallback or value.fallback or ""),
            family = tostring(templateID),
            variant = "neutral",
            fallbackReason = nil,
        }
    end
    return {
        templateID = tostring(value.key or templateID),
        fallback = tostring(value.fallback or ""),
        family = tostring(templateID),
        variant = type(selectedFamily[selected]) == "table"
            and selected or "neutral",
        fallbackReason = reason,
        argument = value.argument,
    }
end

local function applySegment(segment, style, blocked, context, salt, localSelections, phraseStyle, familyAddress, hasResponseArgs)
    if type(segment) ~= "table" or segment.kind ~= "translation" then
        return segment, nil
    end
    if type(blocked) == "table" and blocked[segment.templateID] then
        return segment, nil
    end

    if not phraseStyle then
        phraseStyle, familyAddress = preferredPhraseStyle(style)
    end
    local phrase = selectPhrase(
        segment.templateID,
        phraseStyle,
        context,
        salt,
        localSelections
    )
    if not phrase then return segment, nil end

    local output = copy(segment)
    local resolvedTemplateID = (phrase.translationKey ~= "" and phrase.translationKey)
        or segment.templateID
    output.args = type(segment.args) == "table" and copy(segment.args) or {}
    output.semanticTemplateID = segment.templateID
    output.templateID = resolvedTemplateID
    local fb = phrase.fallback
    local stripped = false
    if tostring(phrase.style or ""):sub(1, 5) == "bond_" then
        local addr = familyAddress or relationshipArgument(style, "familyAddress")
        if type(addr) == "string" and addr ~= "" then
            output.args.familyAddress = addr
            output.args["addressee.name"] = addr
        else
            fb = stripResidualPlaceholders(fb)
            stripped = true
        end
    elseif string.find(tostring(fb or ""), "%s", 1, true)
        and not hasResponseArgs
        and not hasAnyTemplateArgs(output.args, output.translationArgs)
    then
        fb = stripResidualPlaceholders(fb)
        stripped = true
    end
    output.fallback = fb
    if phrase.enFallback ~= nil and phrase.enFallback ~= "" then
        if stripped or (string.find(tostring(phrase.enFallback), "%s", 1, true)
            and not hasResponseArgs
            and not hasAnyTemplateArgs(output.args, output.translationArgs))
        then
            output.enFallback = stripResidualPlaceholders(phrase.enFallback)
        else
            output.enFallback = phrase.enFallback
        end
    end
    output.realizationFamily = segment.templateID
    output.realizationVariant = tostring(
        type(style) == "table" and style.variant or "neutral"
    )
    output.phraseFamilyID = phrase.familyID
    output.phraseID = phrase.phraseID
    output.phrasePoolSize = phrase.poolSize
    output.phraseAntiRepeatReason = phrase.antiRepeatReason
    output.phraseSemanticTemplateID = phrase.semanticTemplateID
    output.phraseStyle = phrase.style

    return output, {
        templateID = resolvedTemplateID,
        fallback = fb,
        family = segment.templateID,
        variant = output.realizationVariant,
        contentStyle = phrase.style,
        fallbackReason = nil,
    }
end

local function compositionalInteractionResponse(
    response, context, style, semanticPlan
)
    context = type(context) == "table" and context or {}
    local interactionPlan = type(context.interactionPlan) == "table"
        and context.interactionPlan or nil
    local ir = type(context.dialogueIR) == "table"
        and context.dialogueIR or nil
    if not interactionPlan or not ir then
        return nil, "interaction_context_unavailable"
    end
    local expectedTemplate = tostring(
        interactionPlan.contentTemplateID or ""
    )
    if expectedTemplate == ""
        or tostring(response.templateID or "") ~= expectedTemplate
    then
        return nil, "interaction_response_template_mismatch"
    end

    local plan, planReason = UtterancePlan.FromInteraction(
        ir, interactionPlan, {
            speaker = "npc",
            target = "player",
            styleVariant = style and style.variant or "neutral",
            selectionSalt = context.utterancePlanSalt
                or response.selectionID
                or interactionPlan.behaviorID,
        }
    )
    if not plan then return nil, planReason end
    local realized, reason = UtterancePlan.Realize(plan)
    if not realized then return nil, reason end

    local output = copy(response)
    output.speechStyleContext = Style.PublicView(style)
    output.utterancePlan = copy(plan)
    output.utteranceRealization = copy(realized)
    output.fallback = realized.text
    output.renderPlan = {
        schemaVersion = 1,
        kind = "dialogue_act_plan",
        dialogueAct = plan.dialogueAct ~= ""
            and plan.dialogueAct or "REPLY",
        groundedFactRefs = copy(
            type(semanticPlan) == "table"
                and semanticPlan.groundedFactRefs or {}
        ) or {},
        turns = {
            {
                id = "microplan",
                separator = " ",
                continuation = "end",
                offers = {},
                segments = {
                    {
                        kind = "literal",
                        text = realized.text,
                    },
                },
            },
        },
    }
    if semanticPlan then output.plan = semanticPlan end
    output.realization = {
        family = "utterance_plan",
        variant = tostring(realized.constructionID or ""),
        applied = true,
        applicationCount = 1,
        neutralFallbackCount = 0,
        maxApplications = Realization.MAX_FAMILY_APPLICATIONS,
        compositional = true,
    }
    output.realizationFamily = "utterance_plan"
    output.realizationVariant = realized.constructionID
    output.semanticVariantID = output.selectionID
    output.speechStyleVariant = style.variant
    output.renderTemplateID = nil
    return output, "utterance_plan_realized"
end

function Realization.Apply(response, context)
    if type(response) ~= "table" then return response end
    local style = Style.Resolve(context)
    local hasPlan = type(response.plan) == "table"
    local hasInteractionPlan = type(context) == "table" and type(context.interactionPlan) == "table"
    local compositionalReason
    if hasInteractionPlan then
        local semanticPlan = hasPlan and copy(response.plan) or nil
        local compositional
        compositional, compositionalReason = compositionalInteractionResponse(
            response, context, style, semanticPlan
        )
        if compositional then return compositional end
    end
    local output = {}
    for key, item in pairs(response) do
        if type(key) == "string" or type(key) == "number" then
            if type(item) == "table" then
                output[key] = copy(item, 0)
            else
                output[key] = item
            end
        end
    end
    local semanticPlan = hasPlan and response.plan or nil
    local renderPlan = output.plan
    local applications = 0
    local fallbackCount = 0
    local first
    local resolved
    local segment
    local turn
    local blocked = {}
    local localSelections = {}
    local phraseSalt = (type(context) == "table" and (
        context.phraseSalt
        or context.variationSeed
        or context.seed
        or context.caseID
    )) or response.selectionID
    local phraseStyle, familyAddress = preferredPhraseStyle(style)
    local hasResponseArgs = hasAnyTemplateArgs(response.args, response.translationArgs)

    if response.selectionID == "semantic.refuse.default" then
        blocked["social.acknowledged"] = true
    end

    output.speechStyleContext = Style.PublicView(style)
    if type(renderPlan) == "table" and type(renderPlan.turns) == "table" then
        for index = 1, math.min(#renderPlan.turns, 4) do
            turn = renderPlan.turns[index]
            for segmentIndex = 1, math.min(#(turn.segments or {}), 6) do
                segment, resolved = applySegment(
                    turn.segments[segmentIndex], style, blocked,
                    context, phraseSalt, localSelections,
                    phraseStyle, familyAddress, hasResponseArgs
                )
                turn.segments[segmentIndex] = segment
                if resolved then
                    applications = applications + 1
                    first = first or resolved
                    if resolved.fallbackReason then fallbackCount = fallbackCount + 1 end
                end
            end
        end
    end
    if output.templateID and not blocked[output.templateID] then
        local phrase = selectPhrase(
            output.templateID, phraseStyle, context, phraseSalt, localSelections
        )
        if phrase then
            local resolvedTemplateID = (phrase.translationKey ~= "" and phrase.translationKey)
                or output.templateID
            local fb = phrase.fallback
            output.args = type(output.args) == "table" and output.args or {}
            local hasArgs = hasResponseArgs or hasAnyTemplateArgs(output.args, output.translationArgs)
            local stripped = false
            if tostring(phrase.style or ""):sub(1, 5) == "bond_" then
                local addr = familyAddress or relationshipArgument(style, "familyAddress")
                if type(addr) == "string" and addr ~= "" then
                    output.args.familyAddress = addr
                    output.args["addressee.name"] = addr
                else
                    fb = stripResidualPlaceholders(fb)
                    stripped = true
                end
            elseif string.find(tostring(fb or ""), "%s", 1, true) and not hasArgs then
                fb = stripResidualPlaceholders(fb)
                stripped = true
            end
            output.semanticTemplateID = output.templateID
            output.renderTemplateID = resolvedTemplateID
            output.fallback = fb
            if phrase.enFallback ~= nil and phrase.enFallback ~= "" then
                if stripped or (string.find(tostring(phrase.enFallback), "%s", 1, true) and not hasArgs) then
                    output.enFallback = stripResidualPlaceholders(phrase.enFallback)
                else
                    output.enFallback = phrase.enFallback
                end
            end
            output.realizationFamily = output.templateID
            output.realizationVariant = tostring(style.variant or "neutral")
            output.phraseFamilyID = phrase.familyID
            output.phraseID = phrase.phraseID
            output.phrasePoolSize = phrase.poolSize
            output.phraseAntiRepeatReason = phrase.antiRepeatReason
            output.phraseSemanticTemplateID = phrase.semanticTemplateID
            if output.phraseID then
                output.phraseSelection = {
                    familyID = output.phraseFamilyID,
                    phraseID = output.phraseID,
                    style = style.variant,
                    poolSize = output.phrasePoolSize,
                    antiRepeatReason = output.phraseAntiRepeatReason,
                }
            end
            resolved = {
                templateID = resolvedTemplateID,
                fallback = fb,
                family = output.templateID,
                variant = output.realizationVariant,
                contentStyle = phrase.style,
                fallbackReason = nil,
            }
            applications = applications + 1
            first = first or resolved
        end
    end
    output.realization = {
        family = first and first.family or nil,
        variant = first and first.variant or style.variant,
        applied = applications > 0,
        applicationCount = applications,
        neutralFallbackCount = fallbackCount,
        maxApplications = Realization.MAX_FAMILY_APPLICATIONS,
    }
    output.semanticVariantID = output.selectionID
    output.speechStyleVariant = style.variant
    if hasInteractionPlan then
        output.utterancePlanFallbackReason = compositionalReason
    end
    if type(output.fallback) == "string"
        and string.find(output.fallback, "%s", 1, true)
        and not (hasResponseArgs or hasAnyTemplateArgs(output.args, output.translationArgs))
    then
        output.fallback = stripResidualPlaceholders(output.fallback)
    end
    if hasPlan then
        output.renderPlan = output.plan
        output.plan = copy(response.plan, 0)
    end
    return output
end

return Realization
