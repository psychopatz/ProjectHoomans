-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.acknowledged.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.acknowledged.warm",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[7]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_acknowledged_warm",
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
                ["responseTemplateID"] = "semantic.social.acknowledged",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/acknowledgement.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "All right. I hear you.",
                            },
                            ["TL"] = {
                                "Sige. Narinig kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Got it, friend. Glad we talked.",
                            },
                            ["TL"] = {
                                "Nakuha ko, kaibigan. Mabuti at nagkausap tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "I completely understand. Thanks for explaining.",
                            },
                            ["TL"] = {
                                "Lubos kong nauunawaan. Salamat sa pagpapaliwanag.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Sounds great. Glad we're in this together.",
                            },
                            ["TL"] = {
                                "Napakaganda. Mabuti at magkasama tayo rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Take care of yourself out there.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Ingatan mo ang sarili mo sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'm with you on that. Good call.",
                            },
                            ["TL"] = {
                                "Kasama mo ako riyan. Magandang desisyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Heard and appreciated. We've got this.",
                            },
                            ["TL"] = {
                                "Narinig at pinahahalagahan. Kayang-kaya natin ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "Clear as crystal. Happy to follow your lead.",
                            },
                            ["TL"] = {
                                "Napakalinaw. Masayang sumunod sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Got it. Always a pleasure working with you.",
                            },
                            ["TL"] = {
                                "Nakuha ko. Laging masarap kang makatrabaho.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "All right. Let's look out for each other.",
                            },
                            ["TL"] = {
                                "Sige. Magtulungan tayo sa isa't isa.",
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
        ["sourceShard"] = "psdl/dialogue/social_reactions_ack_dispute.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
