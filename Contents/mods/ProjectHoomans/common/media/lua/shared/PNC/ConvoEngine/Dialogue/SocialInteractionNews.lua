-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_news",
        ["id"] = "semantic.interaction.news.acknowledge.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.interaction.news.acknowledge.guarded",
            ["sourcePath"] = "psdl/dialogue/social_interaction_news.json#records[3]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionNews",
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
                ["responseTemplateID"] = "semantic.interaction.news.acknowledge",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/news/acknowledge.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'll keep it in mind.",
                            },
                            ["TL"] = {
                                "Tatandaan ko iyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Where did you hear that from?",
                            },
                            ["TL"] = {
                                "Saan mo narinig ang balitang 'yan?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'll believe it when I see it with my own eyes.",
                            },
                            ["TL"] = {
                                "Maniwala lang ako kapag nakita ko na ng sarili kong mata.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Rumors can get people killed out here. Be sure of your facts.",
                            },
                            ["TL"] = {
                                "Ang tsismis ay nakamamatay dito. Tiyakin mo ang katotohanan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Noted, but I'll verify that myself.",
                            },
                            ["TL"] = {
                                "Tala ko na, pero kumpirmahin ko muna sa sarili ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Could be a setup. Don't act on rumors too quickly.",
                            },
                            ["TL"] = {
                                "Baka bitag 'yan. Huwag kumilos sa sabi-sabi nang padalos-dalos.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Who gave you that information?",
                            },
                            ["TL"] = {
                                "Sinong nagbigay sa 'yo ng impormasyong 'yan?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'll take it under advisement, but keep my distance.",
                            },
                            ["TL"] = {
                                "Isasaalang-alang ko, pero magmamasid pa rin ako mula sa malayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Don't spread that around until we know it's solid.",
                            },
                            ["TL"] = {
                                "Huwag mong ikalat 'yan hangga't di tiyak na totoo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Heard. I'll watch for confirming signs.",
                            },
                            ["TL"] = {
                                "Narinig ko. Magmamasid ako ng mga patunay.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_news.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_news",
        ["id"] = "semantic.interaction.news.acknowledge.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.interaction.news.acknowledge.neutral",
            ["sourcePath"] = "psdl/dialogue/social_interaction_news.json#records[0]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionNews",
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
                ["responseTemplateID"] = "semantic.interaction.news.acknowledge",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/news/acknowledge.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "That's good to know.",
                            },
                            ["TL"] = {
                                "Mabuting malaman iyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Appreciate the update.",
                            },
                            ["TL"] = {
                                "Salamat sa balita.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'll keep that intelligence in mind.",
                            },
                            ["TL"] = {
                                "Isasaisip ko ang impormasyong iyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Good to have fresh news from the area.",
                            },
                            ["TL"] = {
                                "Mabuting makatanggap ng bagong balita mula sa lugar.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Thanks for passing that along.",
                            },
                            ["TL"] = {
                                "Salamat sa pagpasa niyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. That changes how we look at the sector.",
                            },
                            ["TL"] = {
                                "Naintindihan. Binabago niyan ang pananaw natin sa lugar.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Good information. We'll plan around it.",
                            },
                            ["TL"] = {
                                "Magandang impormasyon. Magpaplano tayo batay diyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Noted. Reliable news is hard to come by.",
                            },
                            ["TL"] = {
                                "Tala ko na. Mahirap makahanap ng maaasahang balita.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Thanks for keeping me informed.",
                            },
                            ["TL"] = {
                                "Salamat sa pagpapanatili sa aking may alam.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "That helps clear up a few rumors. Thanks.",
                            },
                            ["TL"] = {
                                "Nakatulong 'yan para maalis ang ilang sabi-sabi. Salamat.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_news.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_news",
        ["id"] = "semantic.interaction.news.acknowledge.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.interaction.news.acknowledge.terse",
            ["sourcePath"] = "psdl/dialogue/social_interaction_news.json#records[2]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionNews",
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
                ["responseTemplateID"] = "semantic.interaction.news.acknowledge",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/news/acknowledge.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "Got it.",
                            },
                            ["TL"] = {
                                "Sige.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "Noted.",
                            },
                            ["TL"] = {
                                "Tala ko na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Heard.",
                            },
                            ["TL"] = {
                                "Narinig ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Good info.",
                            },
                            ["TL"] = {
                                "Magandang balita.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Understood.",
                            },
                            ["TL"] = {
                                "Naintindihan.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Clear.",
                            },
                            ["TL"] = {
                                "Malinaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Thanks.",
                            },
                            ["TL"] = {
                                "Salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "Right.",
                            },
                            ["TL"] = {
                                "Tama.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Acknowledged.",
                            },
                            ["TL"] = {
                                "Kinikilala ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Useful.",
                            },
                            ["TL"] = {
                                "May silbi.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_news.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_news",
        ["id"] = "semantic.interaction.news.acknowledge.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.interaction.news.acknowledge.warm",
            ["sourcePath"] = "psdl/dialogue/social_interaction_news.json#records[1]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionNews",
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
                ["responseTemplateID"] = "semantic.interaction.news.acknowledge",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/news/acknowledge.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "Thanks for telling me. I'll keep that in mind.",
                            },
                            ["TL"] = {
                                "Salamat sa pagsabi. Tatandaan ko iyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "That's huge news, friend! Thank you for sharing.",
                            },
                            ["TL"] = {
                                "Napakalaking balita niyan, kaibigan! Salamat sa pagbabahagi.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Always glad to know you're looking out for me with news like this.",
                            },
                            ["TL"] = {
                                "Lagi akong masaya na binabantayan mo ako sa mga ganitong balita.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "You have great sources! Thanks a ton.",
                            },
                            ["TL"] = {
                                "Napakagaling ng mga pinagkukunan mo! Maraming salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "I really appreciate you giving me the heads up first.",
                            },
                            ["TL"] = {
                                "Talagang pinahahalagahan ko na ako ang unang pinaalalahanan mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Good news is worth its weight in gold out here. Thanks!",
                            },
                            ["TL"] = {
                                "Ang magandang balita ay ginto ang halaga rito. Salamat!",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Thanks for sharing that with me. It gives me hope.",
                            },
                            ["TL"] = {
                                "Salamat sa pagbabahagi niyan sa akin. Nagbibigay ito ng pag-asa.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'm relieved to hear that. Thank you so much, partner.",
                            },
                            ["TL"] = {
                                "Nakahinga ako nang maluwag nang marinig 'yan. Salamat nang marami, kasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "That's fantastic information. Appreciate you keeping us safe.",
                            },
                            ["TL"] = {
                                "Napakagandang impormasyon. Salamat sa pag-iingat sa atin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Thanks! Let's make sure the others hear this too.",
                            },
                            ["TL"] = {
                                "Salamat! Tiyakin nating marinig din ito ng iba.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_news.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
