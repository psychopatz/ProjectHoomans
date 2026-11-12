-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.dispute_friendly.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.dispute_friendly.neutral",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[9]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_dispute_friendly_neutral",
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
                ["responseTemplateID"] = "semantic.social.dispute_friendly",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/disputes.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I disagree, but I hear what you're saying.",
                            },
                            ["TL"] = {
                                "Hindi ako sang-ayon, pero naririnig ko ang punto mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I see things differently on this one.",
                            },
                            ["TL"] = {
                                "Iba ang pananaw ko sa bagay na ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "We'll have to agree to disagree here.",
                            },
                            ["TL"] = {
                                "Kailangan na lang nating tanggaping magkaiba tayo rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I don't think that's the best way forward.",
                            },
                            ["TL"] = {
                                "Sa tingin ko hindi 'yan ang pinakamagandang hakbang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I have reservations about that plan.",
                            },
                            ["TL"] = {
                                "May pag-aalinlangan ako sa planong 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Fair point, but I still see a problem with it.",
                            },
                            ["TL"] = {
                                "May punto ka, pero may nakikita pa rin akong aberya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I respectfully disagree with your take.",
                            },
                            ["TL"] = {
                                "May galang akong hindi sumasang-ayon sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "That's not how I read the situation.",
                            },
                            ["TL"] = {
                                "Hindi ganyan ang pagbasa ko sa sitwasyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I don't see it that way, honestly.",
                            },
                            ["TL"] = {
                                "Sa totoo lang, hindi ganoon ang tingin ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "We have different opinions on this. That's fine.",
                            },
                            ["TL"] = {
                                "Magkaiba tayo ng opinyon dito. Ayos lang 'yon.",
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
