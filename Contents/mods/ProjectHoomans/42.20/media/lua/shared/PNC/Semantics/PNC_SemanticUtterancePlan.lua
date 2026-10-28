-- Bounded semantic utterance microplanning.
--
-- Plans are semantic/presentation artifacts only. They never authorize
-- gameplay effects and never splice arbitrary raw player text into output.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local UtterancePlan = PNC.Semantics.UtterancePlan or {}
PNC.Semantics.UtterancePlan = UtterancePlan

UtterancePlan.VERSION = 1
UtterancePlan.MAX_LEXEMES = 6
UtterancePlan.MAX_SLOTS = 6
UtterancePlan.MAX_TEXT = 256

local loaded = false
local recordsByID = {}
local lexemesByConcept = {}
local aliasToConcept = {}
local constructions = {}

local function bounded(value, limit)
    value = tostring(value or "")
    limit = tonumber(limit) or UtterancePlan.MAX_TEXT
    if #value > limit then return string.sub(value, 1, limit) end
    return value
end

local function copy(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 6 then return nil end
    local output = {}
    local count = 0
    for key, item in pairs(value) do
        if count >= 32 then break end
        if type(key) == "string" or type(key) == "number" then
            output[key] = copy(item, depth + 1)
            count = count + 1
        end
    end
    return output
end

local function stableHash(value)
    local output = 0
    value = tostring(value or "")
    for index = 1, #value do
        output = (output * 31 + string.byte(value, index)) % 2147483647
    end
    return output
end

local STYLE_OFFSETS = {
    neutral = 0,
    warm = 1,
    terse = 2,
    guarded = 3,
}

local function canonicalAlias(value)
    value = string.lower(tostring(value or ""))
    value = string.gsub(value, "%s+", " ")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value
end

local function currentLocale(plan)
    local locale = type(plan) == "table" and plan.locale or nil
    if locale and tostring(locale) ~= "" then
        return string.upper(tostring(locale))
    end
    local manager = CustomTranslationManager
    if manager and type(manager.getLanguage) == "function" then
        local ok, value = pcall(manager.getLanguage)
        if ok and value then
            return string.upper(tostring(value))
        end
    end
    return "EN"
end

local function registerRecord(record)
    if type(record) ~= "table" then return end
    local id = tostring(record.id or "")
    if id == "" then return end
    recordsByID[id] = record
    if record.type == "lexeme" then
        local concept = tostring(record.concept or "")
        if concept ~= "" then lexemesByConcept[concept] = record end
        for _, alias in ipairs(record.aliases or {}) do
            local key = canonicalAlias(alias)
            if key ~= "" and aliasToConcept[key] == nil then
                aliasToConcept[key] = concept
            end
        end
    elseif record.type == "construction" then
        local locale = string.upper(tostring(record.locale or ""))
        local strategy = string.upper(tostring(record.strategy or ""))
        if locale ~= "" and strategy ~= "" then
            constructions[locale] = constructions[locale] or {}
            constructions[locale][strategy] =
                constructions[locale][strategy] or {}
            constructions[locale][strategy][#constructions[locale][strategy] + 1] =
                record
        end
    end
end

local function loadCatalog()
    if loaded then return end
    loaded = true
    local ok, index = pcall(
        require,
        "PNC/Semantics/Generated/Conversation/Index/Realization/Social"
    )
    if not ok or type(index) ~= "table" then return end
    local modules = {}
    for _, entry in pairs(index) do
        for _, module in ipairs(type(entry) == "table"
            and entry.generated or {}) do
            modules[tostring(module)] = true
        end
    end
    for module in pairs(modules) do
        local moduleOK, records = pcall(require, module)
        if moduleOK and type(records) == "table" then
            for _, record in ipairs(records) do registerRecord(record) end
        end
    end
    for _, byStrategy in pairs(constructions) do
        for _, values in pairs(byStrategy) do
            table.sort(values, function(left, right)
                return tostring(left.id or "") < tostring(right.id or "")
            end)
        end
    end
end

function UtterancePlan.ResetCatalogForTests()
    loaded = false
    recordsByID = {}
    lexemesByConcept = {}
    aliasToConcept = {}
    constructions = {}
end

function UtterancePlan.CanonicalLexemesFromIR(ir)
    loadCatalog()
    local output = {}
    local seen = {}
    local function addConcept(concept)
        concept = tostring(concept or "")
        if concept ~= "" and lexemesByConcept[concept]
            and not seen[concept] and #output < UtterancePlan.MAX_LEXEMES
        then
            seen[concept] = true
            output[#output + 1] = concept
        end
    end
    local function addAlias(alias)
        local concept = aliasToConcept[canonicalAlias(alias)]
        if concept then addConcept(concept) end
    end

    ir = type(ir) == "table" and ir or {}
    local provenance = type(ir.provenance) == "table" and ir.provenance or {}
    local recovery = type(provenance.surfaceRecovery) == "table"
        and provenance.surfaceRecovery or {}
    addAlias(recovery.sourceAlias)
    addAlias(recovery.recoveredSurface)

    local analysis = type(ir.analysis) == "table" and ir.analysis or {}
    for _, symbol in ipairs(type(analysis.symbols) == "table"
        and analysis.symbols or {}) do
        addAlias(symbol.matchedAlias)
        addAlias(symbol.text)
    end
    return output
end

function UtterancePlan.New(spec)
    spec = type(spec) == "table" and spec or {}
    local plan = {
        schemaVersion = UtterancePlan.VERSION,
        kind = "semantic_utterance_plan",
        speaker = tostring(spec.speaker or "player"),
        target = tostring(spec.target or "recipient"),
        dialogueAct = tostring(spec.dialogueAct or spec.strategy or ""),
        strategy = string.upper(tostring(spec.strategy or "")),
        stance = string.upper(tostring(spec.stance or "NEUTRAL")),
        topic = spec.topic and bounded(spec.topic, 96) or nil,
        subject = spec.subject and bounded(spec.subject, 96) or nil,
        intensity = tonumber(spec.intensity) or 0,
        locale = spec.locale and string.upper(tostring(spec.locale)) or nil,
        styleVariant = string.lower(tostring(spec.styleVariant or "neutral")),
        selectionSalt = bounded(spec.selectionSalt or "", 96),
        fallbackContentTemplateID = spec.fallbackContentTemplateID,
        lexemes = {},
        slots = {},
        safeSlots = {},
        provenance = copy(spec.provenance) or {},
    }
    for key, value in pairs(type(spec.lexemes) == "table" and spec.lexemes or {}) do
        if #plan.lexemes >= UtterancePlan.MAX_LEXEMES then break end
        if type(key) == "string" and type(value) == "string" then
            plan.lexemes[key] = value
        end
    end
    local slotCount = 0
    for key, value in pairs(type(spec.slots) == "table" and spec.slots or {}) do
        if slotCount >= UtterancePlan.MAX_SLOTS then break end
        if type(key) == "string" and spec.safeSlots and spec.safeSlots[key] == true then
            plan.slots[key] = bounded(value, 96)
            plan.safeSlots[key] = true
            slotCount = slotCount + 1
        end
    end
    return plan
end

local function constructionFor(plan, locale)
    loadCatalog()
    local byLocale = constructions[locale]
    local values = byLocale and byLocale[plan.strategy] or nil
    if type(values) ~= "table" or #values == 0 then return nil end
    local dialogueAct = string.upper(tostring(plan.dialogueAct or ""))
    local eligible = {}
    for _, record in ipairs(values) do
        if dialogueAct == ""
            or string.upper(tostring(record.dialogueAct or "")) == dialogueAct
        then
            eligible[#eligible + 1] = record
        end
    end
    if #eligible == 0 then eligible = values end
    if #eligible == 1 then return eligible[1] end

    local style = string.lower(tostring(plan.styleVariant or "neutral"))
    local styleOffset = STYLE_OFFSETS[style] or 0
    local selectionSalt = tostring(plan.selectionSalt or "")
    local turnOffset = tonumber(string.match(selectionSalt, "^(%d+)"))
        or stableHash(selectionSalt)
    local seed = table.concat({
        style,
        tostring(plan.strategy or ""),
        tostring(plan.dialogueAct or ""),
        tostring(locale or ""),
    }, ":")
    local index = (
        (stableHash(seed) + turnOffset + styleOffset) % #eligible
    ) + 1
    return eligible[index]
end

function UtterancePlan.Realize(plan)
    if type(plan) ~= "table" or plan.kind ~= "semantic_utterance_plan" then
        return nil, "utterance_plan_invalid"
    end
    local locale = currentLocale(plan)
    local construction = constructionFor(plan, locale)
    if not construction then
        return nil, "construction_unavailable"
    end

    loadCatalog()
    local parts = {}
    local usedLexemes = {}
    for _, token in ipairs(construction.tokens or {}) do
        local kind = tostring(token.kind or "")
        if kind == "literal" then
            parts[#parts + 1] = bounded(token.value, 128)
        elseif kind == "lexeme" then
            local concept = plan.lexemes[tostring(token.slot or "")]
            local lexeme = concept and lexemesByConcept[concept] or nil
            local form = lexeme and lexeme.forms
                and (lexeme.forms[locale] or lexeme.forms.EN) or nil
            if not form or form == "" then
                return nil, "lexeme_unavailable"
            end
            parts[#parts + 1] = bounded(form, 96)
            usedLexemes[#usedLexemes + 1] = tostring(lexeme.id or concept)
        elseif kind == "slot" then
            local slot = tostring(token.slot or "")
            if plan.safeSlots[slot] ~= true or plan.slots[slot] == nil then
                return nil, "unsafe_or_missing_slot"
            end
            parts[#parts + 1] = bounded(plan.slots[slot], 96)
        else
            return nil, "construction_token_unsupported"
        end
    end
    local value = table.concat(parts)
    if value == "" then return nil, "realized_text_empty" end
    return {
        schemaVersion = UtterancePlan.VERSION,
        kind = "semantic_utterance_realization",
        text = bounded(value),
        locale = locale,
        constructionID = construction.id,
        strategy = plan.strategy,
        dialogueAct = plan.dialogueAct,
        lexemeIDs = usedLexemes,
    }, "realized"
end

local function contains(values, wanted)
    for _, value in ipairs(type(values) == "table" and values or {}) do
        if tostring(value) == wanted then return true end
    end
    return false
end

function UtterancePlan.FromInteraction(ir, interactionPlan, spec)
    ir = type(ir) == "table" and ir or {}
    interactionPlan = type(interactionPlan) == "table"
        and interactionPlan or {}
    spec = type(spec) == "table" and spec or {}
    local behaviorAct = string.upper(tostring(
        interactionPlan.behaviorAct or ""
    ))
    local dialogueAct = string.upper(tostring(
        interactionPlan.dialogueAct or ""
    ))
    local strategy
    local planDialogueAct = dialogueAct
    local stance = "NEUTRAL"
    local lexemes = {}

    if behaviorAct == "WARN" or dialogueAct == "BOUNDARY_WARNING" then
        strategy = "WARN"
        planDialogueAct = "BOUNDARY_WARNING"
        stance = "NEGATIVE"
    elseif behaviorAct == "RETALIATE_VERBALLY"
        or dialogueAct == "RETALIATE_VERBALLY"
    then
        local concepts = UtterancePlan.CanonicalLexemesFromIR(ir)
        if not contains(concepts, "PROFANITY_FUCK") then
            return nil, "mirror_lexeme_unavailable"
        end
        strategy = "MIRROR"
        planDialogueAct = "RETORT"
        stance = "NEGATIVE"
        lexemes.primary = "PROFANITY_FUCK"
    elseif behaviorAct == "DEESCALATE" or dialogueAct == "DEESCALATE" then
        strategy = "DEESCALATE"
        stance = "POSITIVE"
    elseif behaviorAct == "CHALLENGE" or dialogueAct == "CHALLENGE" then
        strategy = "CHALLENGE"
        stance = "NEGATIVE"
    elseif behaviorAct == "END_INTERACTION"
        or dialogueAct == "END_CONVERSATION"
    then
        strategy = "END_CONVERSATION"
        planDialogueAct = "END_CONVERSATION"
        stance = "NEGATIVE"
    elseif behaviorAct == "RECONCILE" then
        strategy = "ACKNOWLEDGE"
        planDialogueAct = "ACKNOWLEDGE"
        stance = "POSITIVE"
    elseif behaviorAct == "ACKNOWLEDGE_THANKS"
        or dialogueAct == "ACKNOWLEDGE"
    then
        strategy = "ACKNOWLEDGE"
        planDialogueAct = "ACKNOWLEDGE"
        stance = "POSITIVE"
    else
        return nil, "interaction_strategy_unavailable"
    end

    local plan = UtterancePlan.New({
        speaker = spec.speaker or "npc",
        target = spec.target or "player",
        dialogueAct = planDialogueAct,
        strategy = strategy,
        stance = stance,
        topic = interactionPlan.topic,
        subject = interactionPlan.subject,
        intensity = type(ir.extensions) == "table"
            and type(ir.extensions.socialFeatures) == "table"
            and ir.extensions.socialFeatures.intensity or 0,
        locale = spec.locale,
        styleVariant = spec.styleVariant,
        selectionSalt = spec.selectionSalt,
        fallbackContentTemplateID =
            interactionPlan.contentTemplateID,
        lexemes = lexemes,
        provenance = {
            interactionPlan = {
                behaviorID = interactionPlan.behaviorID,
                behaviorAct = interactionPlan.behaviorAct,
                beatID = interactionPlan.beatID,
                contentTemplateID = interactionPlan.contentTemplateID,
            },
            sourceSpeechAct = interactionPlan.sourceSpeechAct
                or ir.speechAct,
            sourceIntent = interactionPlan.sourceIntent or ir.intent,
        },
    })
    return plan, "interaction_plan_mapped"
end

function UtterancePlan.CatalogSnapshot()
    loadCatalog()
    local ids = {}
    for id in pairs(recordsByID) do ids[#ids + 1] = id end
    table.sort(ids)
    return {
        recordCount = #ids,
        ids = ids,
    }
end

return UtterancePlan
