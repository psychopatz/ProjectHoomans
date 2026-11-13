-- Stable static semantic suggestion provider entry point.
-- Definitions and eligibility routing load behind the same Provider object.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Provider = PNC.ConvoEngine.DialogueStaticChoiceProvider or {}
PNC.ConvoEngine.DialogueStaticChoiceProvider = Provider
local SemanticFoundation = require
    "PsychopatzCore/ConvoEngine/Foundation"
local IdentityAlias = PNC.IdentityAlias
if type(IdentityAlias) ~= "table" then
    local ok, loaded = pcall(require, "PNC/Core/Identity/PNC_IdentityAlias")
    IdentityAlias = PNC.IdentityAlias
    if type(IdentityAlias) ~= "table" and ok and type(loaded) == "table" then
        IdentityAlias = loaded
    end
end

Provider.id = "projecthoomans.static_questions"
Provider.sourceKind = "typed_input"
Provider.order = 50
Provider.Definitions = require
    "PNC/ConvoEngine/UI/Dialogue/CompanionCheckIn"
Provider.CoreDefinitions = SemanticFoundation.Registry.UI or {}

local function foundationContext(context)
    local knowledge = type(context) == "table"
        and (context.npcKnowledge or context.knowledge) or {}
    knowledge = type(knowledge) == "table" and knowledge or {}
    local identity = type(knowledge.identity) == "table"
        and knowledge.identity or {}
    return {
        identityKnowledge = {
            nameKnown = knowledge.nameKnown == true
                or knowledge.knownName ~= nil
                or context.identityState == "known",
            knownName = knowledge.knownName,
            nicknameKnown = knowledge.nicknameKnown == true
                or knowledge.knownNickname ~= nil
                or identity.nickname ~= nil,
            knownNickname = knowledge.knownNickname or identity.nickname,
            surnameKnown = knowledge.surnameKnown == true
                or knowledge.knownSurname ~= nil
                or identity.surname ~= nil,
            knownSurname = knowledge.knownSurname or identity.surname,
            factionKnown = knowledge.factionKnown == true
                or knowledge.factionID ~= nil
                or knowledge.factionName ~= nil,
            factionID = knowledge.factionID,
            factionName = knowledge.factionName,
        },
    }
end

function Provider.GetDefinitions(context)
    context = type(context) == "table" and context or {}
    local output = SemanticFoundation.GetStaticSuggestions(
        foundationContext(context)
    )
    local coreIDs = {}
    for _, definition in ipairs(Provider.CoreDefinitions) do
        if type(definition) == "table" and definition.id then
            coreIDs[definition.id] = true
        end
    end
    for _, definition in ipairs(Provider.Definitions) do
        if type(definition) == "table"
            and not coreIDs[definition.id]
        then
            output[#output + 1] = definition
        end
    end
    table.sort(output, function(left, right)
        local leftOrder = tonumber(left.order) or 100
        local rightOrder = tonumber(right.order) or 100
        if leftOrder ~= rightOrder then return leftOrder < rightOrder end
        return tostring(left.id) < tostring(right.id)
    end)
    return output
end

function Provider.Find(id)
    for _, definition in ipairs(Provider.Definitions) do
        if definition.id == id then return definition end
    end
    return nil
end

local Identity = require
    "PNC/ConvoEngine/Suggestions/StaticProvider_Identity"
local Context = require
    "PNC/ConvoEngine/Suggestions/StaticProvider_Context"
local hubCandidate = require
    "PNC/ConvoEngine/Suggestions/StaticProvider_Hub"
local installCollection = require
    "PNC/ConvoEngine/Suggestions/StaticProvider_Collect"

installCollection(Provider, Identity, Context, hubCandidate, IdentityAlias)

return Provider
