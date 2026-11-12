-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_tool_replies_affirmation",
        ["id"] = "semantic.tool_reply.compliment.1.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.tool_reply.compliment.1.neutral",
            ["sourcePath"] = "psdl/dialogue/social_tool_replies_affirmation.json#records[19]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_tool_reply_compliment_1_neutral",
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
                ["responseTemplateID"] = "semantic.tool_reply.compliment.1",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/tool_replies/compliment.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "That is kind of you to say.",
                            },
                            ["TL"] = {
                                "Mabait sa 'yo ang magsabi niyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Thank you. That is very nice of you.",
                            },
                            ["TL"] = {
                                "Salamat. Napakabait mo naman.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I appreciate the kind words.",
                            },
                            ["TL"] = {
                                "Salamat sa magagandang salita.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "That is generous of you. Thanks.",
                            },
                            ["TL"] = {
                                "Mabuti ang puso mo. Salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Thanks. It is rare to get compliments out here.",
                            },
                            ["TL"] = {
                                "Salamat. Bihira ang papuri sa panahong ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "That puts a smile on my face. Thank you.",
                            },
                            ["TL"] = {
                                "Napangiti mo ako roon. Salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "You are too kind.",
                            },
                            ["TL"] = {
                                "Napakabait mo talaga.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I appreciate that. Truly.",
                            },
                            ["TL"] = {
                                "Pinahahalagahan ko talaga 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Thanks. I will take all the good words I can get.",
                            },
                            ["TL"] = {
                                "Salamat. Tatanggapin ko ang anumang magandang salita ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Thank you. That brightens things up a bit.",
                            },
                            ["TL"] = {
                                "Salamat. Nabigyan mo ng kaunting liwanag ang araw ko.",
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
        ["sourceShard"] = "psdl/dialogue/social_tool_replies_affirmation.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
