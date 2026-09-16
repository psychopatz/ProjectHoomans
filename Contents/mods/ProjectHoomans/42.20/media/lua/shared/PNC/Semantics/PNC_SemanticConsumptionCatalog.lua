-- Compositional consumption language definitions.
--
-- This catalog only translates a bounded request into Semantic IR.  It does
-- not call item APIs, start timed actions, or change nutrition/container
-- state.  Those responsibilities belong to the later authoritative task
-- handlers.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Semantic = require "PsychopatzCore/Semantics/PsychopatzSemantic"
local Registry = Semantic.Registry
local Catalog = PNC.Semantics.ConsumptionCatalog or {}
PNC.Semantics.ConsumptionCatalog = Catalog

Catalog.VERSION = 1
Catalog.OWNER = "ProjectHoomans"

local function registerConcept(id, aliases, priority)
    return Registry.RegisterConcept({
        id = id,
        aliases = aliases,
        priority = priority or 0,
        owner = Catalog.OWNER,
        metadata = { domain = "consumption" },
    })
end

local function registerPattern(id, match, emit, confidence, priority, options)
    local definition = {
        id = id,
        match = match,
        emit = emit,
        confidence = confidence,
        priority = priority or 0,
        owner = Catalog.OWNER,
    }
    for key, value in pairs(type(options) == "table" and options or {}) do
        definition[key] = value
    end
    return Registry.RegisterPattern(definition)
end

local function prefixRules()
    return {
        { kind = "literal", value = "well", optional = true },
        { kind = "literal", value = "please", optional = true },
        { kind = "literal", value = "can", optional = true },
        { kind = "literal", value = "could", optional = true },
        { kind = "literal", value = "would", optional = true },
        { kind = "literal", value = "you", optional = true },
        { kind = "literal", value = "please", optional = true },
    }
end

local function append(list, value)
    list[#list + 1] = value
end

local function objectRules()
    return {
        { kind = "literal", value = "your", optional = true },
        { kind = "literal", value = "the", optional = true },
        { kind = "literal", value = "a", optional = true },
        { kind = "literal", value = "an", optional = true },
        { kind = "literal", value = "some", optional = true },
        {
            kind = "any_phrase",
            capture = "object",
            minTokens = 1,
            maxTokens = 4,
            stopWords = { "please", "now", "then" },
        },
        { kind = "literal", value = "please", optional = true },
        { kind = "literal", value = "now", optional = true },
    }
end

local function objectEmit()
    return {
        category = "$capture.object.category",
        concept = "$capture.object.concept",
        text = "$capture.object.text",
        value = "$capture.object.value",
        unresolved = "$capture.object.unresolved",
        reference = "$capture.object.reference",
        quantity = "ONE",
    }
end

local function requestEmit(action)
    return {
        intent = "REQUEST",
        speechAct = "REQUEST",
        action = action,
        object = objectEmit(),
    }
end

local function implicitRequestEmit(action)
    return {
        intent = "REQUEST",
        speechAct = "REQUEST",
        action = action,
        -- An omitted object is an implicit discourse reference.  The
        -- contextual resolver may bind it to the current salient item, but
        -- it remains unresolved until that step succeeds.
        object = {
            reference = "IT",
            unresolved = true,
            implicit = true,
        },
    }
end

local function registerAction(action, aliases, priority)
    registerConcept(action, aliases, priority)

    local match = prefixRules()
    append(match, { kind = "concept", id = action })
    local rules = objectRules()
    for index = 1, #rules do append(match, rules[index]) end
    registerPattern(
        "pnc.request." .. string.lower(action),
        match,
        requestEmit(action),
        0.94,
        100,
        { allowFuzzyCapture = true }
    )

    local implicit = prefixRules()
    append(implicit, { kind = "concept", id = action })
    registerPattern(
        "pnc.request." .. string.lower(action) .. "_implicit",
        implicit,
        implicitRequestEmit(action),
        0.82,
        75,
        { allowFuzzyCapture = true }
    )
end

function Catalog.Register()
    registerAction("EAT", {
        "eat", "have a bite", "take a bite",
    }, 4)
    registerAction("DRINK", {
        "drink", "sip", "have a drink", "take a drink",
    }, 4)
    registerAction("REFILL", {
        "refill", "fill up", "top up", "top off",
    }, 4)
    registerAction("CONSUME", {
        "consume",
    }, 3)

    Catalog.registered = true
    Catalog.registryRevision = Registry.GetRevision()
    return true, Catalog.registryRevision
end

Catalog.Register()

return Catalog
