-- Shared SpeechRealization registry, resolver, and fallback boundary.
--
-- Dialogue Content is the one first-party wording registry. This file owns the
-- one application path used by semantic responses; it never selects prose.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Realization = PNC.Semantics.SpeechRealization or {}
PNC.Semantics.SpeechRealization = Realization

Realization.VERSION = 1
Realization.MAX_FAMILY_APPLICATIONS = 8

local Style = PNC.Semantics.SpeechStyleContext
    or require "PNC/Semantics/PNC_SpeechStyleContext"
local phraseRegistry
do
    local ok, value = pcall(require,
        "PNC/Semantics/Generated/DialogueContent/Registry")
    if ok and type(value) == "table" then phraseRegistry = value end
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
    if type(phraseRegistry) ~= "table"
        or type(phraseRegistry.FamilyFor) ~= "function"
    then
        return nil
    end
    local family, phrases, selectedStyle = phraseRegistry.FamilyFor(
        templateID, styleVariant
    )
    if type(family) ~= "table" or type(phrases) ~= "table" or #phrases == 0 then
        return nil
    end
    local familyID = tostring(family.id or templateID)
    local style = tostring(selectedStyle or styleVariant or "neutral")
    local key = phraseActorID(context) .. ":" .. familyID .. ":" .. style
    local existing = localSelections and localSelections[key]
    if existing then return existing end

    local previous = phraseHistory[key]
    local index
    local reason
    if previous == nil then
        -- The first migration turn is intentionally the accepted canonical
        -- wording. Subsequent turns use the stable salt and anti-repeat rule.
        index = 1
        reason = "initial_canonical"
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
    local result = {
        familyID = familyID,
        semanticTemplateID = tostring(
            family.semanticTemplateID or templateID
        ),
        style = style,
        phraseID = tostring(selected.id or ""),
        translationKey = tostring(selected.key or ""),
        fallback = tostring(selected.fallback or ""),
        poolSize = #phrases,
        antiRepeatReason = reason,
    }
    if localSelections then localSelections[key] = result end
    return result
end

function Realization.PhraseCoverage()
    if type(phraseRegistry) ~= "table" then return {} end
    return copy({
        schema = phraseRegistry.SCHEMA,
        fingerprint = phraseRegistry.CONTENT_FINGERPRINT,
        families = phraseRegistry.PHRASE_FAMILIES,
        playerChoices = phraseRegistry.PLAYER_CHOICES,
        runtimeAliases = phraseRegistry.RUNTIME_ALIASES,
    })
end

function Realization.ResetPhraseHistory()
    for key in pairs(phraseHistory) do phraseHistory[key] = nil end
    for index = #phraseHistoryOrder, 1, -1 do phraseHistoryOrder[index] = nil end
end

function Realization.Register(templateID, family)
    return false, "dialogue_content_is_canonical"
end

function Realization.Families()
    return copy(phraseRegistry and phraseRegistry.PHRASE_FAMILIES or {})
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

function Realization.Resolve(templateID, style, semanticFallback)
    style = type(style) == "table" and style or {}
    local selected = tostring(style.variant or "neutral")
    if type(phraseRegistry) ~= "table"
        or type(phraseRegistry.FamilyFor) ~= "function"
    then
        return nil, "realization_content_unavailable"
    end
    local family, phrases, selectedStyle = phraseRegistry.FamilyFor(
        templateID, selected
    )
    if type(family) ~= "table" or type(phrases) ~= "table"
        or #phrases == 0
    then
        return nil, "realization_family_unavailable"
    end
    local value = phrases[1]
    local canonicalID = tostring(family.semanticTemplateID or templateID)
    local fallback = tostring(value.fallback or semanticFallback or "")
    return {
        templateID = canonicalID,
        semanticTemplateID = canonicalID,
        fallback = fallback,
        family = canonicalID,
        variant = tostring(selectedStyle or selected or "neutral"),
        fallbackReason = nil,
        argument = string.find(fallback, "%s", 1, true)
            and "familyAddress" or nil,
    }
end

local function applySegment(segment, style, blocked, context, salt, localSelections)
    if type(segment) ~= "table" or segment.kind ~= "translation" then
        return segment, nil
    end
    if type(blocked) == "table" and blocked[segment.templateID] then
        return segment, nil
    end
    local resolved = Realization.Resolve(
        segment.templateID, style, segment.fallback
    )
    local phrase
    if resolved then
        phrase = selectPhrase(
            segment.templateID,
            resolved.variant,
            context,
            salt,
            localSelections
        )
    else
        -- Migrated event/ToolReply templates may intentionally have no
        -- speech-style family. Dialogue Content still owns their wording;
        -- applying that phrase must not require a second semantic selector.
        phrase = selectPhrase(
            segment.templateID,
            style.variant,
            context,
            salt,
            localSelections
        )
        if not phrase then return segment, nil end
        resolved = {
            templateID = segment.templateID,
            fallback = phrase.fallback,
            family = segment.templateID,
            variant = phrase.style,
            fallbackReason = nil,
            contentOnly = true,
        }
    end
    local output = copy(segment)
    output.args = copy(segment.args or {})
    output.semanticTemplateID = resolved.semanticTemplateID
        or segment.templateID
    output.templateID = resolved.templateID
    output.fallback = resolved.fallback
    output.realizationFamily = resolved.family
    output.realizationVariant = resolved.variant
    output.realizationFallbackReason = resolved.fallbackReason
    if phrase then
        output.templateID = phrase.translationKey
        output.fallback = phrase.fallback
        output.phraseFamilyID = phrase.familyID
        output.phraseID = phrase.phraseID
        output.phrasePoolSize = phrase.poolSize
        output.phraseAntiRepeatReason = phrase.antiRepeatReason
        output.phraseSemanticTemplateID = phrase.semanticTemplateID
    end
    if resolved.argument then
        output.args[resolved.argument] = relationshipArgument(style, resolved.argument)
    end
    return output, resolved
end

function Realization.Apply(response, context)
    if type(response) ~= "table" then return response end
    local style = Style.Resolve(context)
    local output = copy(response)
    local semanticPlan = type(response.plan) == "table"
        and copy(response.plan) or nil
    local renderPlan = output.plan
    local applications = 0
    local fallbackCount = 0
    local first
    local resolved
    local segment
    local turn
    local blocked = {}
    local localSelections = {}
    local phraseSalt = context and context.phraseSalt or response.selectionID

    if response.selectionID == "semantic.refuse.default" then
        blocked["semantic.social.acknowledged"] = true
    end

    output.speechStyleContext = Style.PublicView(style)
    if type(renderPlan) == "table" and type(renderPlan.turns) == "table" then
        for index = 1, math.min(#renderPlan.turns, 4) do
            turn = renderPlan.turns[index]
            for segmentIndex = 1, math.min(#(turn.segments or {}), 6) do
                segment, resolved = applySegment(
                    turn.segments[segmentIndex], style, blocked,
                    context, phraseSalt, localSelections
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
    segment, resolved = applySegment({
        kind = "translation",
        templateID = output.templateID,
        fallback = output.fallback,
        args = output.args,
    }, style, blocked, context, phraseSalt, localSelections)
    if resolved then
        output.args = segment.args
        output.semanticTemplateID = output.templateID
        output.renderTemplateID = resolved.templateID
        output.fallback = segment.fallback or resolved.fallback
        output.realizationFamily = resolved.family
        output.realizationVariant = resolved.variant
        output.realizationFallbackReason = resolved.fallbackReason
        output.phraseFamilyID = segment.phraseFamilyID
        output.phraseID = segment.phraseID
        output.phrasePoolSize = segment.phrasePoolSize
        output.phraseAntiRepeatReason = segment.phraseAntiRepeatReason
        output.phraseSemanticTemplateID = segment.phraseSemanticTemplateID
        if output.phraseID then
            output.phraseSelection = {
                familyID = output.phraseFamilyID,
                phraseID = output.phraseID,
                style = style.variant,
                poolSize = output.phrasePoolSize,
                antiRepeatReason = output.phraseAntiRepeatReason,
            }
        end
        applications = applications + 1
        first = first or resolved
        if resolved.fallbackReason then fallbackCount = fallbackCount + 1 end
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
    -- Keep the semantic response plan canonical while the renderer uses the
    -- realized copy. Queued payloads and decision results then share one
    -- stable plan identity without losing style-specific rendering.
    if semanticPlan then
        output.renderPlan = output.plan
        output.plan = semanticPlan
    end
    return output
end

return Realization
