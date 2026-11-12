-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "compatibility_content",
        ["id"] = "semantic.integration.bandits.hooman_hurt.colonist.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.integration.bandits.hooman_hurt.colonist.neutral",
            ["sourcePath"] = "psdl/dialogue/compatibility_content.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_integration_bandits_hooman_hurt_colonist_neutral",
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
                ["responseTemplateID"] = "semantic.compat.bandits.hooman_hurt.colonist",
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
                                "Bandit fire! Pull back and cover the wounded colonist.",
                            },
                            ["TL"] = {
                                "Bandit fire! Pull back and cover the wounded colonist.",
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
