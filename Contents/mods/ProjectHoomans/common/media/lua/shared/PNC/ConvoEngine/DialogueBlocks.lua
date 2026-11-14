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

local Generated = require "PNC/ConvoEngine/Registry"
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
    local operator = OPERATOR[tostring(node.op or "eq")]
    if string.sub(path, 1, #RELATIONSHIP_PREFIX) == RELATIONSHIP_PREFIX then
        local axis = string.sub(path, #RELATIONSHIP_PREFIX + 1)
        if axis == "state" then
            if operator ~= "==" or node.value == nil then return nil end
            return {
                type = "pnc:relationship_state",
                value = node.value,
            }
        end
        if axis == "" or not operator or node.value == nil then return nil end
        return {
            type = "pnc:relationship",
            axis = axis,
            operator = operator,
            value = node.value,
        }
    end
    return nil
end

local function settlementVisitGate(node)
    if type(node) ~= "table" then return nil end
    local path = tostring(node.path or node.field or "")
    if path ~= "relationship.settlementVisit.active"
        or tostring(node.op or "eq") ~= "eq"
        or node.value ~= true
    then
        return nil
    end
    return { type = "pnc:settlement_visit" }
end

local function adopterGate(node)
    if type(node) ~= "table" then return nil end
    local path = tostring(node.path or node.field or "")
    local operator = tostring(node.op or "eq")
    if path == "conversation.audience"
        and operator == "eq" and node.value ~= nil
    then
        return { type = "pnc:audience", value = node.value }
    end
    if path == "scene.baseEstablished"
        and operator == "eq" and node.value == false
    then
        return {
            type = "pnc:base_not_established",
            reasonKey = "locked.base_established",
        }
    end
    return nil
end

local function timeGate(predicate)
    local startHour
    local endHour
    local function visit(node)
        if type(node) ~= "table" then return false end
        if type(node.all) == "table" then
            for _, child in ipairs(node.all) do
                if not visit(child) then return false end
            end
            return true
        end
        if type(node.any) == "table" then
            if #node.any ~= 2 then return false end
            for _, child in ipairs(node.any) do
                if type(child) ~= "table" then return false end
                local path = tostring(child.path or child.field or "")
                if path ~= "world.time.hour" then return false end
                local op = tostring(child.op or "eq")
                if op == "gte" or op == "gt" then
                    startHour = child.value
                elseif op == "lt" or op == "lte" then
                    endHour = child.value
                else
                    return false
                end
            end
            return true
        end
        local path = tostring(node.path or node.field or "")
        if path ~= "world.time.hour" then return true end
        local op = tostring(node.op or "eq")
        if op == "gte" or op == "gt" then
            startHour = node.value
        elseif op == "lt" or op == "lte" then
            endHour = node.value
        else
            return false
        end
        return true
    end
    if not visit(predicate) or startHour == nil or endHour == nil then
        return nil
    end
    return {
        type = "pnc:time",
        startHour = startHour,
        endHour = endHour,
    }
end

local function gatesForPredicate(predicate)
    if type(predicate) ~= "table" then return {} end
    local output = {}
    local clock = timeGate(predicate)
    if clock then output[#output + 1] = clock end
    local function append(node)
        if type(node) ~= "table" then return end
        if type(node.all) == "table" then
            for _, child in ipairs(node.all) do append(child) end
            return
        end
        if type(node.any) == "table" then return end
        local gate = relationshipGate(node)
        if not gate then gate = settlementVisitGate(node) end
        if not gate then gate = adopterGate(node) end
        if gate then output[#output + 1] = gate end
    end
    if type(predicate.all) == "table" then
        for _, child in ipairs(predicate.all) do
            append(child)
        end
        return output
    end
    append(predicate)
    return output
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
    local close = offerMetadata.close == true
    local outcome = {
        id = "reply",
        weight = 1,
        responseKey = responseKey,
        close = close,
        effects = type(offerMetadata.effects) == "table"
            and offerMetadata.effects or {},
        gates = gatesForPredicate(offer.when),
    }
    if not close or offerMetadata.next then
        outcome.next = offerMetadata.next or "$root"
    end
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
    local say = type(plan.payload) == "table"
        and type(plan.payload.say) == "table"
        and plan.payload.say or nil
    local turns = response and response.turns or nil
    local turn = type(turns) == "table" and turns[1] or nil
    local variants = response and response.variants or nil
    local sayRealization = say and type(say.realizations) == "table"
        and say.realizations["1"] or nil
    local sayVariants = type(sayRealization) == "table"
        and type(sayRealization.variants) == "table"
        and sayRealization.variants or nil
    local turnMetadata = type(turn) == "table"
        and type(turn.metadata) == "table" and turn.metadata or {}
    if type(turn) ~= "table" and type(variants) ~= "table"
        and type(sayVariants) ~= "table"
    then
        return false
    end
    if type(turn) == "table" and type(turn.text) ~= "table"
        and type(variants) ~= "table" and type(sayVariants) ~= "table"
    then
        return false
    end
    local blockID = tostring(values.runtimeBlockID or "")
    local category = tostring(values.category or "")
    local audience = tostring(values.audience or "")
    local audiences = type(values.audiences) == "table"
        and values.audiences or nil
    if not audiences and audience ~= "" then audiences = { audience } end
    local source = textSource(plan)
    if blockID == "" or category == "" or not audiences
        or #audiences == 0 or not source
    then
        return false
    end
    local nodes = {}
    local entryNode = "opening"
    local nodeCount = 0
    if response and type(response.variants) == "table" then
        local node = { choices = {} }
        node.textKeys = {}
        for _, variant in ipairs(response.variants) do
            if type(variant) == "table" and variant.id then
                local variantMetadata = type(variant.metadata) == "table"
                    and variant.metadata or {}
                node.textKeys[#node.textKeys + 1] = tostring(
                    variantMetadata.textKey or variant.id
                )
            end
        end
        if turnMetadata.portraitAnimation then
            node.portraitAnimation = tostring(turnMetadata.portraitAnimation)
        elseif values.portraitAnimation then
            node.portraitAnimation = tostring(values.portraitAnimation)
        end
        if type(turn) == "table" then
            for _, offer in ipairs(turn.offers or {}) do
                if type(offer) == "table" and offer.id then
                    addChoice(node, offer)
                end
            end
        end
        nodes[entryNode] = node
        nodeCount = 1
    elseif type(sayVariants) == "table" then
        local node = { choices = {}, textKeys = {} }
        if type(values.textRows) == "table" and #values.textRows > 0 then
            for _, row in ipairs(values.textRows) do
                if type(row) == "table" and type(row.key) == "string"
                    and row.key ~= ""
                    and string.sub(row.key, 1, 9) ~= "response."
                then
                    node.textKeys[#node.textKeys + 1] = row.key
                end
            end
        end
        if #node.textKeys == 0 then
            for _, variant in ipairs(sayVariants) do
                if type(variant) == "table" and variant.id then
                    local variantMetadata = type(variant.metadata) == "table"
                        and variant.metadata or {}
                    node.textKeys[#node.textKeys + 1] = tostring(
                        variantMetadata.textKey or variant.id
                    )
                end
            end
        end
        if values.portraitAnimation then
            node.portraitAnimation = tostring(values.portraitAnimation)
        end
        nodes[entryNode] = node
        nodeCount = 1
    else
        for index, currentTurn in ipairs(turns or {}) do
            if type(currentTurn) == "table" and currentTurn.id then
                local turnID = tostring(currentTurn.id)
                local currentMetadata = type(currentTurn.metadata) == "table"
                    and currentTurn.metadata or {}
                local currentNode = {
                    choices = {},
                    textKey = tostring(
                        currentMetadata.textKey or "turn." .. turnID
                    ),
                }
                if currentMetadata.portraitAnimation then
                    currentNode.portraitAnimation = tostring(
                        currentMetadata.portraitAnimation
                    )
                elseif values.portraitAnimation then
                    currentNode.portraitAnimation = tostring(
                        values.portraitAnimation
                    )
                end
                for _, offer in ipairs(currentTurn.offers or {}) do
                    if type(offer) == "table" and offer.id then
                        addChoice(currentNode, offer)
                    end
                end
                nodes[turnID] = currentNode
                nodeCount = nodeCount + 1
                if index == 1 then entryNode = turnID end
            end
        end
    end
    if nodeCount == 0 then return false end
    local definition = {
        schemaVersion = 1,
        ownerModID = OWNER,
        category = category,
        audiences = audiences,
        priority = tonumber(values.priority) or 0,
        weight = tonumber(values.weight) or 100,
        textSource = source,
        entryNode = entryNode,
        gates = gatesForPredicate(plan.when),
        nodes = nodes,
    }
    local ok = Registry.RegisterBlock(blockID, definition)
    return ok == true
end

local IDS = {
    "needs.member.support",
    "needs.neutral.support",
    "needs.special.support",
    "social.personal.special.trust",
    "social.relationship.special.affinity",
    "social.set_territory.member.claim",
    "work_orders.member.status",
    "social.settlement_admission",
    "social.ask_about.member",
    "social.ask_about.neutral",
    "social.ask_about.special",
    "social.greetings.acquaintance.dawn",
    "social.greetings.acquaintance.dusk",
    "social.greetings.acquaintance.sunrise",
    "social.greetings.acquaintance.sunset",
    "social.greetings.acquaintance.twilight",
    "social.greetings.firstmeet.dawn",
    "social.greetings.firstmeet.dusk",
    "social.greetings.firstmeet.sunrise",
    "social.greetings.firstmeet.sunset",
    "social.greetings.firstmeet.twilight",
    "social.greetings.hostile.parley",
    "social.greetings.lover.dawn",
    "social.greetings.lover.dusk",
    "social.greetings.lover.sunrise",
    "social.greetings.lover.sunset",
    "social.greetings.lover.twilight",
    "social.greetings.member.dawn",
    "social.greetings.member.dusk",
    "social.greetings.member.sunrise",
    "social.greetings.member.sunset",
    "social.greetings.member.twilight",
    "social.wellbeing.neutral",
    "social.wellbeing.member",
    "social.wellbeing.special",
    "social.small_talk.neutral",
    "social.small_talk.member",
    "social.small_talk.special",
}

for _, id in ipairs(IDS) do
    local plan = Generated.ConvoPlan(id)
    if plan then registerPlan(plan) end
end

return true
