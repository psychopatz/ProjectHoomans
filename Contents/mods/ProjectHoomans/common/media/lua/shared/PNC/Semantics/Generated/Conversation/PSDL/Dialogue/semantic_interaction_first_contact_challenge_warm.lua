-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_first_contact",
        ["id"] = "semantic.interaction.first_contact.challenge.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.first_contact.challenge.warm",
            ["sourcePath"] = "psdl/dialogue/social_interaction_first_contact.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_first_contact_challenge_warm",
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
                ["responseTemplateID"] = "semantic.interaction.first_contact.challenge",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/first_contact/challenge.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "Easy. I don't know you yet.",
                            },
                            ["TL"] = {
                                "Dahan-dahan. Hindi pa kita kilala.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Hold on there, stranger. Let's introduce ourselves first.",
                            },
                            ["TL"] = {
                                "Teka muna, estranghero. Magpakilala muna tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Easy does it. Are you alone out here?",
                            },
                            ["TL"] = {
                                "Dahan-dahan lang. Nag-iisa ka ba rito?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Hey there. Don't be frightened, just tell me your name.",
                            },
                            ["TL"] = {
                                "Kumusta. Huwag kang matakot, sabihin mo lang pangalan mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Slow down, friend. Let's see who we're talking to.",
                            },
                            ["TL"] = {
                                "Dahan-dahan lang, kaibigan. Tingnan natin kung sino ang kausap.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Peace. Just hold up so we can get acquainted.",
                            },
                            ["TL"] = {
                                "Kapayapaan. Huminto ka muna para magkakilala tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Hello. I don't recognize your face—who might you be?",
                            },
                            ["TL"] = {
                                "Kumusta. Di ko pamilyar ang mukha mo—sino ka?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "Easy now. Just looking out for safety. Who are you?",
                            },
                            ["TL"] = {
                                "Dahan-dahan lang. Nag-iingat lang. Sino ka?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Stay there a second, stranger. Where are you heading?",
                            },
                            ["TL"] = {
                                "Diyan ka muna sandali, estranghero. Saan ang punta mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Welcome, but take it slow. What's your story?",
                            },
                            ["TL"] = {
                                "Maligayang pagdating, pero dahan-dahan lang. Ano ang kuwento mo?",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_first_contact.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
