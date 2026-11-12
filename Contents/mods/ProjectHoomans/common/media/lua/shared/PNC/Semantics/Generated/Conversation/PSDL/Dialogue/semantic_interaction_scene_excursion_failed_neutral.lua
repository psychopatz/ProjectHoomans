-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.excursion_failed.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.excursion_failed.neutral",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[16]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_scene_excursion_failed_neutral",
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
                ["responseTemplateID"] = "semantic.interaction.scene.excursion_failed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/excursion.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Trip's off. Something went wrong.",
                            },
                            ["TL"] = {
                                "Kanselado ang biyahe. May nangyaring mali.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "We have to cancel the run. It's not safe.",
                            },
                            ["TL"] = {
                                "Kailangang kanselahin ang lakad. Hindi ligtas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Plan fell apart. We're aborting the trip.",
                            },
                            ["TL"] = {
                                "Pumalpak ang plano. Ititigil natin ang paglabas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Call it off. Conditions are too hazardous.",
                            },
                            ["TL"] = {
                                "Kanselahin na. Masyadong mapanganib ang kalagayan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "We're aborting the mission. Regroup back inside.",
                            },
                            ["TL"] = {
                                "Ititigil ang misyon. Magtipon pabalik sa loob.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Trip canceled. Something compromised our route.",
                            },
                            ["TL"] = {
                                "Kanselado ang biyahe. May sumira sa ruta natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Not happening today. Pull back to base.",
                            },
                            ["TL"] = {
                                "Hindi matutuloy ngayon. Umatras pabalik sa base.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Mission failed. Better to abort than lose lives.",
                            },
                            ["TL"] = {
                                "Bigo ang misyon. Mas mabuting ihinto kaysa may mamatay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "The run is scrubbed. Head back inside.",
                            },
                            ["TL"] = {
                                "Kanselado ang paglabas. Bumalik sa loob.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Aborting the excursion. We'll rethink the plan.",
                            },
                            ["TL"] = {
                                "Ititigil ang lakad. Pag-iisipan natin muli ang plano.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_scene_travel_news.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
