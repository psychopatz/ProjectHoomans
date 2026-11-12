-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_hostile_offer_threat",
        ["id"] = "semantic.social.hostile_stressed.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.hostile_stressed.neutral",
            ["sourcePath"] = "psdl/dialogue/social_reactions_hostile_offer_threat.json#records[5]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_hostile_stressed_neutral",
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
                ["responseTemplateID"] = "semantic.social.hostile_stressed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/hostile.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "That's enough. Everyone needs to step back.",
                            },
                            ["TL"] = {
                                "Tama na. Kailangang umatras ng lahat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Please give me some space to cool off.",
                            },
                            ["TL"] = {
                                "Pakiusap bigyan mo ako ng puwang para kumalma.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "We're all too stressed for this. Step away.",
                            },
                            ["TL"] = {
                                "Masyado tayong tensiyonado para rito. Lumayo muna.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Back up. Let's not make things worse.",
                            },
                            ["TL"] = {
                                "Umatras ka. Huwag nating palalain ang sitwasyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I need room to think. Step back.",
                            },
                            ["TL"] = {
                                "Kailangan ko ng espasyo para mag-isip. Umatras ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Let's put some distance between us right now.",
                            },
                            ["TL"] = {
                                "Maglagay muna tayo ng distansya ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Back away until tempers settle down.",
                            },
                            ["TL"] = {
                                "Umatras muna hanggang sa humupa ang init ng ulo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Stop crowding me. Take a few steps back.",
                            },
                            ["TL"] = {
                                "Huwag mo akong sikipin. Umatras ka nang ilang hakbang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "We need space right now. Move back.",
                            },
                            ["TL"] = {
                                "Kailangan natin ng puwang ngayon. Umatras ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Give it some breathing room.",
                            },
                            ["TL"] = {
                                "Bigyan mo ng puwang para makahinga.",
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
        ["sourceShard"] = "psdl/dialogue/social_reactions_hostile_offer_threat.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
