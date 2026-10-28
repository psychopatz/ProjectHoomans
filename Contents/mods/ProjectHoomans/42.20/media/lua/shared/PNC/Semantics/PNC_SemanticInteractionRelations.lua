-- Declarative participation of semantic acts; no parser or gameplay policy.
local Relations = {}
local acts, count = {}, 0

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
    return true
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
Relations.RegisterAct("APOLOGIZE", { relations = { addresses = { "repair" } } })
Relations.RegisterAct("THANK", { relations = { addresses = { "gratitude" } } })
for _, act in ipairs({ "OFFER", "REQUEST", "QUESTION" }) do
    Relations.RegisterAct(act, { classes = { "pending_response" }, relations = { opens = { "response" } } })
end
for _, act in ipairs({ "ACCEPT", "REFUSE", "ACKNOWLEDGE", "AGREE", "DISAGREE" }) do
    Relations.RegisterAct(act, { relations = { addresses = { "response" } } })
end
return Relations
