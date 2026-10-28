-- Declarative participation of semantic acts; no parser or gameplay policy.
local Relations = {}
local acts, compact, count = {}, {}, 0
local relationPolicies, relationCount = {}, 0

function Relations.RegisterRelation(id, spec)
    if type(id) ~= "string" or #id == 0 or #id > 64 or type(spec) ~= "table"
        or (spec.direction ~= "same" and spec.direction ~= "reverse" and spec.direction ~= "either") then
        return false, "relation_policy_invalid"
    end
    if relationPolicies[id] then return false, "relation_policy_duplicate" end
    if relationCount >= 64 then return false, "relation_policy_limit" end
    relationPolicies[id], relationCount = spec.direction, relationCount + 1
    return true
end

function Relations.Direction(id) return relationPolicies[id] or "same" end
Relations.RegisterRelation("repair", { direction = "same" })
Relations.RegisterRelation("gratitude", { direction = "reverse" })
Relations.RegisterRelation("response", { direction = "reverse" })

function Relations.RegisterAct(id, metadata)
    if type(id) ~= "string" or #id == 0 or #id > 64
        or type(metadata) ~= "table" then return false, "invalid_semantic_act" end
    if acts[id] then return false, "semantic_act_duplicate" end
    if count >= 128 then return false, "semantic_act_limit" end
    -- Reuse the evidence whitelist and bounds, retaining no caller tables.
    local Evidence = require "PNC/Semantics/PNC_SemanticInteractionEvidence"
    local normalized = Evidence.Normalize({ sourceRef = id, sourceTier = "SESSION",
        classes = metadata.classes, relations = metadata.relations,
        retentionSalience = metadata.retentionSalience }, "semantic_act_catalog")
    acts[id], count = normalized, count + 1
    if type(metadata.compactEvent) == "string" and #metadata.compactEvent <= 64 then
        compact[id] = { id = metadata.compactEvent, salience = normalized.retentionSalience or 0,
            longTerm = metadata.longTerm == true, semantic = normalized }
    end
    return true
end

function Relations.GetCompactType(id)
    local spec = compact[id]
    if not spec then return nil end
    return { id = spec.id, salience = spec.salience, longTerm = spec.longTerm,
        semantic = Relations.GetAct(id), sourceTypes = { spec.id } }
end

function Relations.CompactTypes()
    local ids, output = {}, {}
    for id in pairs(compact) do ids[#ids + 1] = id end
    table.sort(ids)
    for _, id in ipairs(ids) do output[#output + 1] = Relations.GetCompactType(id) end
    return output
end

function Relations.ContextualActs()
    local ids = {}
    for id, metadata in pairs(acts) do
        if #metadata.relations.addresses > 0 then ids[#ids + 1] = id end
    end
    table.sort(ids)
    return ids
end

function Relations.ContextualRelations()
    local ids, seen = {}, {}
    for _, metadata in pairs(acts) do
        for _, kind in ipairs({ "addresses", "resolves", "violates", "explains" }) do
            for _, id in ipairs(metadata.relations[kind]) do
                if not seen[id] then ids[#ids + 1], seen[id] = id, true end
            end
        end
    end
    table.sort(ids)
    while #ids > 8 do table.remove(ids) end
    return ids
end

function Relations.GetAct(id)
    local Evidence = require "PNC/Semantics/PNC_SemanticInteractionEvidence"
    return Evidence.Normalize(acts[id], "semantic_act_catalog", "SESSION")
end

local definitions = require "PNC/Core/Relationships/PNC_SocialEventDefinitions"
for act, event in pairs({ INSULT = "player_dialogue_insult",
    HOSTILE_REMARK = "player_dialogue_hostile_remark", THREATEN = "player_dialogue_threat" }) do
    Relations.RegisterAct(act, definitions[event].semantic)
end
Relations.RegisterAct("APOLOGIZE", { relations = { addresses = { "repair" } },
    retentionSalience = 255, compactEvent = "semantic_apologize", longTerm = true })
Relations.RegisterAct("THANK", { relations = { addresses = { "gratitude" } },
    retentionSalience = 255, compactEvent = "semantic_thank", longTerm = true })
for _, act in ipairs({ "OFFER", "REQUEST", "QUESTION" }) do
    Relations.RegisterAct(act, { classes = { "pending_response" }, relations = { opens = { "response" } },
        retentionSalience = 90, compactEvent = "semantic_" .. string.lower(act) })
end
for _, act in ipairs({ "INFORM", "ANSWER", "QUESTION_RECEIVED", "BOUNDARY_WARNING",
    "RETALIATE_VERBALLY", "CHALLENGE", "ASK_CLARIFICATION", "RECONCILE", "ACKNOWLEDGE_REPAIR" }) do
    Relations.RegisterAct(act, { classes = { "information" }, relations = { opens = { "response" } } })
end
for _, act in ipairs({ "ACCEPT", "REFUSE", "ACKNOWLEDGE", "AGREE", "DISAGREE" }) do
    Relations.RegisterAct(act, { relations = { addresses = { "response" } },
        retentionSalience = 100, compactEvent = "semantic_" .. string.lower(act) })
end
return Relations
