-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "compatibility_content",
        ["id"] = "semantic.integration.projectalife.meta.aircraft.heli.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.integration.projectalife.meta.aircraft.heli.neutral",
            ["sourcePath"] = "psdl/dialogue/compatibility_content.json#records[22]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_integration_projectalife_meta_aircraft_heli_neutral",
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
                ["responseTemplateID"] = "semantic.compat.projectalife.meta.aircraft.heli",
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
                                "Something is flying over us. Keep listening.",
                            },
                            ["TL"] = {
                                "Something is flying over us. Keep listening.",
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
