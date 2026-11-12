-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "compatibility_content",
        ["id"] = "semantic.integration.necroa.player_mask_removed.lover.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.integration.necroa.player_mask_removed.lover.neutral",
            ["sourcePath"] = "psdl/dialogue/compatibility_content.json#records[15]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_integration_necroa_player_mask_removed_lover_neutral",
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
                ["category"] = "projecthoomans:compatibility_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.compatibility",
                ["responseTemplateID"] = "semantic.compat.necroa.player_mask_removed.lover",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/compatibility.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Please put your mask back on, love. This air is not safe.",
                            },
                            ["TL"] = {
                                "Please put your mask back on, love. This air is not safe.",
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
        ["sourceShard"] = "psdl/dialogue/compatibility_content.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
