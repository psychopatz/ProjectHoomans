-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "compatibility_content",
        ["id"] = "semantic.integration.projectalife.encounter.hostile.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.integration.projectalife.encounter.hostile.neutral",
            ["sourcePath"] = "psdl/dialogue/compatibility_content.json#records[17]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_integration_projectalife_encounter_hostile_neutral",
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
                ["responseTemplateID"] = "semantic.compat.projectalife.encounter.hostile",
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
                                "That group looks hostile. Keep cover between us and them.",
                            },
                            ["TL"] = {
                                "That group looks hostile. Keep cover between us and them.",
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
