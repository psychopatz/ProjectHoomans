-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_needs",
        ["id"] = "semantic.question.needs.proposal.thirst.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.needs.proposal.thirst.neutral",
            ["sourcePath"] = "psdl/dialogue/conversation_needs.json#records[11]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_needs_proposal_thirst_neutral",
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
                ["responseTemplateID"] = "semantic.question.needs.proposal.thirst",
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
                                "Sounds like a solid idea for water, but let's confirm the bottles and amount first.",
                            },
                            ["TL"] = {
                                "Mukhang maayos na plano para sa tubig, pero tiyakin muna natin ang botelya at dami.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'm open to that water proposal. Just tell me how much you're offering.",
                            },
                            ["TL"] = {
                                "Bukas ako sa alok na tubig. Sabihin mo lang kung gaano karami ang ibibigay mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "We can agree on water, but let's nail down the specifics first.",
                            },
                            ["TL"] = {
                                "Puwede tayong magkasundo sa tubig, pero ayusin muna natin ang detalye.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Water trade sounds good to me. What containers are we discussing?",
                            },
                            ["TL"] = {
                                "Maganda ang palitan ng tubig. Anong lalagyan ba ang pinag-uusapan natin?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I hear your water offer. Let's agree on the quantity before finalizing.",
                            },
                            ["TL"] = {
                                "Narinig ko ang alok mong tubig. Magkasundo muna tayo sa dami bago tapusin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Water is always valuable. Tell me the exact amount you want to trade.",
                            },
                            ["TL"] = {
                                "Mahalaga palagi ang tubig. Sabihin mo ang eksaktong dami na nais mong ipagpalit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'd take that water deal once we clarify how much you're providing.",
                            },
                            ["TL"] = {
                                "Tatanggapin ko ang kasunduan sa tubig kapag nalinaw na kung gaano karami ang ibibigay mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Good proposal for water. Let's make sure the details are clear to both of us.",
                            },
                            ["TL"] = {
                                "Magandang alok para sa tubig. Siguraduhin nating malinaw ang detalye sa ating dalawa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I'm ready to agree on water, just specify how many bottles or sips.",
                            },
                            ["TL"] = {
                                "Handa akong sumang-ayon sa tubig, tukuyin mo lang kung ilang botelya o lagok.",
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
