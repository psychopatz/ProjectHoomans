-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_hostile_offer_threat",
        ["id"] = "semantic.social.threat_boundary.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.threat_boundary.neutral",
            ["sourcePath"] = "psdl/dialogue/social_reactions_hostile_offer_threat.json#records[21]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_threat_boundary_neutral",
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
                ["responseTemplateID"] = "semantic.social.threat_boundary",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/threats.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Step back or we have a problem.",
                            },
                            ["TL"] = {
                                "Umatras ka o magkakaproblema tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "You need to back off right now.",
                            },
                            ["TL"] = {
                                "Kailangan mong lumayo ngayon din.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Keep your distance. Don't make this turn ugly.",
                            },
                            ["TL"] = {
                                "Panatilihin ang distansya. Huwag mong gawing madugo ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I'm giving you fair warning: stand down.",
                            },
                            ["TL"] = {
                                "Binibigyan kita ng patas na babala: ibaba ang armas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Back away. Neither of us needs this fight.",
                            },
                            ["TL"] = {
                                "Umatras ka. Walang nangangailangan ng laban na 'to.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Step down. Let's not do something stupid.",
                            },
                            ["TL"] = {
                                "Huminahon ka. Huwag tayong gumawa ng katangahan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I won't hesitate if you keep advancing.",
                            },
                            ["TL"] = {
                                "Hindi ako magdadalawang-isip kapag lumapit ka pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Hold your ground right there. Do not advance.",
                            },
                            ["TL"] = {
                                "Diyan ka lang. Huwag kang susulong.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Lower your weapon and step back.",
                            },
                            ["TL"] = {
                                "Ibaba mo ang armas mo at umatras.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "This is your only warning. Back off.",
                            },
                            ["TL"] = {
                                "Ito na ang nag-iisang babala mo. Umatras ka.",
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
