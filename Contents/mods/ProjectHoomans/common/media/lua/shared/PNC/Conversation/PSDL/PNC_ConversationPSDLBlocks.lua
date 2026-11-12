-- Project Hoomans adopter projection for PSDL dialogue plans.
--
-- PSDL remains authored and compiled by PsychopatzCore.  This module only
-- adapts the generated response/offer plan to the existing Core Conversation
-- block registry so the established PNC composer and authority continue to
-- own lifecycle, choice, and effect behavior.

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

require "PNC/Conversation/Definitions/01_PNC_ConversationDefinitionHelpers"
require "PNC/Conversation/Definitions/10_PNC_ConversationCategories"

local Generated = require "PNC/Semantics/Generated/Conversation/Registry"
local Registry = PsychopatzCore.Conversation.Registry

local OWNER = "ProjectHoomans"
local RELATIONSHIP_PREFIX = "relationship.speakerToAddressee."
local OPERATOR = {
    eq = "==",
    neq = "~=",
    gt = ">",
    gte = ">=",
    lt = "<",
    lte = "<=",
}

local function metadata(plan)
    local payload = type(plan) == "table" and plan.payload or nil
    return type(payload) == "table" and type(payload.metadata) == "table"
        and payload.metadata or {}
end

local function textSource(plan)
    local values = metadata(plan)
    local target = tostring(values.textTarget or "")
    if target == "" then return nil end
    return {
        modID = OWNER,
        pathPattern = "media/translation/{language}/Conversation/Text/"
            .. target .. ".json",
        domain = tostring(values.textDomain or "pnc.psdl." .. target),
    }
end

local function relationshipGate(node)
    if type(node) ~= "table" then return nil end
    local path = tostring(node.path or node.field or "")
    if string.sub(path, 1, #RELATIONSHIP_PREFIX) ~= RELATIONSHIP_PREFIX then
        return nil
    end
    local axis = string.sub(path, #RELATIONSHIP_PREFIX + 1)
    local operator = OPERATOR[tostring(node.op or "eq")]
    if axis == "" or not operator or node.value == nil then return nil end
    return {
        type = "pnc:relationship",
        axis = axis,
        operator = operator,
        value = node.value,
    }
end

local function gatesForPredicate(predicate)
    if type(predicate) ~= "table" then return {} end
    if type(predicate.all) == "table" then
        local output = {}
        for _, child in ipairs(predicate.all) do
            local gate = relationshipGate(child)
            if gate then output[#output + 1] = gate end
        end
        return output
    end
    local gate = relationshipGate(predicate)
    return gate and { gate } or {}
end

local function addChoice(node, offer)
    local offerMetadata = type(offer.metadata) == "table"
        and offer.metadata or {}
    local choiceKey = tostring(
        offerMetadata.choiceKey or "offer." .. tostring(offer.id) .. ".label"
    )
    local responseKey = tostring(
        offerMetadata.responseKey or "offer." .. tostring(offer.id) .. ".response"
    )
    local outcome = {
        id = "reply",
        weight = 1,
        responseKey = responseKey,
        next = offerMetadata.next or "$root",
        close = offerMetadata.close == true,
        effects = type(offerMetadata.effects) == "table"
            and offerMetadata.effects or {},
        gates = gatesForPredicate(offer.when),
    }
    local choice = {
        id = tostring(offer.id),
        textKey = choiceKey,
        outcomes = { outcome },
        gates = gatesForPredicate(offer.when),
    }
    node.choices[#node.choices + 1] = choice
end

local function registerPlan(plan)
    local values = metadata(plan)
    local response = type(plan.payload) == "table"
        and type(plan.payload.response) == "table"
        and plan.payload.response or nil
    local turns = response and response.turns or nil
    local turn = type(turns) == "table" and turns[1] or nil
    local turnMetadata = type(turn) == "table"
        and type(turn.metadata) == "table" and turn.metadata or {}
    if type(turn) ~= "table" or type(turn.text) ~= "table" then return false end
    local blockID = tostring(values.runtimeBlockID or "")
    local category = tostring(values.category or "")
    local audience = tostring(values.audience or "")
    local source = textSource(plan)
    if blockID == "" or category == "" or audience == "" or not source then
        return false
    end
    local node = {
        textKey = tostring(turnMetadata.textKey or "turn." .. tostring(turn.id)),
        choices = {},
    }
    for _, offer in ipairs(turn.offers or {}) do
        if type(offer) == "table" and offer.id then addChoice(node, offer) end
    end
    local definition = {
        schemaVersion = 1,
        ownerModID = OWNER,
        category = category,
        audiences = { audience },
        priority = tonumber(values.priority) or 0,
        weight = tonumber(values.weight) or 100,
        textSource = source,
        entryNode = "opening",
        nodes = { opening = node },
    }
    local ok = Registry.RegisterBlock(blockID, definition)
    return ok == true
end

local IDS = {
    "social.wellbeing.neutral",
    "social.wellbeing.member",
    "social.wellbeing.special",
    "social.small_talk.neutral",
    "social.small_talk.member",
    "social.small_talk.special",
}

for _, id in ipairs(IDS) do
    local plan = Generated.PSDLPlan(id)
    if plan then registerPlan(plan) end
end

return true
