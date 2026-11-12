-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_hostile_offer_threat",
        ["id"] = "semantic.social.threat_boundary.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.threat_boundary.guarded",
            ["sourcePath"] = "psdl/dialogue/social_reactions_hostile_offer_threat.json#records[20]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_threat_boundary_guarded",
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
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Back away. Now.",
                            },
                            ["TL"] = {
                                "Umatras ka. Ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Take one more step and find out.",
                            },
                            ["TL"] = {
                                "Humakbang ka pa nang isa at nang malaman mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Keep your hands off your weapon and step back.",
                            },
                            ["TL"] = {
                                "Alisin ang kamay sa armas at umatras ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "You're threatening the wrong survivor.",
                            },
                            ["TL"] = {
                                "Maling tao ang tinatakot mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Back up before I put you down.",
                            },
                            ["TL"] = {
                                "Umatras ka bago kita patumbahin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "I am not afraid to defend myself. Back off.",
                            },
                            ["TL"] = {
                                "Hindi ako natatakot ipagtanggol ang sarili ko. Lumayo ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Last chance to walk away alive.",
                            },
                            ["TL"] = {
                                "Huling pagkakataon para lumakad palayo nang buhay.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "You don't want this fight. Step back.",
                            },
                            ["TL"] = {
                                "Ayaw mo sa laban na ito. Umatras ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Back away immediately.",
                            },
                            ["TL"] = {
                                "Lumayo ka agad-agad.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Hands where I can see them. Back off.",
                            },
                            ["TL"] = {
                                "Kamay kung saan ko nakikita. Umatras ka.",
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
