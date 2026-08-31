-- Shared policy for Project Hoomans LLM semantic tools.
--
-- Tool schemas are static and belong to the Core catalog.  This module only
-- owns the Hoomans-specific reaction vocabulary and the safe mapping from an
-- intent to a bounded relationship effect.  The server remains authoritative
-- and must re-check availability before applying anything.

PNC = PNC or {}
PNC.ConversationLLMTools = PNC.ConversationLLMTools or {}

local Tools = PNC.ConversationLLMTools

Tools.VERSION = 1
Tools.REACTION_ORDER = {
    "comfort", "praise", "admire", "apologize", "flirt", "insult",
}
Tools.INTENSITIES = { "low", "normal", "high" }
Tools.REACTIONS = {
    comfort = {
        description = "Offer comfort or reassurance.",
        approval = 3, respect = 1, familiarity = 2,
    },
    praise = {
        description = "Praise the player sincerely.",
        approval = 4, respect = 2, familiarity = 1,
    },
    admire = {
        description = "Express sincere admiration or respect for the player.",
        approval = 3, respect = 4, familiarity = 1,
    },
    apologize = {
        description = "Apologize for the NPC's own behavior.",
        approval = 5, respect = 2, familiarity = 1,
    },
    flirt = {
        description = "Express romantic interest; only appropriate relationships allow this.",
        approval = 3, respect = 0, familiarity = 4,
    },
    insult = {
        description = "The player insulted, cursed at, or antagonized the NPC.",
        approval = -4, respect = -3, familiarity = 0,
    },
}

local INTENSITY_SCALE = { low = 0.5, normal = 1, high = 1.5 }
local REACTION_MEMORY_TYPES = {
    comfort = "player_comforted",
    praise = "player_praised",
    admire = "player_admired",
    apologize = "player_apologized",
    flirt = "player_flirted",
}

local function normalized(value)
    value = string.lower(tostring(value or ""))
    value = string.gsub(value, "[%s%-]", "_")
    return value
end

function Tools.NormalizeReaction(value)
    local key = normalized(value)
    return Tools.REACTIONS[key] and key or nil
end

function Tools.NormalizeIntensity(value)
    local key = normalized(value)
    return INTENSITY_SCALE[key] and key or "normal"
end

local function relationshipState(relationship)
    relationship = type(relationship) == "table" and relationship or {}
    return normalized(
        relationship.state
            or relationship.category
            or relationship.relationshipState
            or ""
    )
end

function Tools.IsAvailable(reaction, relationship)
    reaction = Tools.NormalizeReaction(reaction)
    if not reaction then return false, "unknown_reaction" end
    if reaction ~= "flirt" then return true end

    relationship = type(relationship) == "table" and relationship or {}
    local state = relationshipState(relationship)
    local approval = tonumber(relationship.approval) or 0
    local familiarity = tonumber(relationship.familiarity) or 0
    if state == "lover" or state == "partner" or state == "spouse"
        or (approval >= 60 and familiarity >= 40)
    then
        return true
    end
    return false, "relationship_gate"
end

function Tools.ListAvailable(relationship)
    local output = {}
    for _, reaction in ipairs(Tools.REACTION_ORDER) do
        if Tools.IsAvailable(reaction, relationship) then
            output[#output + 1] = reaction
        end
    end
    return output
end

function Tools.ListAll()
    local output = {}
    for _, reaction in ipairs(Tools.REACTION_ORDER) do
        output[#output + 1] = reaction
    end
    return output
end

function Tools.GetEffect(reaction, intensity)
    reaction = Tools.NormalizeReaction(reaction)
    if not reaction then return nil, "unknown_reaction" end
    intensity = Tools.NormalizeIntensity(intensity)
    local definition = Tools.REACTIONS[reaction]
    local scale = INTENSITY_SCALE[intensity]
    return {
        type = "llm_social_reaction",
        reaction = reaction,
        intensity = intensity,
        approval = definition.approval * scale,
        respect = definition.respect * scale,
        familiarity = definition.familiarity * scale,
        decayPerDay = 0.05,
        permanent = false,
        shareable = false,
        memoryType = reaction == "insult"
            and "player_insulted" or REACTION_MEMORY_TYPES[reaction],
        interactionType = reaction == "insult"
            and "player_insulted" or REACTION_MEMORY_TYPES[reaction],
        tags = {
            llm = true,
            reaction = reaction,
            interaction = reaction == "insult"
                and "player_insulted" or REACTION_MEMORY_TYPES[reaction],
        },
    }
end

function Tools.BuildDefinition()
    local enum = {}
    for _, reaction in ipairs(Tools.REACTION_ORDER) do
        enum[#enum + 1] = reaction
    end
    return {
        type = "function",
        ["function"] = {
            name = "social_react",
            description = "Register the NPC's bounded reaction to the player's social message. "
                .. "For insults, cursing, or hostile abuse directed at the NPC, use kind "
                .. "'insult'. For sincere positive intent use 'admire', 'praise', "
                .. "'comfort', or 'apologize'; use 'flirt' only when the relationship "
                .. "and NPC personality make it appropriate. Positive actions are "
                .. "limited to one per in-game day. Insults have no daily limit. "
                .. "Gameplay authority decides whether it applies.",
            parameters = {
                type = "object",
                properties = {
                    kind = {
                        type = "string",
                        enum = enum,
                        description = "The social reaction intent.",
                    },
                    intensity = {
                        type = "string",
                        enum = Tools.INTENSITIES,
                        description = "Low, normal, or high intensity.",
                    },
                },
                required = { "kind" },
                additionalProperties = false,
            },
        },
    }
end

-- Identity disclosure is a real conversation action, not an LLM-authored
-- fact.  Keeping it in the same catalog lets native and text-only providers
-- reach the existing authoritative knowledge service.
function Tools.BuildIdentityDefinition()
    return {
        type = "function",
        ["function"] = {
            name = "ask_name",
            description = "Ask the NPC to say their name. Use when the player asks "
                .. "what's your name, who are you, or asks the NPC to introduce "
                .. "themselves. This invokes authoritative identity knowledge "
                .. "disclosure; do not invent or persist a name in the reply.",
            parameters = {
                type = "object",
                properties = {},
                additionalProperties = false,
            },
        },
    }
end

return Tools
