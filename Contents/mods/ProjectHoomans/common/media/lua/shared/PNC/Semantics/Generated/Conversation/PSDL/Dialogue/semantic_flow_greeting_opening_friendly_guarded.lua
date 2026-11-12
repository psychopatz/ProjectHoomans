-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_greeting",
        ["id"] = "semantic.flow.greeting.opening.friendly.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.flow.greeting.opening.friendly.guarded",
            ["sourcePath"] = "psdl/dialogue/conversation_greeting.json#records[6]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_flow_greeting_opening_friendly_guarded",
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
                ["responseTemplateID"] = "semantic.flow.greeting.opening.friendly",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/greeting.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Hey. Everything holding together?",
                            },
                            ["TL"] = {
                                "Uy. Maayos pa ba ang lahat?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Good timing. We could use your help.",
                            },
                            ["TL"] = {
                                "Tamang-tama ang dating mo. Kailangan namin ng tulong mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Hey again. Everything quiet around here?",
                            },
                            ["TL"] = {
                                "Uy ulit. Tahimik ba ang paligid dito?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Back again? Keep your weapon close.",
                            },
                            ["TL"] = {
                                "Bumalik ka? Ilapit mo ang armas mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Hey. You notice anything strange out there?",
                            },
                            ["TL"] = {
                                "Uy. May napansin ka bang kakaiba sa labas?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Good to see you. Stay watchful though.",
                            },
                            ["TL"] = {
                                "Mabuti at nakita kita. Magmatyag ka pa rin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "You made it back. Keep low and stay alert.",
                            },
                            ["TL"] = {
                                "Nakabalik ka. Yumuko ka at maging alerto.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Glad you're safe. We've got to watch the treeline.",
                            },
                            ["TL"] = {
                                "Mabuti at ligtas ka. Kailangan nating bantayan ang kagubatan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Hey. Hope nobody followed you in.",
                            },
                            ["TL"] = {
                                "Uy. Sana walang sumunod sa 'yo papasok.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "There you are. Let's keep our eyes sharp.",
                            },
                            ["TL"] = {
                                "Nandiyan ka pala. Maging matalas ang mga mata natin.",
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
        ["sourceShard"] = "psdl/dialogue/conversation_greeting.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
