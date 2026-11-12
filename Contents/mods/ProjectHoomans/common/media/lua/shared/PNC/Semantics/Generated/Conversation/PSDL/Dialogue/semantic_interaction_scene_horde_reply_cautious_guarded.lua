-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["id"] = "semantic.interaction.scene.horde_reply_cautious.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.horde_reply_cautious.guarded",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_horde_work.json#records[11]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_scene_horde_reply_cautious_guarded",
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
                ["responseTemplateID"] = "semantic.interaction.scene.horde_reply_cautious",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/horde.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Bad odds. Give them space.",
                            },
                            ["TL"] = {
                                "Masama ang tsansa. Lumayo tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Fighting that pack is suicide. Withdraw in formation.",
                            },
                            ["TL"] = {
                                "Pagpapakamatay ang labanang 'yan. Umatras nang may pormasyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Step back quietly. Do not alert the rear flank.",
                            },
                            ["TL"] = {
                                "Umatras nang tahimik. Huwag gisingin ang nasa likod.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Keep your weapon raised, but reverse your footsteps.",
                            },
                            ["TL"] = {
                                "Itaas ang armas, pero ihakbang pabalik ang paa.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "We have zero tactical advantage. We fall back immediately.",
                            },
                            ["TL"] = {
                                "Wala tayong kalamangan sa posisyon. Aatras tayo agad.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Don't let adrenaline make you stupid. We withdraw.",
                            },
                            ["TL"] = {
                                "Huwag magpadala sa kaba at maging tanga. Aatras tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Back away into the shadows. Let them wander past.",
                            },
                            ["TL"] = {
                                "Umatras sa dilim. Hayaang lumampas sila.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "I refuse to be butchered in an open field. Retreat.",
                            },
                            ["TL"] = {
                                "Ayokong malapa sa bukas na damuhan. Umatras.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Keep low and retreat to the last secure building.",
                            },
                            ["TL"] = {
                                "Yumuko at umatras sa huling ligtas na gusali.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Orderly withdrawal. If anyone runs screaming, they're dead.",
                            },
                            ["TL"] = {
                                "Maayos na pag-atras. Kapag may nagpanic at sumigaw, patay 'yon.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_scene_horde_work.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
