PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Semantic = require "PsychopatzCore/Semantics/PsychopatzSemantic"
local Registry = Semantic.Registry
local Normalizer = Semantic.Normalizer
local GeneratedLexicon = require
    "PNC/Semantics/PNC_SemanticGeneratedLexicon"
local CampSite = PNC.Semantics.CampSite
    or require "PNC/Semantics/PNC_SemanticCampSite"
local Catalog = PNC.Semantics.Catalog or {}
PNC.Semantics.Catalog = Catalog
Catalog.Internal = Catalog.Internal or {}

Catalog.VERSION = 1
Catalog.OWNER = "ProjectHoomans"

local generatedAliasesByConcept = GeneratedLexicon
    and GeneratedLexicon.aliasesByConcept
if type(generatedAliasesByConcept) ~= "table" then
    error("generated semantic lexicon requires aliasesByConcept")
end
local generatedVerbFormsBySurface = GeneratedLexicon
    and GeneratedLexicon.verbFormsBySurface
if type(generatedVerbFormsBySurface) ~= "table" then
    error("generated semantic lexicon requires verbFormsBySurface")
end

-- Inflections resolve to a lemma and grammatical tag in a separate Registry
-- index; grammar rules must opt into a form before it can match.
function Catalog.ResolveVerbForm(surface)
    if type(surface) ~= "string" then return nil end
    local normalized = Normalizer.NormalizePhrase(surface)
    if normalized == "" then return nil end
    local form = generatedVerbFormsBySurface[normalized]
    if type(form) ~= "table" then return nil end
    return {
        concept = form.concept,
        lemma = form.lemma,
        form = form.form,
    }
end

local function registerConcept(id, aliases, priority)
    local combinedAliases = {}
    local seenAliases = {}
    local function appendAliases(sourceAliases, isGenerated)
        if sourceAliases == nil then return end
        if type(sourceAliases) ~= "table" then
            error("semantic concept aliases must be a table")
        end
        for _, alias in ipairs(sourceAliases) do
            if type(alias) ~= "string" then
                error("semantic concept alias must be a string")
            end
            local normalized = Normalizer.NormalizePhrase(alias)
            if normalized ~= "" then
                if not isGenerated or not seenAliases[normalized] then
                    table.insert(combinedAliases, alias)
                end
                seenAliases[normalized] = true
            end
        end
    end

    -- Core RegisterConcept replaces an existing definition, so generated
    -- entries must be merged into the authored list before registration.
    appendAliases(aliases, false)
    local generatedAliases = generatedAliasesByConcept[id]
    if generatedAliases ~= nil then
        appendAliases(generatedAliases, true)
    end
    return Registry.RegisterConcept({
        id = id,
        aliases = combinedAliases,
        priority = priority or 0,
        owner = Catalog.OWNER,
    })
end

local function validateGeneratedAliasTargets()
    for id, aliases in pairs(generatedAliasesByConcept) do
        if type(id) ~= "string" or type(aliases) ~= "table" then
            error("generated semantic lexicon contains an invalid concept entry")
        end
        local registeredConcept = Registry.GetConcept(id)
        if type(registeredConcept) ~= "table" then
            error("generated semantic lexicon targets an unregistered concept: " .. id)
        end
        local registeredAliases = {}
        for _, alias in ipairs(registeredConcept.aliases or {}) do
            registeredAliases[Normalizer.NormalizePhrase(alias)] = true
        end
        for _, alias in ipairs(aliases) do
            if type(alias) ~= "string" then
                error("generated semantic lexicon contains a non-string alias for " .. id)
            end
            local normalized = Normalizer.NormalizePhrase(alias)
            if normalized ~= "" and not registeredAliases[normalized] then
                error("generated semantic alias was not registered for " .. id
                    .. ": " .. normalized)
            end
        end
    end
end

local function validateGeneratedVerbForms()
    local validForms = {
        PAST = true,
        PROGRESSIVE = true,
        THIRD_PERSON = true,
    }
    for surface, form in pairs(generatedVerbFormsBySurface) do
        if type(surface) ~= "string"
            or Normalizer.NormalizePhrase(surface) ~= surface
            or type(form) ~= "table"
            or type(form.concept) ~= "string"
            or type(form.lemma) ~= "string"
            or validForms[form.form] ~= true
        then
            error("generated semantic lexicon contains an invalid verb form")
        end
        if type(Registry.GetConcept(form.concept)) ~= "table" then
            error("generated verb form targets an unregistered concept: "
                .. form.concept)
        end
    end
end

local function registerGeneratedVerbForms()
    local registerVerbForm = Registry.RegisterVerbForm
    if type(registerVerbForm) ~= "function" then
        Catalog.verbFormsRegistered = false
        return false
    end

    for surface, form in pairs(generatedVerbFormsBySurface) do
        local registered, reason = registerVerbForm({
            surface = surface,
            concept = form.concept,
            lemma = form.lemma,
            form = form.form,
            owner = Catalog.OWNER,
        })
        if registered ~= true then
            error("generated semantic verb form could not be registered: "
                .. surface .. " (" .. tostring(reason) .. ")")
        end
    end
    Catalog.verbFormsRegistered = true
    return true
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

Catalog.Internal.RegisterPattern = registerPattern
Catalog.Internal.RegisterConcept = registerConcept
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_Identity"

local function registerSpeechAct(id)
    return Registry.RegisterSpeechAct({
        id = id,
        owner = Catalog.OWNER,
    })
end

Catalog.Internal.RegisterSpeechAct = registerSpeechAct

require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_Concepts"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_ConversationPatterns"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_CommandPatterns"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_InventoryPatterns"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_GiftPatterns"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_RequestPatterns"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_QuestionPatterns"

function Catalog.Register()
    Catalog.Internal.RegisterVocabulary()
    registerGeneratedVerbForms()
    validateGeneratedAliasTargets()
    validateGeneratedVerbForms()
    Catalog.Internal.RegisterSelfStatePatterns()
    Catalog.Internal.RegisterIdentityPatterns()
    Catalog.Internal.RegisterBasicCommands()
    Catalog.Internal.RegisterInventoryQueries()
    Catalog.Internal.RegisterGiftOffers()
    Catalog.Internal.RegisterNavigationCommands()
    Catalog.Internal.RegisterRequests()
    Catalog.Internal.RegisterOtherCommands()
    Catalog.Internal.RegisterLocationQuestions()
    Catalog.Internal.RegisterSocialSignals()
    Catalog.Internal.RegisterWorldFactQuestions()
    Catalog.registered = true
    Catalog.registryRevision = Registry.GetRevision()
    return true, Catalog.registryRevision
end

Catalog.Register()

-- Keep socially charged language in its own data module.  The base catalog
-- remains the stable vocabulary hub, while this explicit dependency ensures
-- every normal shared semantic load sees the same social patterns.
require "PNC/Semantics/PNC_SemanticSocialCatalog"

return Catalog
