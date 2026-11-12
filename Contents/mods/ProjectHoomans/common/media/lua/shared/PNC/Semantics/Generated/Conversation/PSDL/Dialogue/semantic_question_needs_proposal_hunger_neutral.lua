-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_needs",
        ["id"] = "semantic.question.needs.proposal.hunger.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.needs.proposal.hunger.neutral",
            ["sourcePath"] = "psdl/dialogue/conversation_needs.json#records[10]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_needs_proposal_hunger_neutral",
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
                ["category"] = "projecthoomans:conversation_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.question.needs.proposal.hunger",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/needs.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                            },
                            ["TL"] = {
                                "Ituturing ko muna itong panukala, pero kailangan ko pa ang gamit at dami bago ako magtala ng pangako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Sounds like a fair idea for food, but let's confirm what and how much first.",
                            },
                            ["TL"] = {
                                "Mukhang magandang ideya para sa pagkain, pero tiyakin muna natin kung ano at gaano karami.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'm interested in the food offer, but let's settle on the exact details.",
                            },
                            ["TL"] = {
                                "Interesado ako sa alok na pagkain, pero linawin natin ang mga detalye.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "We can make a deal for food, just let me know the specifics.",
                            },
                            ["TL"] = {
                                "Puwede tayong magkasundo sa pagkain, sabihin mo lang ang mga detalye.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Food trade sounds promising. What rations are we looking at exactly?",
                            },
                            ["TL"] = {
                                "Mukhang maganda ang palitan ng pagkain. Anong rasyon ba eksakto ang tinitingnan natin?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I hear your proposal on food. Let's agree on portions before shaking on it.",
                            },
                            ["TL"] = {
                                "Narinig ko ang alok mo sa pagkain. Magkasundo muna tayo sa dami bago natin pagtibayin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Could work for food, but we need to pin down the details first.",
                            },
                            ["TL"] = {
                                "Puwede sa pagkain, pero kailangan nating tiyakin ang detalye muna.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'm open to trading for food. Just tell me what items you have in mind.",
                            },
                            ["TL"] = {
                                "Bukas ako sa pakikipagpalitan ng pagkain. Sabihin mo lang anong gamit ang nasa isip mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "A food arrangement sounds good. Let's confirm what's on the table.",
                            },
                            ["TL"] = {
                                "Maganda ang kasunduan sa pagkain. Tiyakin natin kung ano ang iaalok.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "That food proposal works for me once we iron out the amount.",
                            },
                            ["TL"] = {
                                "Ayos sa akin ang alok sa pagkain kapag naitama na natin ang dami.",
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
        ["sourceShard"] = "psdl/dialogue/conversation_needs.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
