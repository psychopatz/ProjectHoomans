-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_needs",
        ["id"] = "semantic.question.needs.proposal.unknown.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.needs.proposal.unknown.neutral",
            ["sourcePath"] = "psdl/dialogue/conversation_needs.json#records[12]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_needs_proposal_unknown_neutral",
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
                ["responseTemplateID"] = "semantic.question.needs.proposal.unknown",
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
                                "I can keep that as a proposal, but I need to confirm the item and amount before I record a commitment.",
                            },
                            ["TL"] = {
                                "Ituturing ko muna itong panukala, pero kailangan ko munang tiyakin ang gamit at dami bago ako magtala ng pangako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Sounds like an interesting idea, but let's specify the supplies and amount first.",
                            },
                            ["TL"] = {
                                "Mukhang kawili-wiling ideya, pero tukuyin muna natin ang gamit at dami.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'm open to discussion, but I need to know what you're actually offering.",
                            },
                            ["TL"] = {
                                "Bukas ako sa pag-uusap, pero kailangan kong malaman kung ano talaga ang iaalok mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "We can make an arrangement once the items and quantities are clear.",
                            },
                            ["TL"] = {
                                "Puwede tayong gumawa ng kasunduan kapag malinaw na ang mga gamit at dami.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I hear the proposal, but let's put concrete numbers on the table.",
                            },
                            ["TL"] = {
                                "Narinig ko ang alok, pero maglagay tayo ng tiyak na bilang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Happy to consider a trade, just spell out what you're putting forward.",
                            },
                            ["TL"] = {
                                "Masayang pag-isipan ang palitan, sabihin mo lang nang malinaw ang ihahain mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Let's iron out what items we're talking about before making any promises.",
                            },
                            ["TL"] = {
                                "Linawin muna natin kung anong gamit ang tinutukoy bago mangako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'm listening, but I need specific supplies and numbers to agree.",
                            },
                            ["TL"] = {
                                "Nakikinig ako, pero kailangan ko ng partikular na suplay at bilang para pumayag.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "A proposal is fine, but we need clear terms before shaking on it.",
                            },
                            ["TL"] = {
                                "Maayos ang panukala, pero kailangan natin ng malinaw na kondisyon bago pagkasunduan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Tell me what items and how many, and we'll see if we have a deal.",
                            },
                            ["TL"] = {
                                "Sabihin mo kung anong gamit at ilan, at titingnan natin kung magkakasundo tayo.",
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
