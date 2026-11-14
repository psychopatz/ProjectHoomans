-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "quest_content",
        ["exchangeFamily"] = {
            ["familyID"] = "quest.clinic_supplies.accept.failed",
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
                                ["fallback"] = "I couldn't accept that request.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.quest.clinic_supplies.accept.failed.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I couldn't accept that request.",
                                        "Something went wrong. I couldn't take that on.",
                                        "I wasn't able to accept the clinic supply run.",
                                        "Unable to commit to that medical task right now.",
                                        "The request failed to go through on my end.",
                                        "I can't lock that clinic mission in.",
                                        "Couldn't confirm that request. Try again later.",
                                        "Accepting that task didn't work out.",
                                        "I couldn't take on the supplies task right now.",
                                        "That request couldn't be accepted.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko matanggap ang kahilingang iyon.",
                                        "May nagkaproblema. Hindi ko magawang tanggapin 'yan.",
                                        "Hindi ko nagawang tanggapin ang pagkuha ng suplay sa klinika.",
                                        "Hindi makakapangako sa medikal na gawaing 'yan ngayon.",
                                        "Hindi pumasok ang kahilingan sa panig ko.",
                                        "Hindi ko maitalaga ang misyong 'yan sa klinika.",
                                        "Hindi makumpirma ang kahilingang 'yan. Subukan ulit mamaya.",
                                        "Hindi nagtagumpay ang pagtanggap sa gawaing 'yan.",
                                        "Hindi ko kayang balikatin ang gawain sa suplay ngayon.",
                                        "Hindi natanggap ang kahilingang iyon.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "quest.clinic_supplies.accept",
            ["textRoles"] = {
                {
                    ["fallback"] = "I couldn't accept that request.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.quest.clinic_supplies.accept.failed.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I couldn't accept that request.",
                            "Something went wrong. I couldn't take that on.",
                            "I wasn't able to accept the clinic supply run.",
                            "Unable to commit to that medical task right now.",
                            "The request failed to go through on my end.",
                            "I can't lock that clinic mission in.",
                            "Couldn't confirm that request. Try again later.",
                            "Accepting that task didn't work out.",
                            "I couldn't take on the supplies task right now.",
                            "That request couldn't be accepted.",
                        },
                        ["TL"] = {
                            "Hindi ko matanggap ang kahilingang iyon.",
                            "May nagkaproblema. Hindi ko magawang tanggapin 'yan.",
                            "Hindi ko nagawang tanggapin ang pagkuha ng suplay sa klinika.",
                            "Hindi makakapangako sa medikal na gawaing 'yan ngayon.",
                            "Hindi pumasok ang kahilingan sa panig ko.",
                            "Hindi ko maitalaga ang misyong 'yan sa klinika.",
                            "Hindi makumpirma ang kahilingang 'yan. Subukan ulit mamaya.",
                            "Hindi nagtagumpay ang pagtanggap sa gawaing 'yan.",
                            "Hindi ko kayang balikatin ang gawain sa suplay ngayon.",
                            "Hindi natanggap ang kahilingang iyon.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "quest.clinic_supplies.accept.failed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "failed",
            ["sourceId"] = "quest.clinic_supplies.accept.failed",
            ["sourcePath"] = "adopters/hoomans/dialogue/quest_content/quest_clinic_supplies_accept_failed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/QuestContent",
        ["namespace"] = "quest.clinic_supplies.accept",
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
                ["category"] = "projecthoomans:quest_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.quest",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/quest.json",
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
                                        "I couldn't accept that request.",
                                        "Something went wrong. I couldn't take that on.",
                                        "I wasn't able to accept the clinic supply run.",
                                        "Unable to commit to that medical task right now.",
                                        "The request failed to go through on my end.",
                                        "I can't lock that clinic mission in.",
                                        "Couldn't confirm that request. Try again later.",
                                        "Accepting that task didn't work out.",
                                        "I couldn't take on the supplies task right now.",
                                        "That request couldn't be accepted.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko matanggap ang kahilingang iyon.",
                                        "May nagkaproblema. Hindi ko magawang tanggapin 'yan.",
                                        "Hindi ko nagawang tanggapin ang pagkuha ng suplay sa klinika.",
                                        "Hindi makakapangako sa medikal na gawaing 'yan ngayon.",
                                        "Hindi pumasok ang kahilingan sa panig ko.",
                                        "Hindi ko maitalaga ang misyong 'yan sa klinika.",
                                        "Hindi makumpirma ang kahilingang 'yan. Subukan ulit mamaya.",
                                        "Hindi nagtagumpay ang pagtanggap sa gawaing 'yan.",
                                        "Hindi ko kayang balikatin ang gawain sa suplay ngayon.",
                                        "Hindi natanggap ang kahilingang iyon.",
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
            ["responsePlanID"] = "quest.clinic_supplies.accept.failed",
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
                            ["fallback"] = "I couldn't accept that request.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.quest.clinic_supplies.accept.failed.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/quest_content/quest_clinic_supplies_accept_failed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I couldn't accept that request.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.quest.clinic_supplies.accept.failed.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I couldn't accept that request.",
                        "Something went wrong. I couldn't take that on.",
                        "I wasn't able to accept the clinic supply run.",
                        "Unable to commit to that medical task right now.",
                        "The request failed to go through on my end.",
                        "I can't lock that clinic mission in.",
                        "Couldn't confirm that request. Try again later.",
                        "Accepting that task didn't work out.",
                        "I couldn't take on the supplies task right now.",
                        "That request couldn't be accepted.",
                    },
                    ["TL"] = {
                        "Hindi ko matanggap ang kahilingang iyon.",
                        "May nagkaproblema. Hindi ko magawang tanggapin 'yan.",
                        "Hindi ko nagawang tanggapin ang pagkuha ng suplay sa klinika.",
                        "Hindi makakapangako sa medikal na gawaing 'yan ngayon.",
                        "Hindi pumasok ang kahilingan sa panig ko.",
                        "Hindi ko maitalaga ang misyong 'yan sa klinika.",
                        "Hindi makumpirma ang kahilingang 'yan. Subukan ulit mamaya.",
                        "Hindi nagtagumpay ang pagtanggap sa gawaing 'yan.",
                        "Hindi ko kayang balikatin ang gawain sa suplay ngayon.",
                        "Hindi natanggap ang kahilingang iyon.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "quest_content",
        ["exchangeFamily"] = {
            ["familyID"] = "quest.clinic_supplies.accept.queued",
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
                                ["fallback"] = "I'll bring the clinic supplies.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.quest.clinic_supplies.accept.queued.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'll bring the clinic supplies.",
                                        "I've got the clinic supply run on my list.",
                                        "I'll gather the medical gear as soon as I can.",
                                        "Count on me for the clinic supplies.",
                                        "I'll track down those medical items for you.",
                                        "Queued up. I'll secure those clinic supplies.",
                                        "I'm on it. I'll deliver the clinic supplies.",
                                        "Medical supplies are queued. I'll get them.",
                                        "I'll fetch what the clinic needs.",
                                        "Accepted. I'll bring back those clinic supplies.",
                                    },
                                    ["TL"] = {
                                        "Dadalahin ko ang mga suplay ng klinika.",
                                        "Nasa listahan ko na ang pagkuha ng suplay para sa klinika.",
                                        "Kukunin ko ang mga gamot sa lalong madaling panahon.",
                                        "Asahan mo ako sa mga suplay ng klinika.",
                                        "Hahanapin ko ang mga gamot na 'yon para sa'yo.",
                                        "Nakalista na. Kukunin ko ang mga suplay sa klinika.",
                                        "Ako na bahala. Ihahatid ko ang mga suplay ng klinika.",
                                        "Nakatala na ang mga medikal na suplay. Kukunin ko.",
                                        "Kukunin ko kung ano ang kailangan ng klinika.",
                                        "Tinanggap ko na. Dadalhin ko pabalik ang mga suplay sa klinika.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "quest.clinic_supplies.accept",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'll bring the clinic supplies.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.quest.clinic_supplies.accept.queued.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I'll bring the clinic supplies.",
                            "I've got the clinic supply run on my list.",
                            "I'll gather the medical gear as soon as I can.",
                            "Count on me for the clinic supplies.",
                            "I'll track down those medical items for you.",
                            "Queued up. I'll secure those clinic supplies.",
                            "I'm on it. I'll deliver the clinic supplies.",
                            "Medical supplies are queued. I'll get them.",
                            "I'll fetch what the clinic needs.",
                            "Accepted. I'll bring back those clinic supplies.",
                        },
                        ["TL"] = {
                            "Dadalahin ko ang mga suplay ng klinika.",
                            "Nasa listahan ko na ang pagkuha ng suplay para sa klinika.",
                            "Kukunin ko ang mga gamot sa lalong madaling panahon.",
                            "Asahan mo ako sa mga suplay ng klinika.",
                            "Hahanapin ko ang mga gamot na 'yon para sa'yo.",
                            "Nakalista na. Kukunin ko ang mga suplay sa klinika.",
                            "Ako na bahala. Ihahatid ko ang mga suplay ng klinika.",
                            "Nakatala na ang mga medikal na suplay. Kukunin ko.",
                            "Kukunin ko kung ano ang kailangan ng klinika.",
                            "Tinanggap ko na. Dadalhin ko pabalik ang mga suplay sa klinika.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "quest.clinic_supplies.accept.queued",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "queued",
            ["sourceId"] = "quest.clinic_supplies.accept.queued",
            ["sourcePath"] = "adopters/hoomans/dialogue/quest_content/quest_clinic_supplies_accept_queued.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/QuestContent",
        ["namespace"] = "quest.clinic_supplies.accept",
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
                ["category"] = "projecthoomans:quest_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.quest",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/quest.json",
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
                                        "I'll bring the clinic supplies.",
                                        "I've got the clinic supply run on my list.",
                                        "I'll gather the medical gear as soon as I can.",
                                        "Count on me for the clinic supplies.",
                                        "I'll track down those medical items for you.",
                                        "Queued up. I'll secure those clinic supplies.",
                                        "I'm on it. I'll deliver the clinic supplies.",
                                        "Medical supplies are queued. I'll get them.",
                                        "I'll fetch what the clinic needs.",
                                        "Accepted. I'll bring back those clinic supplies.",
                                    },
                                    ["TL"] = {
                                        "Dadalahin ko ang mga suplay ng klinika.",
                                        "Nasa listahan ko na ang pagkuha ng suplay para sa klinika.",
                                        "Kukunin ko ang mga gamot sa lalong madaling panahon.",
                                        "Asahan mo ako sa mga suplay ng klinika.",
                                        "Hahanapin ko ang mga gamot na 'yon para sa'yo.",
                                        "Nakalista na. Kukunin ko ang mga suplay sa klinika.",
                                        "Ako na bahala. Ihahatid ko ang mga suplay ng klinika.",
                                        "Nakatala na ang mga medikal na suplay. Kukunin ko.",
                                        "Kukunin ko kung ano ang kailangan ng klinika.",
                                        "Tinanggap ko na. Dadalhin ko pabalik ang mga suplay sa klinika.",
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
            ["responsePlanID"] = "quest.clinic_supplies.accept.queued",
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
                            ["fallback"] = "I'll bring the clinic supplies.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.quest.clinic_supplies.accept.queued.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/quest_content/quest_clinic_supplies_accept_queued.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'll bring the clinic supplies.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.quest.clinic_supplies.accept.queued.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I'll bring the clinic supplies.",
                        "I've got the clinic supply run on my list.",
                        "I'll gather the medical gear as soon as I can.",
                        "Count on me for the clinic supplies.",
                        "I'll track down those medical items for you.",
                        "Queued up. I'll secure those clinic supplies.",
                        "I'm on it. I'll deliver the clinic supplies.",
                        "Medical supplies are queued. I'll get them.",
                        "I'll fetch what the clinic needs.",
                        "Accepted. I'll bring back those clinic supplies.",
                    },
                    ["TL"] = {
                        "Dadalahin ko ang mga suplay ng klinika.",
                        "Nasa listahan ko na ang pagkuha ng suplay para sa klinika.",
                        "Kukunin ko ang mga gamot sa lalong madaling panahon.",
                        "Asahan mo ako sa mga suplay ng klinika.",
                        "Hahanapin ko ang mga gamot na 'yon para sa'yo.",
                        "Nakalista na. Kukunin ko ang mga suplay sa klinika.",
                        "Ako na bahala. Ihahatid ko ang mga suplay ng klinika.",
                        "Nakatala na ang mga medikal na suplay. Kukunin ko.",
                        "Kukunin ko kung ano ang kailangan ng klinika.",
                        "Tinanggap ko na. Dadalhin ko pabalik ang mga suplay sa klinika.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "quest_content",
        ["exchangeFamily"] = {
            ["familyID"] = "quest.clinic_supplies.accept.rejected",
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
                                ["fallback"] = "I can't accept that request right now.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.quest.clinic_supplies.accept.rejected.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I can't accept that request right now.",
                                        "I'm not in a position to take that on.",
                                        "Too much on my plate. Can't accept the clinic run.",
                                        "Not right now. I have to pass on that request.",
                                        "I can't commit to gathering clinic supplies today.",
                                        "I have to turn that down for now.",
                                        "Can't help with the clinic run at the moment.",
                                        "I won't be taking that request.",
                                        "Sorry, I can't agree to that right now.",
                                        "I must decline that medical supply task.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko matatanggap ang kahilingang iyon ngayon.",
                                        "Wala ako sa posisyong balikatin 'yan.",
                                        "Masyado akong maraming ginagawa. Hindi ko matatanggap ang klinika.",
                                        "Hindi muna ngayon. Tatanggihan ko muna ang kahilingang 'yan.",
                                        "Hindi ako makakapangakong mag-ipon ng suplay sa klinika ngayon.",
                                        "Kailangan ko munang tanggihan 'yan sa ngayon.",
                                        "Hindi makakatulong sa klinika sa ngayon.",
                                        "Hindi ko tatanggapin ang kahilingang 'yan.",
                                        "Pasensya na, hindi ako makakapayag diyan ngayon.",
                                        "Kailangan kong tanggihan ang gawaing medikal na 'yan.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "quest.clinic_supplies.accept",
            ["textRoles"] = {
                {
                    ["fallback"] = "I can't accept that request right now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.quest.clinic_supplies.accept.rejected.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I can't accept that request right now.",
                            "I'm not in a position to take that on.",
                            "Too much on my plate. Can't accept the clinic run.",
                            "Not right now. I have to pass on that request.",
                            "I can't commit to gathering clinic supplies today.",
                            "I have to turn that down for now.",
                            "Can't help with the clinic run at the moment.",
                            "I won't be taking that request.",
                            "Sorry, I can't agree to that right now.",
                            "I must decline that medical supply task.",
                        },
                        ["TL"] = {
                            "Hindi ko matatanggap ang kahilingang iyon ngayon.",
                            "Wala ako sa posisyong balikatin 'yan.",
                            "Masyado akong maraming ginagawa. Hindi ko matatanggap ang klinika.",
                            "Hindi muna ngayon. Tatanggihan ko muna ang kahilingang 'yan.",
                            "Hindi ako makakapangakong mag-ipon ng suplay sa klinika ngayon.",
                            "Kailangan ko munang tanggihan 'yan sa ngayon.",
                            "Hindi makakatulong sa klinika sa ngayon.",
                            "Hindi ko tatanggapin ang kahilingang 'yan.",
                            "Pasensya na, hindi ako makakapayag diyan ngayon.",
                            "Kailangan kong tanggihan ang gawaing medikal na 'yan.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "quest.clinic_supplies.accept.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "rejected",
            ["sourceId"] = "quest.clinic_supplies.accept.rejected",
            ["sourcePath"] = "adopters/hoomans/dialogue/quest_content/quest_clinic_supplies_accept_rejected.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/QuestContent",
        ["namespace"] = "quest.clinic_supplies.accept",
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
                ["category"] = "projecthoomans:quest_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.quest",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/quest.json",
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
                                        "I can't accept that request right now.",
                                        "I'm not in a position to take that on.",
                                        "Too much on my plate. Can't accept the clinic run.",
                                        "Not right now. I have to pass on that request.",
                                        "I can't commit to gathering clinic supplies today.",
                                        "I have to turn that down for now.",
                                        "Can't help with the clinic run at the moment.",
                                        "I won't be taking that request.",
                                        "Sorry, I can't agree to that right now.",
                                        "I must decline that medical supply task.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko matatanggap ang kahilingang iyon ngayon.",
                                        "Wala ako sa posisyong balikatin 'yan.",
                                        "Masyado akong maraming ginagawa. Hindi ko matatanggap ang klinika.",
                                        "Hindi muna ngayon. Tatanggihan ko muna ang kahilingang 'yan.",
                                        "Hindi ako makakapangakong mag-ipon ng suplay sa klinika ngayon.",
                                        "Kailangan ko munang tanggihan 'yan sa ngayon.",
                                        "Hindi makakatulong sa klinika sa ngayon.",
                                        "Hindi ko tatanggapin ang kahilingang 'yan.",
                                        "Pasensya na, hindi ako makakapayag diyan ngayon.",
                                        "Kailangan kong tanggihan ang gawaing medikal na 'yan.",
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
            ["responsePlanID"] = "quest.clinic_supplies.accept.rejected",
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
                            ["fallback"] = "I can't accept that request right now.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.quest.clinic_supplies.accept.rejected.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/quest_content/quest_clinic_supplies_accept_rejected.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I can't accept that request right now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.quest.clinic_supplies.accept.rejected.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I can't accept that request right now.",
                        "I'm not in a position to take that on.",
                        "Too much on my plate. Can't accept the clinic run.",
                        "Not right now. I have to pass on that request.",
                        "I can't commit to gathering clinic supplies today.",
                        "I have to turn that down for now.",
                        "Can't help with the clinic run at the moment.",
                        "I won't be taking that request.",
                        "Sorry, I can't agree to that right now.",
                        "I must decline that medical supply task.",
                    },
                    ["TL"] = {
                        "Hindi ko matatanggap ang kahilingang iyon ngayon.",
                        "Wala ako sa posisyong balikatin 'yan.",
                        "Masyado akong maraming ginagawa. Hindi ko matatanggap ang klinika.",
                        "Hindi muna ngayon. Tatanggihan ko muna ang kahilingang 'yan.",
                        "Hindi ako makakapangakong mag-ipon ng suplay sa klinika ngayon.",
                        "Kailangan ko munang tanggihan 'yan sa ngayon.",
                        "Hindi makakatulong sa klinika sa ngayon.",
                        "Hindi ko tatanggapin ang kahilingang 'yan.",
                        "Pasensya na, hindi ako makakapayag diyan ngayon.",
                        "Kailangan kong tanggihan ang gawaing medikal na 'yan.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "quest_content",
        ["exchangeFamily"] = {
            ["familyID"] = "quest.clinic_supplies.offer.failed",
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
                                ["fallback"] = "I couldn't check that clinic-supplies request.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.quest.clinic_supplies.offer.failed.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I couldn't check that clinic-supplies request.",
                                        "Unable to look over the clinic supply offer.",
                                        "The offer couldn't be processed.",
                                        "Something went wrong while checking the medical offer.",
                                        "Couldn't review the supplies request just now.",
                                        "I couldn't verify that clinic offer.",
                                        "Failed to inspect the clinic supplies details.",
                                        "I wasn't able to review that request.",
                                        "Could not check the medical offer properly.",
                                        "Checking that offer didn't work out.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko masuri ang kahilingan para sa suplay.",
                                        "Hindi ko masilip ang alok sa suplay ng klinika.",
                                        "Hindi maproseso ang alok na 'yan.",
                                        "May nagkaproblema habang sinusuri ang medikal na alok.",
                                        "Hindi masuri ang kahilingan sa suplay ngayon.",
                                        "Hindi ko makumpirma ang alok na 'yon sa klinika.",
                                        "Bigo sa pagsusuri ng detalye ng suplay sa klinika.",
                                        "Hindi ko nasuri ang kahilingang iyon.",
                                        "Hindi maayos na nasuri ang medikal na alok.",
                                        "Hindi gumana ang pagsusuri sa alok na 'yon.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "quest.clinic_supplies.offer",
            ["textRoles"] = {
                {
                    ["fallback"] = "I couldn't check that clinic-supplies request.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.quest.clinic_supplies.offer.failed.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I couldn't check that clinic-supplies request.",
                            "Unable to look over the clinic supply offer.",
                            "The offer couldn't be processed.",
                            "Something went wrong while checking the medical offer.",
                            "Couldn't review the supplies request just now.",
                            "I couldn't verify that clinic offer.",
                            "Failed to inspect the clinic supplies details.",
                            "I wasn't able to review that request.",
                            "Could not check the medical offer properly.",
                            "Checking that offer didn't work out.",
                        },
                        ["TL"] = {
                            "Hindi ko masuri ang kahilingan para sa suplay.",
                            "Hindi ko masilip ang alok sa suplay ng klinika.",
                            "Hindi maproseso ang alok na 'yan.",
                            "May nagkaproblema habang sinusuri ang medikal na alok.",
                            "Hindi masuri ang kahilingan sa suplay ngayon.",
                            "Hindi ko makumpirma ang alok na 'yon sa klinika.",
                            "Bigo sa pagsusuri ng detalye ng suplay sa klinika.",
                            "Hindi ko nasuri ang kahilingang iyon.",
                            "Hindi maayos na nasuri ang medikal na alok.",
                            "Hindi gumana ang pagsusuri sa alok na 'yon.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "quest.clinic_supplies.offer.failed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "failed",
            ["sourceId"] = "quest.clinic_supplies.offer.failed",
            ["sourcePath"] = "adopters/hoomans/dialogue/quest_content/quest_clinic_supplies_offer_failed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/QuestContent",
        ["namespace"] = "quest.clinic_supplies.offer",
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
                ["category"] = "projecthoomans:quest_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.quest",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/quest.json",
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
                                        "I couldn't check that clinic-supplies request.",
                                        "Unable to look over the clinic supply offer.",
                                        "The offer couldn't be processed.",
                                        "Something went wrong while checking the medical offer.",
                                        "Couldn't review the supplies request just now.",
                                        "I couldn't verify that clinic offer.",
                                        "Failed to inspect the clinic supplies details.",
                                        "I wasn't able to review that request.",
                                        "Could not check the medical offer properly.",
                                        "Checking that offer didn't work out.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko masuri ang kahilingan para sa suplay.",
                                        "Hindi ko masilip ang alok sa suplay ng klinika.",
                                        "Hindi maproseso ang alok na 'yan.",
                                        "May nagkaproblema habang sinusuri ang medikal na alok.",
                                        "Hindi masuri ang kahilingan sa suplay ngayon.",
                                        "Hindi ko makumpirma ang alok na 'yon sa klinika.",
                                        "Bigo sa pagsusuri ng detalye ng suplay sa klinika.",
                                        "Hindi ko nasuri ang kahilingang iyon.",
                                        "Hindi maayos na nasuri ang medikal na alok.",
                                        "Hindi gumana ang pagsusuri sa alok na 'yon.",
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
            ["responsePlanID"] = "quest.clinic_supplies.offer.failed",
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
                            ["fallback"] = "I couldn't check that clinic-supplies request.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.quest.clinic_supplies.offer.failed.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/quest_content/quest_clinic_supplies_offer_failed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I couldn't check that clinic-supplies request.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.quest.clinic_supplies.offer.failed.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I couldn't check that clinic-supplies request.",
                        "Unable to look over the clinic supply offer.",
                        "The offer couldn't be processed.",
                        "Something went wrong while checking the medical offer.",
                        "Couldn't review the supplies request just now.",
                        "I couldn't verify that clinic offer.",
                        "Failed to inspect the clinic supplies details.",
                        "I wasn't able to review that request.",
                        "Could not check the medical offer properly.",
                        "Checking that offer didn't work out.",
                    },
                    ["TL"] = {
                        "Hindi ko masuri ang kahilingan para sa suplay.",
                        "Hindi ko masilip ang alok sa suplay ng klinika.",
                        "Hindi maproseso ang alok na 'yan.",
                        "May nagkaproblema habang sinusuri ang medikal na alok.",
                        "Hindi masuri ang kahilingan sa suplay ngayon.",
                        "Hindi ko makumpirma ang alok na 'yon sa klinika.",
                        "Bigo sa pagsusuri ng detalye ng suplay sa klinika.",
                        "Hindi ko nasuri ang kahilingang iyon.",
                        "Hindi maayos na nasuri ang medikal na alok.",
                        "Hindi gumana ang pagsusuri sa alok na 'yon.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "quest_content",
        ["exchangeFamily"] = {
            ["familyID"] = "quest.clinic_supplies.offer.queued",
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
                                ["fallback"] = "I can help with the clinic supplies.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.quest.clinic_supplies.offer.queued.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I can help with the clinic supplies.",
                                        "I'm ready to lend a hand with those medical goods.",
                                        "Put me down for the clinic supply run.",
                                        "I'm available to help gather medical gear.",
                                        "I can assist with securing what the clinic needs.",
                                        "Count me in for the clinic supplies.",
                                        "I'll pitch in on that medical supply run.",
                                        "I can offer my help for the clinic task.",
                                        "Glad to help get those supplies to the clinic.",
                                        "I can take on part of that clinic effort.",
                                    },
                                    ["TL"] = {
                                        "Matutulungan kita sa mga suplay ng klinika.",
                                        "Handa akong tumulong sa mga medikal na gamit na 'yon.",
                                        "Ilista mo ako para sa pagkuha ng suplay sa klinika.",
                                        "Available ako para tumulong mag-ipon ng gamot.",
                                        "Makatutulong ako sa pagkuha ng kailangan ng klinika.",
                                        "Isama mo ako sa suplay para sa klinika.",
                                        "Tutulong ako sa pagkuha ng medikal na suplay.",
                                        "Maaari kong ialok ang tulong ko sa gawaing ito sa klinika.",
                                        "Masaya akong makatulong maihatid ang mga suplay sa klinika.",
                                        "Kaya kong gampanan ang bahagi ng gawaing 'yan sa klinika.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "quest.clinic_supplies.offer",
            ["textRoles"] = {
                {
                    ["fallback"] = "I can help with the clinic supplies.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.quest.clinic_supplies.offer.queued.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I can help with the clinic supplies.",
                            "I'm ready to lend a hand with those medical goods.",
                            "Put me down for the clinic supply run.",
                            "I'm available to help gather medical gear.",
                            "I can assist with securing what the clinic needs.",
                            "Count me in for the clinic supplies.",
                            "I'll pitch in on that medical supply run.",
                            "I can offer my help for the clinic task.",
                            "Glad to help get those supplies to the clinic.",
                            "I can take on part of that clinic effort.",
                        },
                        ["TL"] = {
                            "Matutulungan kita sa mga suplay ng klinika.",
                            "Handa akong tumulong sa mga medikal na gamit na 'yon.",
                            "Ilista mo ako para sa pagkuha ng suplay sa klinika.",
                            "Available ako para tumulong mag-ipon ng gamot.",
                            "Makatutulong ako sa pagkuha ng kailangan ng klinika.",
                            "Isama mo ako sa suplay para sa klinika.",
                            "Tutulong ako sa pagkuha ng medikal na suplay.",
                            "Maaari kong ialok ang tulong ko sa gawaing ito sa klinika.",
                            "Masaya akong makatulong maihatid ang mga suplay sa klinika.",
                            "Kaya kong gampanan ang bahagi ng gawaing 'yan sa klinika.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "quest.clinic_supplies.offer.queued",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "queued",
            ["sourceId"] = "quest.clinic_supplies.offer.queued",
            ["sourcePath"] = "adopters/hoomans/dialogue/quest_content/quest_clinic_supplies_offer_queued.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/QuestContent",
        ["namespace"] = "quest.clinic_supplies.offer",
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
                ["category"] = "projecthoomans:quest_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.quest",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/quest.json",
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
                                        "I can help with the clinic supplies.",
                                        "I'm ready to lend a hand with those medical goods.",
                                        "Put me down for the clinic supply run.",
                                        "I'm available to help gather medical gear.",
                                        "I can assist with securing what the clinic needs.",
                                        "Count me in for the clinic supplies.",
                                        "I'll pitch in on that medical supply run.",
                                        "I can offer my help for the clinic task.",
                                        "Glad to help get those supplies to the clinic.",
                                        "I can take on part of that clinic effort.",
                                    },
                                    ["TL"] = {
                                        "Matutulungan kita sa mga suplay ng klinika.",
                                        "Handa akong tumulong sa mga medikal na gamit na 'yon.",
                                        "Ilista mo ako para sa pagkuha ng suplay sa klinika.",
                                        "Available ako para tumulong mag-ipon ng gamot.",
                                        "Makatutulong ako sa pagkuha ng kailangan ng klinika.",
                                        "Isama mo ako sa suplay para sa klinika.",
                                        "Tutulong ako sa pagkuha ng medikal na suplay.",
                                        "Maaari kong ialok ang tulong ko sa gawaing ito sa klinika.",
                                        "Masaya akong makatulong maihatid ang mga suplay sa klinika.",
                                        "Kaya kong gampanan ang bahagi ng gawaing 'yan sa klinika.",
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
            ["responsePlanID"] = "quest.clinic_supplies.offer.queued",
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
                            ["fallback"] = "I can help with the clinic supplies.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.quest.clinic_supplies.offer.queued.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/quest_content/quest_clinic_supplies_offer_queued.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I can help with the clinic supplies.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.quest.clinic_supplies.offer.queued.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I can help with the clinic supplies.",
                        "I'm ready to lend a hand with those medical goods.",
                        "Put me down for the clinic supply run.",
                        "I'm available to help gather medical gear.",
                        "I can assist with securing what the clinic needs.",
                        "Count me in for the clinic supplies.",
                        "I'll pitch in on that medical supply run.",
                        "I can offer my help for the clinic task.",
                        "Glad to help get those supplies to the clinic.",
                        "I can take on part of that clinic effort.",
                    },
                    ["TL"] = {
                        "Matutulungan kita sa mga suplay ng klinika.",
                        "Handa akong tumulong sa mga medikal na gamit na 'yon.",
                        "Ilista mo ako para sa pagkuha ng suplay sa klinika.",
                        "Available ako para tumulong mag-ipon ng gamot.",
                        "Makatutulong ako sa pagkuha ng kailangan ng klinika.",
                        "Isama mo ako sa suplay para sa klinika.",
                        "Tutulong ako sa pagkuha ng medikal na suplay.",
                        "Maaari kong ialok ang tulong ko sa gawaing ito sa klinika.",
                        "Masaya akong makatulong maihatid ang mga suplay sa klinika.",
                        "Kaya kong gampanan ang bahagi ng gawaing 'yan sa klinika.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "quest_content",
        ["exchangeFamily"] = {
            ["familyID"] = "quest.clinic_supplies.offer.rejected",
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
                                ["fallback"] = "I can't take that clinic-supplies request right now.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.quest.clinic_supplies.offer.rejected.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I can't take that clinic-supplies request right now.",
                                        "I have to turn down the clinic offer for now.",
                                        "Not able to help with medical supplies today.",
                                        "I can't sign up for that clinic mission.",
                                        "Must decline the clinic supplies offer.",
                                        "I can't accept the offer at this time.",
                                        "Medical supply run isn't something I can do now.",
                                        "I'll have to pass on this clinic offer.",
                                        "Can't take on the medical task right now.",
                                        "I must reject that offer for the moment.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko matatanggap ang kahilingan para sa suplay ngayon.",
                                        "Kailangan kong tanggihan ang alok sa klinika sa ngayon.",
                                        "Hindi makakatulong sa mga medikal na suplay ngayon.",
                                        "Hindi ako makakasali sa misyong 'yan sa klinika.",
                                        "Kailangang tanggihan ang alok na suplay sa klinika.",
                                        "Hindi ko matatanggap ang alok sa panahong ito.",
                                        "Hindi ko kayang gawin ang pagkuha ng medikal na suplay ngayon.",
                                        "Lalagpasan ko muna ang alok na 'to para sa klinika.",
                                        "Hindi maaring hawakan ang medikal na gawain ngayon.",
                                        "Kailangan kong tanggihan ang alok na 'yan sa sandaling ito.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "quest.clinic_supplies.offer",
            ["textRoles"] = {
                {
                    ["fallback"] = "I can't take that clinic-supplies request right now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.quest.clinic_supplies.offer.rejected.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I can't take that clinic-supplies request right now.",
                            "I have to turn down the clinic offer for now.",
                            "Not able to help with medical supplies today.",
                            "I can't sign up for that clinic mission.",
                            "Must decline the clinic supplies offer.",
                            "I can't accept the offer at this time.",
                            "Medical supply run isn't something I can do now.",
                            "I'll have to pass on this clinic offer.",
                            "Can't take on the medical task right now.",
                            "I must reject that offer for the moment.",
                        },
                        ["TL"] = {
                            "Hindi ko matatanggap ang kahilingan para sa suplay ngayon.",
                            "Kailangan kong tanggihan ang alok sa klinika sa ngayon.",
                            "Hindi makakatulong sa mga medikal na suplay ngayon.",
                            "Hindi ako makakasali sa misyong 'yan sa klinika.",
                            "Kailangang tanggihan ang alok na suplay sa klinika.",
                            "Hindi ko matatanggap ang alok sa panahong ito.",
                            "Hindi ko kayang gawin ang pagkuha ng medikal na suplay ngayon.",
                            "Lalagpasan ko muna ang alok na 'to para sa klinika.",
                            "Hindi maaring hawakan ang medikal na gawain ngayon.",
                            "Kailangan kong tanggihan ang alok na 'yan sa sandaling ito.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "quest.clinic_supplies.offer.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "rejected",
            ["sourceId"] = "quest.clinic_supplies.offer.rejected",
            ["sourcePath"] = "adopters/hoomans/dialogue/quest_content/quest_clinic_supplies_offer_rejected.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/QuestContent",
        ["namespace"] = "quest.clinic_supplies.offer",
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
                ["category"] = "projecthoomans:quest_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.quest",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/quest.json",
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
                                        "I can't take that clinic-supplies request right now.",
                                        "I have to turn down the clinic offer for now.",
                                        "Not able to help with medical supplies today.",
                                        "I can't sign up for that clinic mission.",
                                        "Must decline the clinic supplies offer.",
                                        "I can't accept the offer at this time.",
                                        "Medical supply run isn't something I can do now.",
                                        "I'll have to pass on this clinic offer.",
                                        "Can't take on the medical task right now.",
                                        "I must reject that offer for the moment.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko matatanggap ang kahilingan para sa suplay ngayon.",
                                        "Kailangan kong tanggihan ang alok sa klinika sa ngayon.",
                                        "Hindi makakatulong sa mga medikal na suplay ngayon.",
                                        "Hindi ako makakasali sa misyong 'yan sa klinika.",
                                        "Kailangang tanggihan ang alok na suplay sa klinika.",
                                        "Hindi ko matatanggap ang alok sa panahong ito.",
                                        "Hindi ko kayang gawin ang pagkuha ng medikal na suplay ngayon.",
                                        "Lalagpasan ko muna ang alok na 'to para sa klinika.",
                                        "Hindi maaring hawakan ang medikal na gawain ngayon.",
                                        "Kailangan kong tanggihan ang alok na 'yan sa sandaling ito.",
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
            ["responsePlanID"] = "quest.clinic_supplies.offer.rejected",
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
                            ["fallback"] = "I can't take that clinic-supplies request right now.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.quest.clinic_supplies.offer.rejected.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/quest_content/quest_clinic_supplies_offer_rejected.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I can't take that clinic-supplies request right now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.quest.clinic_supplies.offer.rejected.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I can't take that clinic-supplies request right now.",
                        "I have to turn down the clinic offer for now.",
                        "Not able to help with medical supplies today.",
                        "I can't sign up for that clinic mission.",
                        "Must decline the clinic supplies offer.",
                        "I can't accept the offer at this time.",
                        "Medical supply run isn't something I can do now.",
                        "I'll have to pass on this clinic offer.",
                        "Can't take on the medical task right now.",
                        "I must reject that offer for the moment.",
                    },
                    ["TL"] = {
                        "Hindi ko matatanggap ang kahilingan para sa suplay ngayon.",
                        "Kailangan kong tanggihan ang alok sa klinika sa ngayon.",
                        "Hindi makakatulong sa mga medikal na suplay ngayon.",
                        "Hindi ako makakasali sa misyong 'yan sa klinika.",
                        "Kailangang tanggihan ang alok na suplay sa klinika.",
                        "Hindi ko matatanggap ang alok sa panahong ito.",
                        "Hindi ko kayang gawin ang pagkuha ng medikal na suplay ngayon.",
                        "Lalagpasan ko muna ang alok na 'to para sa klinika.",
                        "Hindi maaring hawakan ang medikal na gawain ngayon.",
                        "Kailangan kong tanggihan ang alok na 'yan sa sandaling ito.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "quest_content",
        ["exchangeFamily"] = {
            ["familyID"] = "quest.clinic_supplies.status.failed",
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
                                ["fallback"] = "I couldn't check that request.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.quest.clinic_supplies.status.failed.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I couldn't check that request.",
                                        "Unable to verify the status of the clinic supplies.",
                                        "Status check on the medical supplies failed.",
                                        "Couldn't retrieve the clinic quest details.",
                                        "I wasn't able to inspect the request status.",
                                        "Failed to look up where we stand on clinic supplies.",
                                        "Couldn't confirm progress on that task.",
                                        "Unable to check our clinic supplies progress.",
                                        "Checking that request didn't go through.",
                                        "Couldn't get a status read on the medical run.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko masuri ang kahilingang iyon.",
                                        "Hindi ko makumpirma ang katayuan ng mga suplay sa klinika.",
                                        "Bigo ang pagsusuri sa katayuan ng mga suplay.",
                                        "Hindi makuha ang mga detalye ng misyon sa klinika.",
                                        "Hindi ko nasuri ang katayuan ng kahilingan.",
                                        "Bigo sa pagtingin sa katayuan ng suplay sa klinika.",
                                        "Hindi makumpirma ang progreso sa gawaing 'yan.",
                                        "Hindi masuri ang progreso natin sa suplay sa klinika.",
                                        "Hindi natuloy ang pagsusuri sa kahilingang 'yan.",
                                        "Hindi makakuha ng ulat sa medikal na lakad.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "quest.clinic_supplies.status",
            ["textRoles"] = {
                {
                    ["fallback"] = "I couldn't check that request.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.quest.clinic_supplies.status.failed.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I couldn't check that request.",
                            "Unable to verify the status of the clinic supplies.",
                            "Status check on the medical supplies failed.",
                            "Couldn't retrieve the clinic quest details.",
                            "I wasn't able to inspect the request status.",
                            "Failed to look up where we stand on clinic supplies.",
                            "Couldn't confirm progress on that task.",
                            "Unable to check our clinic supplies progress.",
                            "Checking that request didn't go through.",
                            "Couldn't get a status read on the medical run.",
                        },
                        ["TL"] = {
                            "Hindi ko masuri ang kahilingang iyon.",
                            "Hindi ko makumpirma ang katayuan ng mga suplay sa klinika.",
                            "Bigo ang pagsusuri sa katayuan ng mga suplay.",
                            "Hindi makuha ang mga detalye ng misyon sa klinika.",
                            "Hindi ko nasuri ang katayuan ng kahilingan.",
                            "Bigo sa pagtingin sa katayuan ng suplay sa klinika.",
                            "Hindi makumpirma ang progreso sa gawaing 'yan.",
                            "Hindi masuri ang progreso natin sa suplay sa klinika.",
                            "Hindi natuloy ang pagsusuri sa kahilingang 'yan.",
                            "Hindi makakuha ng ulat sa medikal na lakad.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "quest.clinic_supplies.status.failed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "failed",
            ["sourceId"] = "quest.clinic_supplies.status.failed",
            ["sourcePath"] = "adopters/hoomans/dialogue/quest_content/quest_clinic_supplies_status_failed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/QuestContent",
        ["namespace"] = "quest.clinic_supplies.status",
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
                ["category"] = "projecthoomans:quest_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.quest",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/quest.json",
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
                                        "I couldn't check that request.",
                                        "Unable to verify the status of the clinic supplies.",
                                        "Status check on the medical supplies failed.",
                                        "Couldn't retrieve the clinic quest details.",
                                        "I wasn't able to inspect the request status.",
                                        "Failed to look up where we stand on clinic supplies.",
                                        "Couldn't confirm progress on that task.",
                                        "Unable to check our clinic supplies progress.",
                                        "Checking that request didn't go through.",
                                        "Couldn't get a status read on the medical run.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko masuri ang kahilingang iyon.",
                                        "Hindi ko makumpirma ang katayuan ng mga suplay sa klinika.",
                                        "Bigo ang pagsusuri sa katayuan ng mga suplay.",
                                        "Hindi makuha ang mga detalye ng misyon sa klinika.",
                                        "Hindi ko nasuri ang katayuan ng kahilingan.",
                                        "Bigo sa pagtingin sa katayuan ng suplay sa klinika.",
                                        "Hindi makumpirma ang progreso sa gawaing 'yan.",
                                        "Hindi masuri ang progreso natin sa suplay sa klinika.",
                                        "Hindi natuloy ang pagsusuri sa kahilingang 'yan.",
                                        "Hindi makakuha ng ulat sa medikal na lakad.",
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
            ["responsePlanID"] = "quest.clinic_supplies.status.failed",
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
                            ["fallback"] = "I couldn't check that request.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.quest.clinic_supplies.status.failed.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/quest_content/quest_clinic_supplies_status_failed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I couldn't check that request.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.quest.clinic_supplies.status.failed.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I couldn't check that request.",
                        "Unable to verify the status of the clinic supplies.",
                        "Status check on the medical supplies failed.",
                        "Couldn't retrieve the clinic quest details.",
                        "I wasn't able to inspect the request status.",
                        "Failed to look up where we stand on clinic supplies.",
                        "Couldn't confirm progress on that task.",
                        "Unable to check our clinic supplies progress.",
                        "Checking that request didn't go through.",
                        "Couldn't get a status read on the medical run.",
                    },
                    ["TL"] = {
                        "Hindi ko masuri ang kahilingang iyon.",
                        "Hindi ko makumpirma ang katayuan ng mga suplay sa klinika.",
                        "Bigo ang pagsusuri sa katayuan ng mga suplay.",
                        "Hindi makuha ang mga detalye ng misyon sa klinika.",
                        "Hindi ko nasuri ang katayuan ng kahilingan.",
                        "Bigo sa pagtingin sa katayuan ng suplay sa klinika.",
                        "Hindi makumpirma ang progreso sa gawaing 'yan.",
                        "Hindi masuri ang progreso natin sa suplay sa klinika.",
                        "Hindi natuloy ang pagsusuri sa kahilingang 'yan.",
                        "Hindi makakuha ng ulat sa medikal na lakad.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "quest_content",
        ["exchangeFamily"] = {
            ["familyID"] = "quest.clinic_supplies.status.queued",
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
                                ["fallback"] = "I'll check the clinic-supplies request.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.quest.clinic_supplies.status.queued.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'll check the clinic-supplies request.",
                                        "I'll see how we're doing on those medical supplies.",
                                        "Checking our progress on the clinic gear now.",
                                        "I'll look into the status of the clinic task.",
                                        "Reviewing where we stand with the clinic supplies.",
                                        "I'll pull up the clinic supply checklist.",
                                        "Let me verify our clinic supplies count.",
                                        "I'm checking the medical supplies progress.",
                                        "I'll inspect the clinic supplies status for you.",
                                        "Looking into the clinic request right now.",
                                    },
                                    ["TL"] = {
                                        "Susuriin ko ang kahilingan para sa suplay ng klinika.",
                                        "Titingnan ko kung kamusta na ang mga medikal na suplay natin.",
                                        "Sinusuri na ang progreso natin sa gamot para sa klinika.",
                                        "Sisiyasatin ko ang katayuan ng gawain sa klinika.",
                                        "Sinusuri kung nasaan na tayo sa mga suplay ng klinika.",
                                        "Kukunin ko ang listahan ng suplay para sa klinika.",
                                        "Hayaan mong kumpirmahin ko ang bilang ng suplay sa klinika.",
                                        "Sinusuri ko ang progreso ng mga medikal na suplay.",
                                        "Titingnan ko ang katayuan ng suplay sa klinika para sa'yo.",
                                        "Sinisiyasat ko na ang kahilingan ng klinika ngayon.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "quest.clinic_supplies.status",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'll check the clinic-supplies request.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.quest.clinic_supplies.status.queued.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I'll check the clinic-supplies request.",
                            "I'll see how we're doing on those medical supplies.",
                            "Checking our progress on the clinic gear now.",
                            "I'll look into the status of the clinic task.",
                            "Reviewing where we stand with the clinic supplies.",
                            "I'll pull up the clinic supply checklist.",
                            "Let me verify our clinic supplies count.",
                            "I'm checking the medical supplies progress.",
                            "I'll inspect the clinic supplies status for you.",
                            "Looking into the clinic request right now.",
                        },
                        ["TL"] = {
                            "Susuriin ko ang kahilingan para sa suplay ng klinika.",
                            "Titingnan ko kung kamusta na ang mga medikal na suplay natin.",
                            "Sinusuri na ang progreso natin sa gamot para sa klinika.",
                            "Sisiyasatin ko ang katayuan ng gawain sa klinika.",
                            "Sinusuri kung nasaan na tayo sa mga suplay ng klinika.",
                            "Kukunin ko ang listahan ng suplay para sa klinika.",
                            "Hayaan mong kumpirmahin ko ang bilang ng suplay sa klinika.",
                            "Sinusuri ko ang progreso ng mga medikal na suplay.",
                            "Titingnan ko ang katayuan ng suplay sa klinika para sa'yo.",
                            "Sinisiyasat ko na ang kahilingan ng klinika ngayon.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "quest.clinic_supplies.status.queued",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "queued",
            ["sourceId"] = "quest.clinic_supplies.status.queued",
            ["sourcePath"] = "adopters/hoomans/dialogue/quest_content/quest_clinic_supplies_status_queued.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/QuestContent",
        ["namespace"] = "quest.clinic_supplies.status",
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
                ["category"] = "projecthoomans:quest_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.quest",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/quest.json",
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
                                        "I'll check the clinic-supplies request.",
                                        "I'll see how we're doing on those medical supplies.",
                                        "Checking our progress on the clinic gear now.",
                                        "I'll look into the status of the clinic task.",
                                        "Reviewing where we stand with the clinic supplies.",
                                        "I'll pull up the clinic supply checklist.",
                                        "Let me verify our clinic supplies count.",
                                        "I'm checking the medical supplies progress.",
                                        "I'll inspect the clinic supplies status for you.",
                                        "Looking into the clinic request right now.",
                                    },
                                    ["TL"] = {
                                        "Susuriin ko ang kahilingan para sa suplay ng klinika.",
                                        "Titingnan ko kung kamusta na ang mga medikal na suplay natin.",
                                        "Sinusuri na ang progreso natin sa gamot para sa klinika.",
                                        "Sisiyasatin ko ang katayuan ng gawain sa klinika.",
                                        "Sinusuri kung nasaan na tayo sa mga suplay ng klinika.",
                                        "Kukunin ko ang listahan ng suplay para sa klinika.",
                                        "Hayaan mong kumpirmahin ko ang bilang ng suplay sa klinika.",
                                        "Sinusuri ko ang progreso ng mga medikal na suplay.",
                                        "Titingnan ko ang katayuan ng suplay sa klinika para sa'yo.",
                                        "Sinisiyasat ko na ang kahilingan ng klinika ngayon.",
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
            ["responsePlanID"] = "quest.clinic_supplies.status.queued",
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
                            ["fallback"] = "I'll check the clinic-supplies request.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.quest.clinic_supplies.status.queued.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/quest_content/quest_clinic_supplies_status_queued.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'll check the clinic-supplies request.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.quest.clinic_supplies.status.queued.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I'll check the clinic-supplies request.",
                        "I'll see how we're doing on those medical supplies.",
                        "Checking our progress on the clinic gear now.",
                        "I'll look into the status of the clinic task.",
                        "Reviewing where we stand with the clinic supplies.",
                        "I'll pull up the clinic supply checklist.",
                        "Let me verify our clinic supplies count.",
                        "I'm checking the medical supplies progress.",
                        "I'll inspect the clinic supplies status for you.",
                        "Looking into the clinic request right now.",
                    },
                    ["TL"] = {
                        "Susuriin ko ang kahilingan para sa suplay ng klinika.",
                        "Titingnan ko kung kamusta na ang mga medikal na suplay natin.",
                        "Sinusuri na ang progreso natin sa gamot para sa klinika.",
                        "Sisiyasatin ko ang katayuan ng gawain sa klinika.",
                        "Sinusuri kung nasaan na tayo sa mga suplay ng klinika.",
                        "Kukunin ko ang listahan ng suplay para sa klinika.",
                        "Hayaan mong kumpirmahin ko ang bilang ng suplay sa klinika.",
                        "Sinusuri ko ang progreso ng mga medikal na suplay.",
                        "Titingnan ko ang katayuan ng suplay sa klinika para sa'yo.",
                        "Sinisiyasat ko na ang kahilingan ng klinika ngayon.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "quest_content",
        ["exchangeFamily"] = {
            ["familyID"] = "quest.clinic_supplies.status.rejected",
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
                                ["fallback"] = "I can't check that request right now.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.quest.clinic_supplies.status.rejected.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I can't check that request right now.",
                                        "Too busy to review the clinic task status.",
                                        "Can't inspect the medical supplies list at the moment.",
                                        "Not able to pull up that status right now.",
                                        "I won't be checking that request today.",
                                        "I have to decline looking into the status now.",
                                        "Can't check the clinic supplies progress right now.",
                                        "Unable to review the request at this time.",
                                        "I can't follow up on that clinic task currently.",
                                        "Not checking clinic status now. Ask later.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko masuri ang kahilingang iyon ngayon.",
                                        "Masyadong abala para suriin ang katayuan ng klinika.",
                                        "Hindi masisilip ang listahan ng suplay sa sandaling ito.",
                                        "Hindi ko mabuksan ang katayuang 'yan ngayon.",
                                        "Hindi ko susuriin ang kahilingang 'yan ngayon.",
                                        "Kailangan kong tanggihan ang pagsilip sa katayuan ngayon.",
                                        "Hindi masusuri ang progreso ng suplay sa klinika ngayon.",
                                        "Hindi magagawang suriin ang kahilingan sa oras na 'to.",
                                        "Hindi ko matututukan ang gawaing 'yan sa klinika sa kasalukuyan.",
                                        "Hindi titingnan ang katayuan sa klinika ngayon. Magtanong mamaya.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "quest.clinic_supplies.status",
            ["textRoles"] = {
                {
                    ["fallback"] = "I can't check that request right now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.quest.clinic_supplies.status.rejected.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I can't check that request right now.",
                            "Too busy to review the clinic task status.",
                            "Can't inspect the medical supplies list at the moment.",
                            "Not able to pull up that status right now.",
                            "I won't be checking that request today.",
                            "I have to decline looking into the status now.",
                            "Can't check the clinic supplies progress right now.",
                            "Unable to review the request at this time.",
                            "I can't follow up on that clinic task currently.",
                            "Not checking clinic status now. Ask later.",
                        },
                        ["TL"] = {
                            "Hindi ko masuri ang kahilingang iyon ngayon.",
                            "Masyadong abala para suriin ang katayuan ng klinika.",
                            "Hindi masisilip ang listahan ng suplay sa sandaling ito.",
                            "Hindi ko mabuksan ang katayuang 'yan ngayon.",
                            "Hindi ko susuriin ang kahilingang 'yan ngayon.",
                            "Kailangan kong tanggihan ang pagsilip sa katayuan ngayon.",
                            "Hindi masusuri ang progreso ng suplay sa klinika ngayon.",
                            "Hindi magagawang suriin ang kahilingan sa oras na 'to.",
                            "Hindi ko matututukan ang gawaing 'yan sa klinika sa kasalukuyan.",
                            "Hindi titingnan ang katayuan sa klinika ngayon. Magtanong mamaya.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "quest.clinic_supplies.status.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "rejected",
            ["sourceId"] = "quest.clinic_supplies.status.rejected",
            ["sourcePath"] = "adopters/hoomans/dialogue/quest_content/quest_clinic_supplies_status_rejected.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/QuestContent",
        ["namespace"] = "quest.clinic_supplies.status",
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
                ["category"] = "projecthoomans:quest_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.quest",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/quest.json",
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
                                        "I can't check that request right now.",
                                        "Too busy to review the clinic task status.",
                                        "Can't inspect the medical supplies list at the moment.",
                                        "Not able to pull up that status right now.",
                                        "I won't be checking that request today.",
                                        "I have to decline looking into the status now.",
                                        "Can't check the clinic supplies progress right now.",
                                        "Unable to review the request at this time.",
                                        "I can't follow up on that clinic task currently.",
                                        "Not checking clinic status now. Ask later.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko masuri ang kahilingang iyon ngayon.",
                                        "Masyadong abala para suriin ang katayuan ng klinika.",
                                        "Hindi masisilip ang listahan ng suplay sa sandaling ito.",
                                        "Hindi ko mabuksan ang katayuang 'yan ngayon.",
                                        "Hindi ko susuriin ang kahilingang 'yan ngayon.",
                                        "Kailangan kong tanggihan ang pagsilip sa katayuan ngayon.",
                                        "Hindi masusuri ang progreso ng suplay sa klinika ngayon.",
                                        "Hindi magagawang suriin ang kahilingan sa oras na 'to.",
                                        "Hindi ko matututukan ang gawaing 'yan sa klinika sa kasalukuyan.",
                                        "Hindi titingnan ang katayuan sa klinika ngayon. Magtanong mamaya.",
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
            ["responsePlanID"] = "quest.clinic_supplies.status.rejected",
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
                            ["fallback"] = "I can't check that request right now.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.quest.clinic_supplies.status.rejected.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/quest_content/quest_clinic_supplies_status_rejected.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I can't check that request right now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.quest.clinic_supplies.status.rejected.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I can't check that request right now.",
                        "Too busy to review the clinic task status.",
                        "Can't inspect the medical supplies list at the moment.",
                        "Not able to pull up that status right now.",
                        "I won't be checking that request today.",
                        "I have to decline looking into the status now.",
                        "Can't check the clinic supplies progress right now.",
                        "Unable to review the request at this time.",
                        "I can't follow up on that clinic task currently.",
                        "Not checking clinic status now. Ask later.",
                    },
                    ["TL"] = {
                        "Hindi ko masuri ang kahilingang iyon ngayon.",
                        "Masyadong abala para suriin ang katayuan ng klinika.",
                        "Hindi masisilip ang listahan ng suplay sa sandaling ito.",
                        "Hindi ko mabuksan ang katayuang 'yan ngayon.",
                        "Hindi ko susuriin ang kahilingang 'yan ngayon.",
                        "Kailangan kong tanggihan ang pagsilip sa katayuan ngayon.",
                        "Hindi masusuri ang progreso ng suplay sa klinika ngayon.",
                        "Hindi magagawang suriin ang kahilingan sa oras na 'to.",
                        "Hindi ko matututukan ang gawaing 'yan sa klinika sa kasalukuyan.",
                        "Hindi titingnan ang katayuan sa klinika ngayon. Magtanong mamaya.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "quest_content",
        ["exchangeFamily"] = {
            ["familyID"] = "quest.clinic_supplies.turn_in.failed",
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
                                ["fallback"] = "I couldn't turn in the clinic supplies.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.quest.clinic_supplies.turn_in.failed.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I couldn't turn in the clinic supplies.",
                                        "Something went wrong handing over the medical gear.",
                                        "Turn-in failed. Check if we have every item.",
                                        "Unable to complete the clinic supply delivery.",
                                        "I wasn't able to drop off the clinic supplies.",
                                        "Failed to hand in the requested medical items.",
                                        "Couldn't finalize the clinic supplies handover.",
                                        "Delivery of clinic goods couldn't be registered.",
                                        "Could not complete the turn-in for the clinic.",
                                        "Turn-in was unsuccessful. Try again.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko maipasa ang mga suplay ng klinika.",
                                        "May nagkaproblema sa pag-abot ng mga medikal na gamit.",
                                        "Bigo ang pagpasa. Tignan kung kumpleto ang bawat gamit.",
                                        "Hindi makumpleto ang paghahatid ng suplay sa klinika.",
                                        "Hindi ko naibigay ang mga suplay para sa klinika.",
                                        "Bigo sa pagpasa ng hinihiling na medikal na kagamitan.",
                                        "Hindi matapos ang paglilipat ng suplay sa klinika.",
                                        "Hindi naitala ang paghahatid ng gamit sa klinika.",
                                        "Hindi makumpleto ang pagpasa para sa klinika.",
                                        "Hindi nagtagumpay ang pagpasa. Subukan ulit.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "quest.clinic_supplies.turn_in",
            ["textRoles"] = {
                {
                    ["fallback"] = "I couldn't turn in the clinic supplies.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.quest.clinic_supplies.turn_in.failed.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I couldn't turn in the clinic supplies.",
                            "Something went wrong handing over the medical gear.",
                            "Turn-in failed. Check if we have every item.",
                            "Unable to complete the clinic supply delivery.",
                            "I wasn't able to drop off the clinic supplies.",
                            "Failed to hand in the requested medical items.",
                            "Couldn't finalize the clinic supplies handover.",
                            "Delivery of clinic goods couldn't be registered.",
                            "Could not complete the turn-in for the clinic.",
                            "Turn-in was unsuccessful. Try again.",
                        },
                        ["TL"] = {
                            "Hindi ko maipasa ang mga suplay ng klinika.",
                            "May nagkaproblema sa pag-abot ng mga medikal na gamit.",
                            "Bigo ang pagpasa. Tignan kung kumpleto ang bawat gamit.",
                            "Hindi makumpleto ang paghahatid ng suplay sa klinika.",
                            "Hindi ko naibigay ang mga suplay para sa klinika.",
                            "Bigo sa pagpasa ng hinihiling na medikal na kagamitan.",
                            "Hindi matapos ang paglilipat ng suplay sa klinika.",
                            "Hindi naitala ang paghahatid ng gamit sa klinika.",
                            "Hindi makumpleto ang pagpasa para sa klinika.",
                            "Hindi nagtagumpay ang pagpasa. Subukan ulit.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "quest.clinic_supplies.turn_in.failed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "failed",
            ["sourceId"] = "quest.clinic_supplies.turn_in.failed",
            ["sourcePath"] = "adopters/hoomans/dialogue/quest_content/quest_clinic_supplies_turn_in_failed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/QuestContent",
        ["namespace"] = "quest.clinic_supplies.turn_in",
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
                ["category"] = "projecthoomans:quest_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.quest",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/quest.json",
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
                                        "I couldn't turn in the clinic supplies.",
                                        "Something went wrong handing over the medical gear.",
                                        "Turn-in failed. Check if we have every item.",
                                        "Unable to complete the clinic supply delivery.",
                                        "I wasn't able to drop off the clinic supplies.",
                                        "Failed to hand in the requested medical items.",
                                        "Couldn't finalize the clinic supplies handover.",
                                        "Delivery of clinic goods couldn't be registered.",
                                        "Could not complete the turn-in for the clinic.",
                                        "Turn-in was unsuccessful. Try again.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko maipasa ang mga suplay ng klinika.",
                                        "May nagkaproblema sa pag-abot ng mga medikal na gamit.",
                                        "Bigo ang pagpasa. Tignan kung kumpleto ang bawat gamit.",
                                        "Hindi makumpleto ang paghahatid ng suplay sa klinika.",
                                        "Hindi ko naibigay ang mga suplay para sa klinika.",
                                        "Bigo sa pagpasa ng hinihiling na medikal na kagamitan.",
                                        "Hindi matapos ang paglilipat ng suplay sa klinika.",
                                        "Hindi naitala ang paghahatid ng gamit sa klinika.",
                                        "Hindi makumpleto ang pagpasa para sa klinika.",
                                        "Hindi nagtagumpay ang pagpasa. Subukan ulit.",
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
            ["responsePlanID"] = "quest.clinic_supplies.turn_in.failed",
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
                            ["fallback"] = "I couldn't turn in the clinic supplies.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.quest.clinic_supplies.turn_in.failed.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/quest_content/quest_clinic_supplies_turn_in_failed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I couldn't turn in the clinic supplies.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.quest.clinic_supplies.turn_in.failed.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I couldn't turn in the clinic supplies.",
                        "Something went wrong handing over the medical gear.",
                        "Turn-in failed. Check if we have every item.",
                        "Unable to complete the clinic supply delivery.",
                        "I wasn't able to drop off the clinic supplies.",
                        "Failed to hand in the requested medical items.",
                        "Couldn't finalize the clinic supplies handover.",
                        "Delivery of clinic goods couldn't be registered.",
                        "Could not complete the turn-in for the clinic.",
                        "Turn-in was unsuccessful. Try again.",
                    },
                    ["TL"] = {
                        "Hindi ko maipasa ang mga suplay ng klinika.",
                        "May nagkaproblema sa pag-abot ng mga medikal na gamit.",
                        "Bigo ang pagpasa. Tignan kung kumpleto ang bawat gamit.",
                        "Hindi makumpleto ang paghahatid ng suplay sa klinika.",
                        "Hindi ko naibigay ang mga suplay para sa klinika.",
                        "Bigo sa pagpasa ng hinihiling na medikal na kagamitan.",
                        "Hindi matapos ang paglilipat ng suplay sa klinika.",
                        "Hindi naitala ang paghahatid ng gamit sa klinika.",
                        "Hindi makumpleto ang pagpasa para sa klinika.",
                        "Hindi nagtagumpay ang pagpasa. Subukan ulit.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "quest_content",
        ["exchangeFamily"] = {
            ["familyID"] = "quest.clinic_supplies.turn_in.queued",
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
                                ["fallback"] = "I'll turn in the clinic supplies.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.quest.clinic_supplies.turn_in.queued.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'll turn in the clinic supplies.",
                                        "I'm heading over to drop off the medical items.",
                                        "I'll deliver the clinic supplies right away.",
                                        "Queued to hand over the medical gear.",
                                        "I will submit the clinic supplies now.",
                                        "Taking these supplies over to the clinic station.",
                                        "I'll deposit the medical items as requested.",
                                        "Handing in the clinic goods now.",
                                        "I'll complete the delivery of the clinic supplies.",
                                        "Off to turn in our gathered clinic supplies.",
                                    },
                                    ["TL"] = {
                                        "Ipapasa ko ang mga suplay ng klinika.",
                                        "Pupunta na ako para iabot ang mga medikal na gamit.",
                                        "Ihahatid ko agad ang mga suplay ng klinika.",
                                        "Nakatakdang iabot ang mga medikal na gamit.",
                                        "Ipapasa ko na ang mga suplay sa klinika ngayon.",
                                        "Dadalhin ko na ang mga suplay na 'to sa klinika.",
                                        "Ilalagak ko ang mga medikal na gamit tulad ng hiniling.",
                                        "Iniaabot ko na ang mga gamit sa klinika ngayon.",
                                        "Tatapusin ko ang paghahatid ng suplay sa klinika.",
                                        "Aalis na para ipasa ang naipon nating suplay sa klinika.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "quest.clinic_supplies.turn_in",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'll turn in the clinic supplies.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.quest.clinic_supplies.turn_in.queued.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I'll turn in the clinic supplies.",
                            "I'm heading over to drop off the medical items.",
                            "I'll deliver the clinic supplies right away.",
                            "Queued to hand over the medical gear.",
                            "I will submit the clinic supplies now.",
                            "Taking these supplies over to the clinic station.",
                            "I'll deposit the medical items as requested.",
                            "Handing in the clinic goods now.",
                            "I'll complete the delivery of the clinic supplies.",
                            "Off to turn in our gathered clinic supplies.",
                        },
                        ["TL"] = {
                            "Ipapasa ko ang mga suplay ng klinika.",
                            "Pupunta na ako para iabot ang mga medikal na gamit.",
                            "Ihahatid ko agad ang mga suplay ng klinika.",
                            "Nakatakdang iabot ang mga medikal na gamit.",
                            "Ipapasa ko na ang mga suplay sa klinika ngayon.",
                            "Dadalhin ko na ang mga suplay na 'to sa klinika.",
                            "Ilalagak ko ang mga medikal na gamit tulad ng hiniling.",
                            "Iniaabot ko na ang mga gamit sa klinika ngayon.",
                            "Tatapusin ko ang paghahatid ng suplay sa klinika.",
                            "Aalis na para ipasa ang naipon nating suplay sa klinika.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "quest.clinic_supplies.turn_in.queued",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "queued",
            ["sourceId"] = "quest.clinic_supplies.turn_in.queued",
            ["sourcePath"] = "adopters/hoomans/dialogue/quest_content/quest_clinic_supplies_turn_in_queued.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/QuestContent",
        ["namespace"] = "quest.clinic_supplies.turn_in",
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
                ["category"] = "projecthoomans:quest_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.quest",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/quest.json",
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
                                        "I'll turn in the clinic supplies.",
                                        "I'm heading over to drop off the medical items.",
                                        "I'll deliver the clinic supplies right away.",
                                        "Queued to hand over the medical gear.",
                                        "I will submit the clinic supplies now.",
                                        "Taking these supplies over to the clinic station.",
                                        "I'll deposit the medical items as requested.",
                                        "Handing in the clinic goods now.",
                                        "I'll complete the delivery of the clinic supplies.",
                                        "Off to turn in our gathered clinic supplies.",
                                    },
                                    ["TL"] = {
                                        "Ipapasa ko ang mga suplay ng klinika.",
                                        "Pupunta na ako para iabot ang mga medikal na gamit.",
                                        "Ihahatid ko agad ang mga suplay ng klinika.",
                                        "Nakatakdang iabot ang mga medikal na gamit.",
                                        "Ipapasa ko na ang mga suplay sa klinika ngayon.",
                                        "Dadalhin ko na ang mga suplay na 'to sa klinika.",
                                        "Ilalagak ko ang mga medikal na gamit tulad ng hiniling.",
                                        "Iniaabot ko na ang mga gamit sa klinika ngayon.",
                                        "Tatapusin ko ang paghahatid ng suplay sa klinika.",
                                        "Aalis na para ipasa ang naipon nating suplay sa klinika.",
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
            ["responsePlanID"] = "quest.clinic_supplies.turn_in.queued",
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
                            ["fallback"] = "I'll turn in the clinic supplies.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.quest.clinic_supplies.turn_in.queued.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/quest_content/quest_clinic_supplies_turn_in_queued.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'll turn in the clinic supplies.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.quest.clinic_supplies.turn_in.queued.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I'll turn in the clinic supplies.",
                        "I'm heading over to drop off the medical items.",
                        "I'll deliver the clinic supplies right away.",
                        "Queued to hand over the medical gear.",
                        "I will submit the clinic supplies now.",
                        "Taking these supplies over to the clinic station.",
                        "I'll deposit the medical items as requested.",
                        "Handing in the clinic goods now.",
                        "I'll complete the delivery of the clinic supplies.",
                        "Off to turn in our gathered clinic supplies.",
                    },
                    ["TL"] = {
                        "Ipapasa ko ang mga suplay ng klinika.",
                        "Pupunta na ako para iabot ang mga medikal na gamit.",
                        "Ihahatid ko agad ang mga suplay ng klinika.",
                        "Nakatakdang iabot ang mga medikal na gamit.",
                        "Ipapasa ko na ang mga suplay sa klinika ngayon.",
                        "Dadalhin ko na ang mga suplay na 'to sa klinika.",
                        "Ilalagak ko ang mga medikal na gamit tulad ng hiniling.",
                        "Iniaabot ko na ang mga gamit sa klinika ngayon.",
                        "Tatapusin ko ang paghahatid ng suplay sa klinika.",
                        "Aalis na para ipasa ang naipon nating suplay sa klinika.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "quest_content",
        ["exchangeFamily"] = {
            ["familyID"] = "quest.clinic_supplies.turn_in.rejected",
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
                                ["fallback"] = "I can't turn that in yet.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.quest.clinic_supplies.turn_in.rejected.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I can't turn that in yet.",
                                        "We don't have everything needed for the clinic yet.",
                                        "Supplies aren't complete. Can't hand them over.",
                                        "I have to decline turning this in right now.",
                                        "Not ready for turn-in. Missing items.",
                                        "Can't drop these off yet. Double-check our pack.",
                                        "I won't turn in an incomplete medical bundle.",
                                        "Hold on, we can't submit these clinic supplies yet.",
                                        "Delivery cannot be accepted until all items are present.",
                                        "Can't finalize the clinic hand-in at this stage.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko pa maipapasa iyon.",
                                        "Wala pa sa atin ang lahat ng kailangan para sa klinika.",
                                        "Kulang pa ang mga suplay. Hindi pa pwedeng iabot.",
                                        "Kailangan kong tanggihan ang pagpasa nito ngayon.",
                                        "Hindi pa handa sa pagpasa. May kulang na gamit.",
                                        "Hindi pa maibibigay 'to. Tignan ulit ang bag natin.",
                                        "Hindi ako magpapasa ng kulang na medikal na gamit.",
                                        "Sandali, hindi pa natin maipapasa ang mga suplay sa klinika.",
                                        "Hindi matatanggap ang hatid hangga't kulang ang mga gamit.",
                                        "Hindi matatapos ang pagpasa sa klinika sa yugtong ito.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "quest.clinic_supplies.turn_in",
            ["textRoles"] = {
                {
                    ["fallback"] = "I can't turn that in yet.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.quest.clinic_supplies.turn_in.rejected.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I can't turn that in yet.",
                            "We don't have everything needed for the clinic yet.",
                            "Supplies aren't complete. Can't hand them over.",
                            "I have to decline turning this in right now.",
                            "Not ready for turn-in. Missing items.",
                            "Can't drop these off yet. Double-check our pack.",
                            "I won't turn in an incomplete medical bundle.",
                            "Hold on, we can't submit these clinic supplies yet.",
                            "Delivery cannot be accepted until all items are present.",
                            "Can't finalize the clinic hand-in at this stage.",
                        },
                        ["TL"] = {
                            "Hindi ko pa maipapasa iyon.",
                            "Wala pa sa atin ang lahat ng kailangan para sa klinika.",
                            "Kulang pa ang mga suplay. Hindi pa pwedeng iabot.",
                            "Kailangan kong tanggihan ang pagpasa nito ngayon.",
                            "Hindi pa handa sa pagpasa. May kulang na gamit.",
                            "Hindi pa maibibigay 'to. Tignan ulit ang bag natin.",
                            "Hindi ako magpapasa ng kulang na medikal na gamit.",
                            "Sandali, hindi pa natin maipapasa ang mga suplay sa klinika.",
                            "Hindi matatanggap ang hatid hangga't kulang ang mga gamit.",
                            "Hindi matatapos ang pagpasa sa klinika sa yugtong ito.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "quest.clinic_supplies.turn_in.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "rejected",
            ["sourceId"] = "quest.clinic_supplies.turn_in.rejected",
            ["sourcePath"] = "adopters/hoomans/dialogue/quest_content/quest_clinic_supplies_turn_in_rejected.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/QuestContent",
        ["namespace"] = "quest.clinic_supplies.turn_in",
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
                ["category"] = "projecthoomans:quest_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.quest",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/quest.json",
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
                                        "I can't turn that in yet.",
                                        "We don't have everything needed for the clinic yet.",
                                        "Supplies aren't complete. Can't hand them over.",
                                        "I have to decline turning this in right now.",
                                        "Not ready for turn-in. Missing items.",
                                        "Can't drop these off yet. Double-check our pack.",
                                        "I won't turn in an incomplete medical bundle.",
                                        "Hold on, we can't submit these clinic supplies yet.",
                                        "Delivery cannot be accepted until all items are present.",
                                        "Can't finalize the clinic hand-in at this stage.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko pa maipapasa iyon.",
                                        "Wala pa sa atin ang lahat ng kailangan para sa klinika.",
                                        "Kulang pa ang mga suplay. Hindi pa pwedeng iabot.",
                                        "Kailangan kong tanggihan ang pagpasa nito ngayon.",
                                        "Hindi pa handa sa pagpasa. May kulang na gamit.",
                                        "Hindi pa maibibigay 'to. Tignan ulit ang bag natin.",
                                        "Hindi ako magpapasa ng kulang na medikal na gamit.",
                                        "Sandali, hindi pa natin maipapasa ang mga suplay sa klinika.",
                                        "Hindi matatanggap ang hatid hangga't kulang ang mga gamit.",
                                        "Hindi matatapos ang pagpasa sa klinika sa yugtong ito.",
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
            ["responsePlanID"] = "quest.clinic_supplies.turn_in.rejected",
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
                            ["fallback"] = "I can't turn that in yet.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.quest.clinic_supplies.turn_in.rejected.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/quest_content/quest_clinic_supplies_turn_in_rejected.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I can't turn that in yet.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.quest.clinic_supplies.turn_in.rejected.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I can't turn that in yet.",
                        "We don't have everything needed for the clinic yet.",
                        "Supplies aren't complete. Can't hand them over.",
                        "I have to decline turning this in right now.",
                        "Not ready for turn-in. Missing items.",
                        "Can't drop these off yet. Double-check our pack.",
                        "I won't turn in an incomplete medical bundle.",
                        "Hold on, we can't submit these clinic supplies yet.",
                        "Delivery cannot be accepted until all items are present.",
                        "Can't finalize the clinic hand-in at this stage.",
                    },
                    ["TL"] = {
                        "Hindi ko pa maipapasa iyon.",
                        "Wala pa sa atin ang lahat ng kailangan para sa klinika.",
                        "Kulang pa ang mga suplay. Hindi pa pwedeng iabot.",
                        "Kailangan kong tanggihan ang pagpasa nito ngayon.",
                        "Hindi pa handa sa pagpasa. May kulang na gamit.",
                        "Hindi pa maibibigay 'to. Tignan ulit ang bag natin.",
                        "Hindi ako magpapasa ng kulang na medikal na gamit.",
                        "Sandali, hindi pa natin maipapasa ang mga suplay sa klinika.",
                        "Hindi matatanggap ang hatid hangga't kulang ang mga gamit.",
                        "Hindi matatapos ang pagpasa sa klinika sa yugtong ito.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
