-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_first_contact",
        ["id"] = "semantic.interaction.first_contact.challenge.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.first_contact.challenge.guarded",
            ["sourcePath"] = "psdl/dialogue/social_interaction_first_contact.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionFirstContact/Catalog",
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
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "That's close enough. What do you want?",
                            },
                            ["TL"] = {
                                "Hanggang diyan ka lang. Ano ang gusto mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Hands where I can see them. Who are you?",
                            },
                            ["TL"] = {
                                "Kamay kung saan ko nakikita. Sino ka?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Stop right there. State your business.",
                            },
                            ["TL"] = {
                                "Tigil diyan. Sabihin mo ang pakay mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Keep your distance. What brings you over here?",
                            },
                            ["TL"] = {
                                "Panatilihin ang distansya. Anong nagdala sa 'yo rito?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Don't take another step. Who sent you?",
                            },
                            ["TL"] = {
                                "Huwag ka nang humakbang pa. Sinong nagpadala sa 'yo?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Hold it. Are you armed?",
                            },
                            ["TL"] = {
                                "Sandali. May armas ka ba?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Stay where you are. Why are you approaching me?",
                            },
                            ["TL"] = {
                                "Diyan ka lang. Bakit ka lumalapit sa akin?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Hold ground. What are you after?",
                            },
                            ["TL"] = {
                                "Diyan ka lang. Anong hinahabol mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Keep your hands clear of your waist. Who are you?",
                            },
                            ["TL"] = {
                                "Ilayo ang kamay sa baywang. Sino ka?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "One wrong twitch and we have a problem. Speak up.",
                            },
                            ["TL"] = {
                                "Isang maling galaw at magkakaproblema tayo. Magsalita ka.",
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
    {
        ["domain"] = "social_interaction_first_contact",
        ["id"] = "semantic.interaction.first_contact.challenge.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.first_contact.challenge.neutral",
            ["sourcePath"] = "psdl/dialogue/social_interaction_first_contact.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionFirstContact/Catalog",
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
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Hold it. Who are you?",
                            },
                            ["TL"] = {
                                "Sandali. Sino ka?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Hold up a second. What's your name?",
                            },
                            ["TL"] = {
                                "Teka sandali. Anong pangalan mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Who goes there? Speak up.",
                            },
                            ["TL"] = {
                                "Sino 'yan? Magsalita ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Stop there for a moment. Are you friendly?",
                            },
                            ["TL"] = {
                                "Tigil muna diyan. Kaibigan ka ba?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Hold on. What brings you to this area?",
                            },
                            ["TL"] = {
                                "Teka muna. Anong ginagawa mo sa lugar na 'to?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "State who you are and what you're doing here.",
                            },
                            ["TL"] = {
                                "Sabihin kung sino ka at anong ginagawa mo rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Hold it right there. Let's talk before you come closer.",
                            },
                            ["TL"] = {
                                "Diyan ka muna. Mag-usap tayo bago ka lumapit pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Who are you and who are you with?",
                            },
                            ["TL"] = {
                                "Sino ka at sinong kasama mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Stop there. Just want to make sure you're not a threat.",
                            },
                            ["TL"] = {
                                "Tigil diyan. Nais ko lang tiyakin na di ka banta.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Hold up. Give me a name and a reason you're here.",
                            },
                            ["TL"] = {
                                "Teka lang. Bigyan mo ako ng pangalan at dahilan kung bakit ka narito.",
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
    {
        ["domain"] = "social_interaction_first_contact",
        ["id"] = "semantic.interaction.first_contact.challenge.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.first_contact.challenge.terse",
            ["sourcePath"] = "psdl/dialogue/social_interaction_first_contact.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionFirstContact/Catalog",
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
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "Who are you?",
                            },
                            ["TL"] = {
                                "Sino ka?",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "Halt.",
                            },
                            ["TL"] = {
                                "Hinto.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Identify.",
                            },
                            ["TL"] = {
                                "Magpakilala.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Stop.",
                            },
                            ["TL"] = {
                                "Tigil.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Name?",
                            },
                            ["TL"] = {
                                "Pangalan?",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Hands up.",
                            },
                            ["TL"] = {
                                "Itaas ang kamay.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Purpose?",
                            },
                            ["TL"] = {
                                "Pakay?",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "Freeze.",
                            },
                            ["TL"] = {
                                "Huwag gagalaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "State business.",
                            },
                            ["TL"] = {
                                "Sabihin ang sadya.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Who's there?",
                            },
                            ["TL"] = {
                                "Sino 'yan?",
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
    {
        ["domain"] = "social_interaction_first_contact",
        ["id"] = "semantic.interaction.first_contact.challenge.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.first_contact.challenge.warm",
            ["sourcePath"] = "psdl/dialogue/social_interaction_first_contact.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionFirstContact/Catalog",
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
