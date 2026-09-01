-- Provider-facing schemas for Project Hoomans semantic conversation tools.

PNC = PNC or {}
PNC.ConversationLLMTools = PNC.ConversationLLMTools or {}

local Tools = PNC.ConversationLLMTools

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
                    subtype = {
                        type = "string",
                        enum = Tools.SOCIAL_SUBTYPE_ORDER,
                        description = "Presentation subtype: use compliment for praise, "
                            .. "romantic_interest for non-explicit attraction, "
                            .. "sexual_advance for an explicit sexual proposition, or "
                            .. "hostile_abuse for directed insults/cursing. This is "
                            .. "metadata; the game still decides the relationship result.",
                    },
                    explicit = {
                        type = "boolean",
                        description = "True only for an explicit sexual advance. "
                            .. "This never grants consent or bypasses policy.",
                    },
                },
                required = { "kind" },
                additionalProperties = false,
            },
        },
    }
end

-- Identity disclosure is a real conversation action, not an LLM-authored
-- fact. Keeping it in the same catalog lets native and text-only providers
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

local function knowledgeTopics()
    local output = {}
    local seen = {}
    local descriptors = PNC.KnowledgeDescriptors
        and PNC.KnowledgeDescriptors.List and PNC.KnowledgeDescriptors.List()
        or {}
    for _, descriptor in ipairs(descriptors) do
        local topicID = descriptor.presentation
            and tostring(descriptor.presentation.topicID or "") or ""
        if topicID ~= "" and topicID ~= "identity_name"
            and descriptor.discovery.allowDisclosure == true
            and not seen[topicID]
        then
            seen[topicID] = true
            output[#output + 1] = topicID
        end
    end
    table.sort(output)
    return output
end

-- Bounded topic selection keeps the tool useful for natural questions such as
-- "are you good at carpentry?" without allowing the model to author a fact.
function Tools.BuildKnowledgeDefinition()
    local topics = knowledgeTopics()
    if #topics == 0 then return nil end
    return {
        type = "function",
        ["function"] = {
            name = "disclose_knowledge",
            description = "Ask the NPC to disclose one known topic. Use only when "
                .. "the player directly asks about that topic. The game decides "
                .. "whether the NPC can disclose it; never invent or persist facts.",
            parameters = {
                type = "object",
                properties = {
                    topic_id = {
                        type = "string",
                        enum = topics,
                        description = "The exact registered knowledge topic.",
                    },
                },
                required = { "topic_id" },
                additionalProperties = false,
            },
        },
    }
end

return Tools
