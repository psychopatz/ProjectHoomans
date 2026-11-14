-- Generated Conversation discovery index; do not edit by hand.
return {
    ["interaction.memory.acknowledge"] = {
        ["dependents"] = {
            "behavior.acknowledge_memory",
        },
        ["domain"] = "social_interaction_memory",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/SocialInteractionMemory",
        },
        ["id"] = "interaction.memory.acknowledge",
        ["kind"] = "dialogue",
        ["source"] = "adopters/hoomans/dialogue/social_interaction_memory/interaction_memory_acknowledge.json",
    },
    ["interaction.memory.acknowledge_flavor"] = {
        ["dependents"] = {
            "behavior.acknowledge_memory",
        },
        ["domain"] = "social_interaction_memory",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/SocialInteractionMemory",
        },
        ["id"] = "interaction.memory.acknowledge_flavor",
        ["kind"] = "dialogue",
        ["source"] = "adopters/hoomans/dialogue/social_interaction_memory/interaction_memory_acknowledge_flavor.json",
    },
    ["interaction.memory.followup"] = {
        ["dependents"] = {
            "behavior.ask_memory_followup",
            "behavior.scene_news_followup",
        },
        ["domain"] = "social_interaction_memory",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/SocialInteractionMemory",
        },
        ["id"] = "interaction.memory.followup",
        ["kind"] = "dialogue",
        ["source"] = "adopters/hoomans/dialogue/social_interaction_memory/interaction_memory_followup.json",
    },
}
