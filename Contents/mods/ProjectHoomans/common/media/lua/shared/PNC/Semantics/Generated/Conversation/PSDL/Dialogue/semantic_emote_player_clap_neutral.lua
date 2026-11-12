-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_emotes",
        ["id"] = "semantic.emote.player.clap.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.emote.player.clap.neutral",
            ["sourcePath"] = "psdl/dialogue/social_emotes.json#records[4]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_emote_player_clap_neutral",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["metadata"] = {
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.emote.player.clap",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/emotes/emotes_player.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Well done, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Magaling, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "That's worth celebrating, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Karapat-dapat ipagdiwang iyan, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Nice work, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Mahusay na trabaho, {addressee.name}.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/social_emotes.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
