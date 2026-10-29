-- Typed semantic interaction stimuli.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local ValueBounds = require "PNC/Semantics/PNC_SemanticValueBounds"
local Stimulus = PNC.Semantics.InteractionStimulus or {}
PNC.Semantics.InteractionStimulus = Stimulus

Stimulus.VERSION = 1
Stimulus.MAX_TARGETS = 8
Stimulus.MAX_TEXT = 512

local TYPES = {
    HUMAN_UTTERANCE = true,
    NPC_SEMANTIC_ACT = true,
    EMOTE = true,
    AMBIENT_SOCIAL_OPPORTUNITY = true,
    WORLD_EVENT = true,
    FACTION_EVENT = true,
    TASK_EVENT = true,
    DANGER_CHANGED = true,
    ACTOR_JOINED = true,
    ACTOR_LEFT = true,
    WITNESSED_DEATH = true,
}

local function boundedText(value, maximum)
    if value == nil then return nil end
    value = tostring(value)
    if #value > maximum then value = string.sub(value, 1, maximum) end
    return value
end

local function targets(value)
    local output = {}
    if type(value) ~= "table" then return output end
    for index = 1, math.min(#value, Stimulus.MAX_TARGETS) do
        local id = boundedText(value[index], 128)
        if id and id ~= "" then output[#output + 1] = id end
    end
    return output
end

function Stimulus.Normalize(value)
    if type(value) ~= "table" then
        return nil, "interaction_stimulus_invalid"
    end
    local kind = tostring(value.type or "")
    if TYPES[kind] ~= true then
        return nil, "interaction_stimulus_type_invalid"
    end
    local source = type(value.source) == "table" and value.source or {}
    local semantic = type(value.semantic) == "table" and value.semantic or {}
    local output = {
        schemaVersion = Stimulus.VERSION,
        type = kind,
        source = {
            kind = boundedText(source.kind, 32) or "unknown",
            actorID = boundedText(source.actorID, 128),
            providerID = boundedText(source.providerID, 128),
        },
        targets = targets(value.targets),
        semantic = {
            intent = boundedText(semantic.intent, 64),
            speechAct = boundedText(semantic.speechAct, 64),
            subject = boundedText(semantic.subject, 128),
            confidence = tonumber(semantic.confidence),
            topic = boundedText(semantic.topic, 128),
            factID = boundedText(semantic.factID, 128),
            eventID = boundedText(semantic.eventID, 128),
            modifiers = ValueBounds.Copy(semantic.modifiers) or {},
        },
        text = boundedText(value.text, Stimulus.MAX_TEXT),
        payload = ValueBounds.Copy(value.payload),
    }
    if output.semantic.confidence ~= nil then
        output.semantic.confidence = math.max(
            0, math.min(1, output.semantic.confidence)
        )
    end
    return output
end

function Stimulus.FromIR(ir, context)
    ir = type(ir) == "table" and ir or {}
    context = type(context) == "table" and context or {}
    local value, reason = Stimulus.Normalize({
        type = "HUMAN_UTTERANCE",
        source = {
            kind = "human",
            actorID = context.playerIdentitySeed or context.playerID or "player",
            providerID = "psychopatzcore.nlu",
        },
        targets = { context.npcID or context.targetNPCID or "dialogue.npc" },
        semantic = {
            intent = ir.intent,
            speechAct = ir.speechAct,
            subject = ir.subject,
            confidence = ir.confidence,
            topic = context.currentTopic or context.conversationTopic,
        },
        text = ir.rawText,
    })
    if not value then error(reason) end
    return value
end

function Stimulus.Types()
    local output = {}
    for key in pairs(TYPES) do output[#output + 1] = key end
    table.sort(output)
    return output
end

return Stimulus
