PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Semantic = require "PsychopatzCore/Semantics/PsychopatzSemantic"
local Registry = Semantic.Registry
local CampSite = PNC.Semantics.CampSite
    or require "PNC/Semantics/PNC_SemanticCampSite"
local Catalog = PNC.Semantics.Catalog or {}
PNC.Semantics.Catalog = Catalog
Catalog.Internal = Catalog.Internal or {}

Catalog.VERSION = 1
Catalog.OWNER = "ProjectHoomans"

local function registerConcept(id, aliases, priority)
    return Registry.RegisterConcept({
        id = id,
        aliases = aliases,
        priority = priority or 0,
        owner = Catalog.OWNER,
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
