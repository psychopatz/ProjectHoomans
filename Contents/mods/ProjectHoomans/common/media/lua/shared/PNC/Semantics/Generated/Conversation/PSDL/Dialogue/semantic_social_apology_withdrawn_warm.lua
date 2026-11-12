-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_apology",
        ["id"] = "semantic.social.apology.withdrawn.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.apology.withdrawn.warm",
            ["sourcePath"] = "psdl/dialogue/social_apology.json#records[13]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_apology_withdrawn_warm",
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
                ["category"] = "projecthoomans:social.apology",
                ["responseTemplateID"] = "semantic.social.apology.withdrawn",
                ["sourceSurface"] = "content/social_apology.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "APOLOGY_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.social.apology.withdrawn.warm.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "All right. Let's leave it there for now.",
                            },
                            ["TL"] = {
                                "Sige. Tama na muna iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.social.apology.withdrawn.warm.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "We can give it some space. We're still good.",
                            },
                            ["TL"] = {
                                "Bigyan muna natin ng puwang. Maayos pa rin tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.social.apology.withdrawn.warm.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Take your time. We don't have to talk about it anymore.",
                            },
                            ["TL"] = {
                                "Magpahinga ka. Hindi na natin kailangang pag-usapan pa 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.social.apology.withdrawn.warm.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I hear you, and it's okay. We can put it to rest.",
                            },
                            ["TL"] = {
                                "Narinig kita, at ayos lang. Pwede na nating ipahinga 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.social.apology.withdrawn.warm.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "It's okay. We can take a break from this topic.",
                            },
                            ["TL"] = {
                                "Ayos lang. Pwede tayong magpahinga sa paksang ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.social.apology.withdrawn.warm.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "No worries at all. We'll leave it behind us.",
                            },
                            ["TL"] = {
                                "Walang problema talaga. Iiwan na natin 'yan sa likod.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.social.apology.withdrawn.warm.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I understand. Let's just focus on each other and staying safe.",
                            },
                            ["TL"] = {
                                "Nauunawaan ko. Magpokus na lang tayo sa isa't isa at kaligtasan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.social.apology.withdrawn.warm.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "All good. No pressure to explain anything more.",
                            },
                            ["TL"] = {
                                "Ayos ang lahat. Walang pamimilit na magpaliwanag pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.social.apology.withdrawn.warm.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "We're okay. Let's leave it there peacefully.",
                            },
                            ["TL"] = {
                                "Ayos lang tayo. Iwan na natin doon nang payapa.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.social.apology.withdrawn.warm.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm with you. We don't need to rehash it.",
                            },
                            ["TL"] = {
                                "Kasama mo ako. Hindi na natin kailangang ulit-ulitin.",
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
        ["sourceShard"] = "psdl/dialogue/social_apology.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
