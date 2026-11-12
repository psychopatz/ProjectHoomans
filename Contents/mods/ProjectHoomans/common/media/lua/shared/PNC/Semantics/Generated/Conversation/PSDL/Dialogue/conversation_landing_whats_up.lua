-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_greeting",
        ["id"] = "conversation.landing.whats_up",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "conversation.landing.whats_up",
            ["sourcePath"] = "psdl/dialogue/conversation_greeting.json#records[13]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/conversation_landing_whats_up",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "player",
            },
        },
        ["payload"] = {
            ["metadata"] = {
                ["category"] = "projecthoomans:conversation_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["playerChoice"] = {
                    ["choice"] = {
                        ["EN"] = "What's up?",
                        ["TL"] = "Ano ang balita?",
                    },
                    ["hubID"] = "whats_up",
                    ["id"] = "conversation.landing:whats_up",
                    ["kind"] = "player_landing_choice",
                    ["label"] = {
                        ["EN"] = "What's up",
                        ["TL"] = "Ano ang balita",
                    },
                    ["route"] = "semantic_hub",
                },
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/greeting.json",
            },
            ["response"] = {
                ["act"] = "QUESTION",
                ["variants"] = {
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/conversation_greeting.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
