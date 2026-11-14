-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "event_reactions_corpse",
        ["exchangeFamily"] = {
            ["familyID"] = "corpse.reaction.default",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "Someone died here. We should remember that.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.reaction.default.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Someone died here. We should remember that.",
                                        "Poor bastard. Didn't make it.",
                                        "Another body in the dirt. World's unforgiving.",
                                        "They fought hard, by the looks of it.",
                                        "Someone lost a life here. Tread with respect.",
                                        "Looks like they got trapped. Rest easy.",
                                        "Could've been any of us. Keep walking.",
                                        "Another survivor cut down too early.",
                                        "Body's cold. Let's make sure we don't end up like this.",
                                        "Rest in peace, stranger. Let's keep moving.",
                                    },
                                    ["TL"] = {
                                        "May namatay dito. Dapat nating alalahanin 'yon.",
                                        "Kawawa naman. Hindi nakaligtas.",
                                        "Isa na namang bangkay sa lupa. Malupit ang mundo.",
                                        "Lumaban nang husto, base sa hitsura.",
                                        "May nawalan ng buhay rito. Maglakad nang may galang.",
                                        "Mukhang naipit sila rito. Mamahinga ka na.",
                                        "Kahit sino sa atin pwedeng maging ganyan. Lakad na.",
                                        "Isa na namang survivor ang pumanaw nang maaga.",
                                        "Malamig na ang bangkay. Siguruhin nating hindi tayo matutulad dito.",
                                        "Sumalangit nawa ang kaluluwa mo. Magpatuloy tayo.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "corpse.reaction",
            ["textRoles"] = {
                {
                    ["fallback"] = "Someone died here. We should remember that.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.reaction.default.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Someone died here. We should remember that.",
                            "Poor bastard. Didn't make it.",
                            "Another body in the dirt. World's unforgiving.",
                            "They fought hard, by the looks of it.",
                            "Someone lost a life here. Tread with respect.",
                            "Looks like they got trapped. Rest easy.",
                            "Could've been any of us. Keep walking.",
                            "Another survivor cut down too early.",
                            "Body's cold. Let's make sure we don't end up like this.",
                            "Rest in peace, stranger. Let's keep moving.",
                        },
                        ["TL"] = {
                            "May namatay dito. Dapat nating alalahanin 'yon.",
                            "Kawawa naman. Hindi nakaligtas.",
                            "Isa na namang bangkay sa lupa. Malupit ang mundo.",
                            "Lumaban nang husto, base sa hitsura.",
                            "May nawalan ng buhay rito. Maglakad nang may galang.",
                            "Mukhang naipit sila rito. Mamahinga ka na.",
                            "Kahit sino sa atin pwedeng maging ganyan. Lakad na.",
                            "Isa na namang survivor ang pumanaw nang maaga.",
                            "Malamig na ang bangkay. Siguruhin nating hindi tayo matutulad dito.",
                            "Sumalangit nawa ang kaluluwa mo. Magpatuloy tayo.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "corpse.reaction.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "default",
            ["sourceId"] = "corpse.reaction.default",
            ["sourcePath"] = "adopters/hoomans/dialogue/event_reactions_corpse/corpse_reaction_default.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsCorpse",
        ["namespace"] = "corpse.reaction",
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
                ["category"] = "projecthoomans:event_reactions",
                ["contentOwner"] = "projecthoomans.dialogue_content.events",
                ["responseAct"] = "REACT",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Someone died here. We should remember that.",
                                        "Poor bastard. Didn't make it.",
                                        "Another body in the dirt. World's unforgiving.",
                                        "They fought hard, by the looks of it.",
                                        "Someone lost a life here. Tread with respect.",
                                        "Looks like they got trapped. Rest easy.",
                                        "Could've been any of us. Keep walking.",
                                        "Another survivor cut down too early.",
                                        "Body's cold. Let's make sure we don't end up like this.",
                                        "Rest in peace, stranger. Let's keep moving.",
                                    },
                                    ["TL"] = {
                                        "May namatay dito. Dapat nating alalahanin 'yon.",
                                        "Kawawa naman. Hindi nakaligtas.",
                                        "Isa na namang bangkay sa lupa. Malupit ang mundo.",
                                        "Lumaban nang husto, base sa hitsura.",
                                        "May nawalan ng buhay rito. Maglakad nang may galang.",
                                        "Mukhang naipit sila rito. Mamahinga ka na.",
                                        "Kahit sino sa atin pwedeng maging ganyan. Lakad na.",
                                        "Isa na namang survivor ang pumanaw nang maaga.",
                                        "Malamig na ang bangkay. Siguruhin nating hindi tayo matutulad dito.",
                                        "Sumalangit nawa ang kaluluwa mo. Magpatuloy tayo.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "corpse.reaction.default",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Someone died here. We should remember that.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.corpse.reaction.default.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/event_reactions_corpse/corpse_reaction_default.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Someone died here. We should remember that.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.reaction.default.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Someone died here. We should remember that.",
                        "Poor bastard. Didn't make it.",
                        "Another body in the dirt. World's unforgiving.",
                        "They fought hard, by the looks of it.",
                        "Someone lost a life here. Tread with respect.",
                        "Looks like they got trapped. Rest easy.",
                        "Could've been any of us. Keep walking.",
                        "Another survivor cut down too early.",
                        "Body's cold. Let's make sure we don't end up like this.",
                        "Rest in peace, stranger. Let's keep moving.",
                    },
                    ["TL"] = {
                        "May namatay dito. Dapat nating alalahanin 'yon.",
                        "Kawawa naman. Hindi nakaligtas.",
                        "Isa na namang bangkay sa lupa. Malupit ang mundo.",
                        "Lumaban nang husto, base sa hitsura.",
                        "May nawalan ng buhay rito. Maglakad nang may galang.",
                        "Mukhang naipit sila rito. Mamahinga ka na.",
                        "Kahit sino sa atin pwedeng maging ganyan. Lakad na.",
                        "Isa na namang survivor ang pumanaw nang maaga.",
                        "Malamig na ang bangkay. Siguruhin nating hindi tayo matutulad dito.",
                        "Sumalangit nawa ang kaluluwa mo. Magpatuloy tayo.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "event_reactions_corpse",
        ["exchangeFamily"] = {
            ["familyID"] = "corpse.reaction.revenge",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "Someone is going to answer for this.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.reaction.revenge.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Someone is going to answer for this.",
                                        "They didn't deserve this. Whoever did it will pay.",
                                        "This wasn't rottens, this was murder. They'll bleed for it.",
                                        "I'll find whoever did this and make them regret it.",
                                        "They slaughtered them. There's no forgiving this.",
                                        "Mark my words, retribution is coming for them.",
                                        "Whoever left this body won't walk away clean.",
                                        "Cold-blooded. I won't forget this sight.",
                                        "Blood demands blood. We settle this score.",
                                        "They butchered one of our own. They will pay.",
                                    },
                                    ["TL"] = {
                                        "May mananagot para rito.",
                                        "Hindi nila nararapat 'to. Pagbabayaran 'to ng may gawa.",
                                        "Hindi 'to gawa ng infected, patayan 'to. Dudugo sila para rito.",
                                        "Hahanapin ko ang may gawa nito at pagsisisihan nila.",
                                        "Pinaslang nila sila. Walang kapatawaran ito.",
                                        "Tandaan mo, darating ang ganti para sa kanila.",
                                        "Ang nag-iwan ng bangkay na 'to ay hindi makakatakas nang buo.",
                                        "Walang awang pagpatay. Hindi ko makakalimutan ang nakita ko.",
                                        "Dugo ang kabayaran ng dugo. Tutuldukan natin 'to.",
                                        "Kinatay nila ang isa sa atin. Pagbabayaran nila.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "corpse.reaction",
            ["textRoles"] = {
                {
                    ["fallback"] = "Someone is going to answer for this.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.reaction.revenge.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Someone is going to answer for this.",
                            "They didn't deserve this. Whoever did it will pay.",
                            "This wasn't rottens, this was murder. They'll bleed for it.",
                            "I'll find whoever did this and make them regret it.",
                            "They slaughtered them. There's no forgiving this.",
                            "Mark my words, retribution is coming for them.",
                            "Whoever left this body won't walk away clean.",
                            "Cold-blooded. I won't forget this sight.",
                            "Blood demands blood. We settle this score.",
                            "They butchered one of our own. They will pay.",
                        },
                        ["TL"] = {
                            "May mananagot para rito.",
                            "Hindi nila nararapat 'to. Pagbabayaran 'to ng may gawa.",
                            "Hindi 'to gawa ng infected, patayan 'to. Dudugo sila para rito.",
                            "Hahanapin ko ang may gawa nito at pagsisisihan nila.",
                            "Pinaslang nila sila. Walang kapatawaran ito.",
                            "Tandaan mo, darating ang ganti para sa kanila.",
                            "Ang nag-iwan ng bangkay na 'to ay hindi makakatakas nang buo.",
                            "Walang awang pagpatay. Hindi ko makakalimutan ang nakita ko.",
                            "Dugo ang kabayaran ng dugo. Tutuldukan natin 'to.",
                            "Kinatay nila ang isa sa atin. Pagbabayaran nila.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "corpse.reaction.revenge",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "revenge",
            ["sourceId"] = "corpse.reaction.revenge",
            ["sourcePath"] = "adopters/hoomans/dialogue/event_reactions_corpse/corpse_reaction_revenge.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsCorpse",
        ["namespace"] = "corpse.reaction",
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
                ["category"] = "projecthoomans:event_reactions",
                ["contentOwner"] = "projecthoomans.dialogue_content.events",
                ["responseAct"] = "REACT",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Someone is going to answer for this.",
                                        "They didn't deserve this. Whoever did it will pay.",
                                        "This wasn't rottens, this was murder. They'll bleed for it.",
                                        "I'll find whoever did this and make them regret it.",
                                        "They slaughtered them. There's no forgiving this.",
                                        "Mark my words, retribution is coming for them.",
                                        "Whoever left this body won't walk away clean.",
                                        "Cold-blooded. I won't forget this sight.",
                                        "Blood demands blood. We settle this score.",
                                        "They butchered one of our own. They will pay.",
                                    },
                                    ["TL"] = {
                                        "May mananagot para rito.",
                                        "Hindi nila nararapat 'to. Pagbabayaran 'to ng may gawa.",
                                        "Hindi 'to gawa ng infected, patayan 'to. Dudugo sila para rito.",
                                        "Hahanapin ko ang may gawa nito at pagsisisihan nila.",
                                        "Pinaslang nila sila. Walang kapatawaran ito.",
                                        "Tandaan mo, darating ang ganti para sa kanila.",
                                        "Ang nag-iwan ng bangkay na 'to ay hindi makakatakas nang buo.",
                                        "Walang awang pagpatay. Hindi ko makakalimutan ang nakita ko.",
                                        "Dugo ang kabayaran ng dugo. Tutuldukan natin 'to.",
                                        "Kinatay nila ang isa sa atin. Pagbabayaran nila.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "corpse.reaction.revenge",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Someone is going to answer for this.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.corpse.reaction.revenge.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/event_reactions_corpse/corpse_reaction_revenge.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Someone is going to answer for this.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.reaction.revenge.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Someone is going to answer for this.",
                        "They didn't deserve this. Whoever did it will pay.",
                        "This wasn't rottens, this was murder. They'll bleed for it.",
                        "I'll find whoever did this and make them regret it.",
                        "They slaughtered them. There's no forgiving this.",
                        "Mark my words, retribution is coming for them.",
                        "Whoever left this body won't walk away clean.",
                        "Cold-blooded. I won't forget this sight.",
                        "Blood demands blood. We settle this score.",
                        "They butchered one of our own. They will pay.",
                    },
                    ["TL"] = {
                        "May mananagot para rito.",
                        "Hindi nila nararapat 'to. Pagbabayaran 'to ng may gawa.",
                        "Hindi 'to gawa ng infected, patayan 'to. Dudugo sila para rito.",
                        "Hahanapin ko ang may gawa nito at pagsisisihan nila.",
                        "Pinaslang nila sila. Walang kapatawaran ito.",
                        "Tandaan mo, darating ang ganti para sa kanila.",
                        "Ang nag-iwan ng bangkay na 'to ay hindi makakatakas nang buo.",
                        "Walang awang pagpatay. Hindi ko makakalimutan ang nakita ko.",
                        "Dugo ang kabayaran ng dugo. Tutuldukan natin 'to.",
                        "Kinatay nila ang isa sa atin. Pagbabayaran nila.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
