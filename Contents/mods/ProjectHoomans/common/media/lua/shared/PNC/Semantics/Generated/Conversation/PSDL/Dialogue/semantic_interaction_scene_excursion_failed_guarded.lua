-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.excursion_failed.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.excursion_failed.guarded",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[19]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_scene_excursion_failed_guarded",
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
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Excursion failed. We regroup here.",
                            },
                            ["TL"] = {
                                "Bigo ang paglalakbay. Magtipon ulit tayo rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Something compromised the operation. Pull back immediately.",
                            },
                            ["TL"] = {
                                "May sumira sa operasyon. Umatras agad-agad.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Forcing this run will get us slaughtered. Abort.",
                            },
                            ["TL"] = {
                                "Kamatayan kapag pinilit ang lakad na 'to. Ihinto.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Fall back and figure out what went wrong behind closed doors.",
                            },
                            ["TL"] = {
                                "Umatras at alamin kung anong pumalpak sa loob ng pinto.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "The route is burned. We're retreating right now.",
                            },
                            ["TL"] = {
                                "Nasira ang ruta. Aatras tayo ngayon din.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Trip canceled. Watch your back as we return to the gates.",
                            },
                            ["TL"] = {
                                "Kanselado ang lakad. Bantayan ang likod habang bumabalik.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Bad intel or bad luck. Either way, we pull the plug.",
                            },
                            ["TL"] = {
                                "Maling balita o malas. Alinman doon, itigil na.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Do not push forward into an ambush. Abort the mission.",
                            },
                            ["TL"] = {
                                "Huwag lumusob sa tambang. Itigil ang misyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Abort. Secure the entrance and debrief.",
                            },
                            ["TL"] = {
                                "Tigil. I-secure ang lagusan at mag-usap.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Failed attempt. Fall back and secure your weapons.",
                            },
                            ["TL"] = {
                                "Bigong pagtatangka. Umatras at i-secure ang armas.",
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
