-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "gift.completed",
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
                                ["fallback"] = "Thank you for the gift.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.gift.completed.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Thank you for the gift.",
                                        "I appreciate this gesture. Thank you.",
                                        "That's generous of you. Thanks.",
                                        "Thank you! This will be put to good use.",
                                        "A welcome surprise. Thank you, friend.",
                                        "Much obliged for the gift.",
                                        "I'm grateful for this. Thank you.",
                                        "You didn't have to, but thanks a lot.",
                                        "Received with gratitude. Thank you.",
                                        "Thanks for thinking of me with this gift.",
                                    },
                                    ["TL"] = {
                                        "Salamat sa regalo.",
                                        "Salamat sa magandang kalooban. Maraming salamat.",
                                        "Bukas-palad ka. Salamat.",
                                        "Salamat! Magagamit ito nang maayos.",
                                        "Magandang sorpresa. Salamat, kaibigan.",
                                        "Maraming salamat sa regalo.",
                                        "Nagpapasalamat ako rito. Salamat.",
                                        "Di mo kailangang gawin, pero maraming salamat.",
                                        "Tinatanggap kalakip ang pasasalamat. Salamat.",
                                        "Salamat sa pag-alala sa akin sa regalong ito.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "gift",
            ["textRoles"] = {
                {
                    ["fallback"] = "Thank you for the gift.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.gift.completed.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Thank you for the gift.",
                            "I appreciate this gesture. Thank you.",
                            "That's generous of you. Thanks.",
                            "Thank you! This will be put to good use.",
                            "A welcome surprise. Thank you, friend.",
                            "Much obliged for the gift.",
                            "I'm grateful for this. Thank you.",
                            "You didn't have to, but thanks a lot.",
                            "Received with gratitude. Thank you.",
                            "Thanks for thinking of me with this gift.",
                        },
                        ["TL"] = {
                            "Salamat sa regalo.",
                            "Salamat sa magandang kalooban. Maraming salamat.",
                            "Bukas-palad ka. Salamat.",
                            "Salamat! Magagamit ito nang maayos.",
                            "Magandang sorpresa. Salamat, kaibigan.",
                            "Maraming salamat sa regalo.",
                            "Nagpapasalamat ako rito. Salamat.",
                            "Di mo kailangang gawin, pero maraming salamat.",
                            "Tinatanggap kalakip ang pasasalamat. Salamat.",
                            "Salamat sa pag-alala sa akin sa regalong ito.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "gift.completed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "completed",
            ["sourceId"] = "gift.completed",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/gift_completed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
        ["namespace"] = "gift",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/gift.json",
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
                                        "Thank you for the gift.",
                                        "I appreciate this gesture. Thank you.",
                                        "That's generous of you. Thanks.",
                                        "Thank you! This will be put to good use.",
                                        "A welcome surprise. Thank you, friend.",
                                        "Much obliged for the gift.",
                                        "I'm grateful for this. Thank you.",
                                        "You didn't have to, but thanks a lot.",
                                        "Received with gratitude. Thank you.",
                                        "Thanks for thinking of me with this gift.",
                                    },
                                    ["TL"] = {
                                        "Salamat sa regalo.",
                                        "Salamat sa magandang kalooban. Maraming salamat.",
                                        "Bukas-palad ka. Salamat.",
                                        "Salamat! Magagamit ito nang maayos.",
                                        "Magandang sorpresa. Salamat, kaibigan.",
                                        "Maraming salamat sa regalo.",
                                        "Nagpapasalamat ako rito. Salamat.",
                                        "Di mo kailangang gawin, pero maraming salamat.",
                                        "Tinatanggap kalakip ang pasasalamat. Salamat.",
                                        "Salamat sa pag-alala sa akin sa regalong ito.",
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
            ["responsePlanID"] = "gift.completed",
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
                            ["fallback"] = "Thank you for the gift.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.gift.completed.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/gift_completed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Thank you for the gift.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.gift.completed.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Thank you for the gift.",
                        "I appreciate this gesture. Thank you.",
                        "That's generous of you. Thanks.",
                        "Thank you! This will be put to good use.",
                        "A welcome surprise. Thank you, friend.",
                        "Much obliged for the gift.",
                        "I'm grateful for this. Thank you.",
                        "You didn't have to, but thanks a lot.",
                        "Received with gratitude. Thank you.",
                        "Thanks for thinking of me with this gift.",
                    },
                    ["TL"] = {
                        "Salamat sa regalo.",
                        "Salamat sa magandang kalooban. Maraming salamat.",
                        "Bukas-palad ka. Salamat.",
                        "Salamat! Magagamit ito nang maayos.",
                        "Magandang sorpresa. Salamat, kaibigan.",
                        "Maraming salamat sa regalo.",
                        "Nagpapasalamat ako rito. Salamat.",
                        "Di mo kailangang gawin, pero maraming salamat.",
                        "Tinatanggap kalakip ang pasasalamat. Salamat.",
                        "Salamat sa pag-alala sa akin sa regalong ito.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "gift.failed",
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
                                ["fallback"] = "I couldn't accept that gift.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.gift.failed.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I couldn't accept that gift.",
                                        "Something went wrong while transferring the gift.",
                                        "Gift transfer failed. My hands were full.",
                                        "Couldn't receive that right now.",
                                        "Unable to take the gift into my inventory.",
                                        "Transaction interrupted. Gift not taken.",
                                        "Failed to receive the offering.",
                                        "I dropped it or couldn't hold it.",
                                        "Gift transfer could not be completed.",
                                        "Couldn't take that from you.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko matanggap ang regalong iyan.",
                                        "May nangyaring mali habang ipinapasa ang regalo.",
                                        "Bigo ang paglipat ng regalo. Puno ang kamay ko.",
                                        "Di matanggap 'yan sa ngayon.",
                                        "Di mailagay ang regalo sa lalagyan ko.",
                                        "Naabala ang pagbibigay. Di nakuha ang regalo.",
                                        "Bigo sa pagtanggap ng alay.",
                                        "Nahulog ko o di nahawakan.",
                                        "Di natapos ang paglipat ng regalo.",
                                        "Di ko nakuha 'yan mula sa 'yo.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "gift",
            ["textRoles"] = {
                {
                    ["fallback"] = "I couldn't accept that gift.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.gift.failed.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I couldn't accept that gift.",
                            "Something went wrong while transferring the gift.",
                            "Gift transfer failed. My hands were full.",
                            "Couldn't receive that right now.",
                            "Unable to take the gift into my inventory.",
                            "Transaction interrupted. Gift not taken.",
                            "Failed to receive the offering.",
                            "I dropped it or couldn't hold it.",
                            "Gift transfer could not be completed.",
                            "Couldn't take that from you.",
                        },
                        ["TL"] = {
                            "Hindi ko matanggap ang regalong iyan.",
                            "May nangyaring mali habang ipinapasa ang regalo.",
                            "Bigo ang paglipat ng regalo. Puno ang kamay ko.",
                            "Di matanggap 'yan sa ngayon.",
                            "Di mailagay ang regalo sa lalagyan ko.",
                            "Naabala ang pagbibigay. Di nakuha ang regalo.",
                            "Bigo sa pagtanggap ng alay.",
                            "Nahulog ko o di nahawakan.",
                            "Di natapos ang paglipat ng regalo.",
                            "Di ko nakuha 'yan mula sa 'yo.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "gift.failed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "failed",
            ["sourceId"] = "gift.failed",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/gift_failed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
        ["namespace"] = "gift",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/gift.json",
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
                                        "I couldn't accept that gift.",
                                        "Something went wrong while transferring the gift.",
                                        "Gift transfer failed. My hands were full.",
                                        "Couldn't receive that right now.",
                                        "Unable to take the gift into my inventory.",
                                        "Transaction interrupted. Gift not taken.",
                                        "Failed to receive the offering.",
                                        "I dropped it or couldn't hold it.",
                                        "Gift transfer could not be completed.",
                                        "Couldn't take that from you.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko matanggap ang regalong iyan.",
                                        "May nangyaring mali habang ipinapasa ang regalo.",
                                        "Bigo ang paglipat ng regalo. Puno ang kamay ko.",
                                        "Di matanggap 'yan sa ngayon.",
                                        "Di mailagay ang regalo sa lalagyan ko.",
                                        "Naabala ang pagbibigay. Di nakuha ang regalo.",
                                        "Bigo sa pagtanggap ng alay.",
                                        "Nahulog ko o di nahawakan.",
                                        "Di natapos ang paglipat ng regalo.",
                                        "Di ko nakuha 'yan mula sa 'yo.",
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
            ["responsePlanID"] = "gift.failed",
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
                            ["fallback"] = "I couldn't accept that gift.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.gift.failed.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/gift_failed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I couldn't accept that gift.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.gift.failed.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I couldn't accept that gift.",
                        "Something went wrong while transferring the gift.",
                        "Gift transfer failed. My hands were full.",
                        "Couldn't receive that right now.",
                        "Unable to take the gift into my inventory.",
                        "Transaction interrupted. Gift not taken.",
                        "Failed to receive the offering.",
                        "I dropped it or couldn't hold it.",
                        "Gift transfer could not be completed.",
                        "Couldn't take that from you.",
                    },
                    ["TL"] = {
                        "Hindi ko matanggap ang regalong iyan.",
                        "May nangyaring mali habang ipinapasa ang regalo.",
                        "Bigo ang paglipat ng regalo. Puno ang kamay ko.",
                        "Di matanggap 'yan sa ngayon.",
                        "Di mailagay ang regalo sa lalagyan ko.",
                        "Naabala ang pagbibigay. Di nakuha ang regalo.",
                        "Bigo sa pagtanggap ng alay.",
                        "Nahulog ko o di nahawakan.",
                        "Di natapos ang paglipat ng regalo.",
                        "Di ko nakuha 'yan mula sa 'yo.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "gift.pending",
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
                                ["fallback"] = "I'll take a look at that gift.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.gift.pending.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'll take a look at that gift.",
                                        "Let's see what you brought.",
                                        "Considering the gift now.",
                                        "Inspecting what you have for me.",
                                        "Hold on, looking at the offering.",
                                        "I'll review the item you offered.",
                                        "Checking out the gift.",
                                        "Let me examine what this is.",
                                        "Looking over your gift.",
                                        "Give me a second to check this item.",
                                    },
                                    ["TL"] = {
                                        "Titingnan ko ang regalong iyan.",
                                        "Tingnan natin kung ano ang dala mo.",
                                        "Tinitingnan ang regalo ngayon.",
                                        "Sinusuri ang handog mo para sa akin.",
                                        "Teka, tinitingnan ang iniaalok.",
                                        "Susuriin ko ang bagay na inialok mo.",
                                        "Tinitingnan ang regalo.",
                                        "Hayaan mong tingnan ko kung ano ito.",
                                        "Sinusuri ang regalo mo.",
                                        "Bigyan mo ako ng sandali para tingnan ang gamit na ito.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "gift",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'll take a look at that gift.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.gift.pending.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I'll take a look at that gift.",
                            "Let's see what you brought.",
                            "Considering the gift now.",
                            "Inspecting what you have for me.",
                            "Hold on, looking at the offering.",
                            "I'll review the item you offered.",
                            "Checking out the gift.",
                            "Let me examine what this is.",
                            "Looking over your gift.",
                            "Give me a second to check this item.",
                        },
                        ["TL"] = {
                            "Titingnan ko ang regalong iyan.",
                            "Tingnan natin kung ano ang dala mo.",
                            "Tinitingnan ang regalo ngayon.",
                            "Sinusuri ang handog mo para sa akin.",
                            "Teka, tinitingnan ang iniaalok.",
                            "Susuriin ko ang bagay na inialok mo.",
                            "Tinitingnan ang regalo.",
                            "Hayaan mong tingnan ko kung ano ito.",
                            "Sinusuri ang regalo mo.",
                            "Bigyan mo ako ng sandali para tingnan ang gamit na ito.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "gift.pending",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "pending",
            ["sourceId"] = "gift.pending",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/gift_pending.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
        ["namespace"] = "gift",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/gift.json",
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
                                        "I'll take a look at that gift.",
                                        "Let's see what you brought.",
                                        "Considering the gift now.",
                                        "Inspecting what you have for me.",
                                        "Hold on, looking at the offering.",
                                        "I'll review the item you offered.",
                                        "Checking out the gift.",
                                        "Let me examine what this is.",
                                        "Looking over your gift.",
                                        "Give me a second to check this item.",
                                    },
                                    ["TL"] = {
                                        "Titingnan ko ang regalong iyan.",
                                        "Tingnan natin kung ano ang dala mo.",
                                        "Tinitingnan ang regalo ngayon.",
                                        "Sinusuri ang handog mo para sa akin.",
                                        "Teka, tinitingnan ang iniaalok.",
                                        "Susuriin ko ang bagay na inialok mo.",
                                        "Tinitingnan ang regalo.",
                                        "Hayaan mong tingnan ko kung ano ito.",
                                        "Sinusuri ang regalo mo.",
                                        "Bigyan mo ako ng sandali para tingnan ang gamit na ito.",
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
            ["responsePlanID"] = "gift.pending",
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
                            ["fallback"] = "I'll take a look at that gift.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.gift.pending.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/gift_pending.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'll take a look at that gift.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.gift.pending.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I'll take a look at that gift.",
                        "Let's see what you brought.",
                        "Considering the gift now.",
                        "Inspecting what you have for me.",
                        "Hold on, looking at the offering.",
                        "I'll review the item you offered.",
                        "Checking out the gift.",
                        "Let me examine what this is.",
                        "Looking over your gift.",
                        "Give me a second to check this item.",
                    },
                    ["TL"] = {
                        "Titingnan ko ang regalong iyan.",
                        "Tingnan natin kung ano ang dala mo.",
                        "Tinitingnan ang regalo ngayon.",
                        "Sinusuri ang handog mo para sa akin.",
                        "Teka, tinitingnan ang iniaalok.",
                        "Susuriin ko ang bagay na inialok mo.",
                        "Tinitingnan ang regalo.",
                        "Hayaan mong tingnan ko kung ano ito.",
                        "Sinusuri ang regalo mo.",
                        "Bigyan mo ako ng sandali para tingnan ang gamit na ito.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "gift.rejected",
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
                                ["fallback"] = "I can't accept that gift right now.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.gift.rejected.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I can't accept that gift right now.",
                                        "Keep it. You need it more than I do.",
                                        "I have no room for gifts in my pack.",
                                        "I don't feel comfortable taking this from you.",
                                        "Refusing this gift. We're not there yet.",
                                        "Save your supplies. Don't waste them on me.",
                                        "I cannot take that offering.",
                                        "No thanks. I carry my own weight.",
                                        "Gift rejected. Keep your belongings.",
                                        "I won't accept that from you today.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko matanggap ang regalong iyan ngayon.",
                                        "Itabi mo. Mas kailangan mo 'yan kaysa sa akin.",
                                        "Wala nang espasyo sa bag ko para sa mga regalo.",
                                        "Hindi magaan sa loob ko na tanggapin ito sa 'yo.",
                                        "Tinatanggihan ang regalo. Di pa tayo ganoon kalapit.",
                                        "Itabi ang gamit mo. Huwag mong sayangin sa akin.",
                                        "Di ko matatanggap ang alay na 'yan.",
                                        "Hindi salamat. Kaya kong dalhin ang sarili ko.",
                                        "Tinatanggihan ang regalo. Itago ang pag-aari mo.",
                                        "Di ko tatanggapin 'yan mula sa 'yo ngayong araw.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "gift",
            ["textRoles"] = {
                {
                    ["fallback"] = "I can't accept that gift right now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.gift.rejected.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I can't accept that gift right now.",
                            "Keep it. You need it more than I do.",
                            "I have no room for gifts in my pack.",
                            "I don't feel comfortable taking this from you.",
                            "Refusing this gift. We're not there yet.",
                            "Save your supplies. Don't waste them on me.",
                            "I cannot take that offering.",
                            "No thanks. I carry my own weight.",
                            "Gift rejected. Keep your belongings.",
                            "I won't accept that from you today.",
                        },
                        ["TL"] = {
                            "Hindi ko matanggap ang regalong iyan ngayon.",
                            "Itabi mo. Mas kailangan mo 'yan kaysa sa akin.",
                            "Wala nang espasyo sa bag ko para sa mga regalo.",
                            "Hindi magaan sa loob ko na tanggapin ito sa 'yo.",
                            "Tinatanggihan ang regalo. Di pa tayo ganoon kalapit.",
                            "Itabi ang gamit mo. Huwag mong sayangin sa akin.",
                            "Di ko matatanggap ang alay na 'yan.",
                            "Hindi salamat. Kaya kong dalhin ang sarili ko.",
                            "Tinatanggihan ang regalo. Itago ang pag-aari mo.",
                            "Di ko tatanggapin 'yan mula sa 'yo ngayong araw.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "gift.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "rejected",
            ["sourceId"] = "gift.rejected",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/gift_rejected.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
        ["namespace"] = "gift",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/gift.json",
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
                                        "I can't accept that gift right now.",
                                        "Keep it. You need it more than I do.",
                                        "I have no room for gifts in my pack.",
                                        "I don't feel comfortable taking this from you.",
                                        "Refusing this gift. We're not there yet.",
                                        "Save your supplies. Don't waste them on me.",
                                        "I cannot take that offering.",
                                        "No thanks. I carry my own weight.",
                                        "Gift rejected. Keep your belongings.",
                                        "I won't accept that from you today.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko matanggap ang regalong iyan ngayon.",
                                        "Itabi mo. Mas kailangan mo 'yan kaysa sa akin.",
                                        "Wala nang espasyo sa bag ko para sa mga regalo.",
                                        "Hindi magaan sa loob ko na tanggapin ito sa 'yo.",
                                        "Tinatanggihan ang regalo. Di pa tayo ganoon kalapit.",
                                        "Itabi ang gamit mo. Huwag mong sayangin sa akin.",
                                        "Di ko matatanggap ang alay na 'yan.",
                                        "Hindi salamat. Kaya kong dalhin ang sarili ko.",
                                        "Tinatanggihan ang regalo. Itago ang pag-aari mo.",
                                        "Di ko tatanggapin 'yan mula sa 'yo ngayong araw.",
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
            ["responsePlanID"] = "gift.rejected",
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
                            ["fallback"] = "I can't accept that gift right now.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.gift.rejected.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/gift_rejected.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I can't accept that gift right now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.gift.rejected.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I can't accept that gift right now.",
                        "Keep it. You need it more than I do.",
                        "I have no room for gifts in my pack.",
                        "I don't feel comfortable taking this from you.",
                        "Refusing this gift. We're not there yet.",
                        "Save your supplies. Don't waste them on me.",
                        "I cannot take that offering.",
                        "No thanks. I carry my own weight.",
                        "Gift rejected. Keep your belongings.",
                        "I won't accept that from you today.",
                    },
                    ["TL"] = {
                        "Hindi ko matanggap ang regalong iyan ngayon.",
                        "Itabi mo. Mas kailangan mo 'yan kaysa sa akin.",
                        "Wala nang espasyo sa bag ko para sa mga regalo.",
                        "Hindi magaan sa loob ko na tanggapin ito sa 'yo.",
                        "Tinatanggihan ang regalo. Di pa tayo ganoon kalapit.",
                        "Itabi ang gamit mo. Huwag mong sayangin sa akin.",
                        "Di ko matatanggap ang alay na 'yan.",
                        "Hindi salamat. Kaya kong dalhin ang sarili ko.",
                        "Tinatanggihan ang regalo. Itago ang pag-aari mo.",
                        "Di ko tatanggapin 'yan mula sa 'yo ngayong araw.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "gift.selection_required",
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
                                ["fallback"] = "I need to see what you brought me first.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.gift.selection_required.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I need to see what you brought me first.",
                                        "What exactly are you offering me?",
                                        "Select an item to gift before I decide.",
                                        "Show me what you want to give.",
                                        "Which item are you trying to hand over?",
                                        "Pick the specific item first.",
                                        "I can't take anything until you select it.",
                                        "Show me what's in your hands.",
                                        "What gift are we talking about? Choose one.",
                                        "Specify the gift from your inventory.",
                                    },
                                    ["TL"] = {
                                        "Kailangan ko munang makita ang dala mo.",
                                        "Ano nga ba ang iniaalok mo sa akin?",
                                        "Pumili ng bagay na ireregalo bago ako magpasya.",
                                        "Ipakita mo kung ano ang nais mong ibigay.",
                                        "Aling gamit ba ang sinusubukan mong iabot?",
                                        "Piliin muna ang partikular na gamit.",
                                        "Wala akong matatanggap hangga't di mo pinipili.",
                                        "Ipakita mo ang nasa mga kamay mo.",
                                        "Anong regalo ba ang pinag-uusapan natin? Pumili ka.",
                                        "Tukuyin ang regalo mula sa bag mo.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "gift",
            ["textRoles"] = {
                {
                    ["fallback"] = "I need to see what you brought me first.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.gift.selection_required.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I need to see what you brought me first.",
                            "What exactly are you offering me?",
                            "Select an item to gift before I decide.",
                            "Show me what you want to give.",
                            "Which item are you trying to hand over?",
                            "Pick the specific item first.",
                            "I can't take anything until you select it.",
                            "Show me what's in your hands.",
                            "What gift are we talking about? Choose one.",
                            "Specify the gift from your inventory.",
                        },
                        ["TL"] = {
                            "Kailangan ko munang makita ang dala mo.",
                            "Ano nga ba ang iniaalok mo sa akin?",
                            "Pumili ng bagay na ireregalo bago ako magpasya.",
                            "Ipakita mo kung ano ang nais mong ibigay.",
                            "Aling gamit ba ang sinusubukan mong iabot?",
                            "Piliin muna ang partikular na gamit.",
                            "Wala akong matatanggap hangga't di mo pinipili.",
                            "Ipakita mo ang nasa mga kamay mo.",
                            "Anong regalo ba ang pinag-uusapan natin? Pumili ka.",
                            "Tukuyin ang regalo mula sa bag mo.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "gift.selection_required",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "selection_required",
            ["sourceId"] = "gift.selection_required",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/gift_selection_required.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
        ["namespace"] = "gift",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/gift.json",
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
                                        "I need to see what you brought me first.",
                                        "What exactly are you offering me?",
                                        "Select an item to gift before I decide.",
                                        "Show me what you want to give.",
                                        "Which item are you trying to hand over?",
                                        "Pick the specific item first.",
                                        "I can't take anything until you select it.",
                                        "Show me what's in your hands.",
                                        "What gift are we talking about? Choose one.",
                                        "Specify the gift from your inventory.",
                                    },
                                    ["TL"] = {
                                        "Kailangan ko munang makita ang dala mo.",
                                        "Ano nga ba ang iniaalok mo sa akin?",
                                        "Pumili ng bagay na ireregalo bago ako magpasya.",
                                        "Ipakita mo kung ano ang nais mong ibigay.",
                                        "Aling gamit ba ang sinusubukan mong iabot?",
                                        "Piliin muna ang partikular na gamit.",
                                        "Wala akong matatanggap hangga't di mo pinipili.",
                                        "Ipakita mo ang nasa mga kamay mo.",
                                        "Anong regalo ba ang pinag-uusapan natin? Pumili ka.",
                                        "Tukuyin ang regalo mula sa bag mo.",
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
            ["responsePlanID"] = "gift.selection_required",
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
                            ["fallback"] = "I need to see what you brought me first.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.gift.selection_required.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/gift_selection_required.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I need to see what you brought me first.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.gift.selection_required.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I need to see what you brought me first.",
                        "What exactly are you offering me?",
                        "Select an item to gift before I decide.",
                        "Show me what you want to give.",
                        "Which item are you trying to hand over?",
                        "Pick the specific item first.",
                        "I can't take anything until you select it.",
                        "Show me what's in your hands.",
                        "What gift are we talking about? Choose one.",
                        "Specify the gift from your inventory.",
                    },
                    ["TL"] = {
                        "Kailangan ko munang makita ang dala mo.",
                        "Ano nga ba ang iniaalok mo sa akin?",
                        "Pumili ng bagay na ireregalo bago ako magpasya.",
                        "Ipakita mo kung ano ang nais mong ibigay.",
                        "Aling gamit ba ang sinusubukan mong iabot?",
                        "Piliin muna ang partikular na gamit.",
                        "Wala akong matatanggap hangga't di mo pinipili.",
                        "Ipakita mo ang nasa mga kamay mo.",
                        "Anong regalo ba ang pinag-uusapan natin? Pumili ka.",
                        "Tukuyin ang regalo mula sa bag mo.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.consume.active",
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
                                ["fallback"] = "I'm using that now.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.task.consume.active.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'm using that now.",
                                        "Currently using the item.",
                                        "Applying it right now.",
                                        "In the middle of consuming that.",
                                        "Working through this item.",
                                        "Taking this now. Give me a second.",
                                        "Using the supplies as requested.",
                                        "Consuming it right now.",
                                        "Holding still to use this.",
                                        "Using it. Almost done.",
                                    },
                                    ["TL"] = {
                                        "Ginagamit ko na iyon ngayon.",
                                        "Kasalukuyang ginagamit ang gamit.",
                                        "Inilalapat na ngayon.",
                                        "Kasalukuyang ginagamit iyan.",
                                        "Ginagamit ang bagay na ito.",
                                        "Ginagamit ko na ito. Bigyan mo ako ng sandali.",
                                        "Ginagamit ang mga kagamitan ayon sa hiling.",
                                        "Ginagamit ko na ngayon.",
                                        "Nakahinto para gamitin ito.",
                                        "Ginagamit na. Halos tapos na.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "task.consume",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'm using that now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.task.consume.active.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I'm using that now.",
                            "Currently using the item.",
                            "Applying it right now.",
                            "In the middle of consuming that.",
                            "Working through this item.",
                            "Taking this now. Give me a second.",
                            "Using the supplies as requested.",
                            "Consuming it right now.",
                            "Holding still to use this.",
                            "Using it. Almost done.",
                        },
                        ["TL"] = {
                            "Ginagamit ko na iyon ngayon.",
                            "Kasalukuyang ginagamit ang gamit.",
                            "Inilalapat na ngayon.",
                            "Kasalukuyang ginagamit iyan.",
                            "Ginagamit ang bagay na ito.",
                            "Ginagamit ko na ito. Bigyan mo ako ng sandali.",
                            "Ginagamit ang mga kagamitan ayon sa hiling.",
                            "Ginagamit ko na ngayon.",
                            "Nakahinto para gamitin ito.",
                            "Ginagamit na. Halos tapos na.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "task.consume.active",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "active",
            ["sourceId"] = "task.consume.active",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_consume_active.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
        ["namespace"] = "task.consume",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/consume.json",
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
                                        "I'm using that now.",
                                        "Currently using the item.",
                                        "Applying it right now.",
                                        "In the middle of consuming that.",
                                        "Working through this item.",
                                        "Taking this now. Give me a second.",
                                        "Using the supplies as requested.",
                                        "Consuming it right now.",
                                        "Holding still to use this.",
                                        "Using it. Almost done.",
                                    },
                                    ["TL"] = {
                                        "Ginagamit ko na iyon ngayon.",
                                        "Kasalukuyang ginagamit ang gamit.",
                                        "Inilalapat na ngayon.",
                                        "Kasalukuyang ginagamit iyan.",
                                        "Ginagamit ang bagay na ito.",
                                        "Ginagamit ko na ito. Bigyan mo ako ng sandali.",
                                        "Ginagamit ang mga kagamitan ayon sa hiling.",
                                        "Ginagamit ko na ngayon.",
                                        "Nakahinto para gamitin ito.",
                                        "Ginagamit na. Halos tapos na.",
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
            ["responsePlanID"] = "task.consume.active",
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
                            ["fallback"] = "I'm using that now.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.task.consume.active.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_consume_active.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'm using that now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.task.consume.active.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I'm using that now.",
                        "Currently using the item.",
                        "Applying it right now.",
                        "In the middle of consuming that.",
                        "Working through this item.",
                        "Taking this now. Give me a second.",
                        "Using the supplies as requested.",
                        "Consuming it right now.",
                        "Holding still to use this.",
                        "Using it. Almost done.",
                    },
                    ["TL"] = {
                        "Ginagamit ko na iyon ngayon.",
                        "Kasalukuyang ginagamit ang gamit.",
                        "Inilalapat na ngayon.",
                        "Kasalukuyang ginagamit iyan.",
                        "Ginagamit ang bagay na ito.",
                        "Ginagamit ko na ito. Bigyan mo ako ng sandali.",
                        "Ginagamit ang mga kagamitan ayon sa hiling.",
                        "Ginagamit ko na ngayon.",
                        "Nakahinto para gamitin ito.",
                        "Ginagamit na. Halos tapos na.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.consume.admitted",
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
                                ["fallback"] = "I'll use that.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.task.consume.admitted.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'll use that.",
                                        "Understood. I will consume that item.",
                                        "All right, I'll take that.",
                                        "Good idea. I'll use it.",
                                        "Got it. Taking that now.",
                                        "I'll go ahead and apply that.",
                                        "Understood. That will help.",
                                        "Right. Using that item.",
                                        "I'll use what you specified.",
                                        "Sounds good. Consuming it.",
                                    },
                                    ["TL"] = {
                                        "Gagamitin ko iyon.",
                                        "Naintindihan. Gagamitin ko ang bagay na iyon.",
                                        "Sige, gagamitin ko iyon.",
                                        "Magandang ideya. Gagamitin ko.",
                                        "Nakuha ko. Gagamitin na ngayon.",
                                        "Sige, ilalapat ko iyan.",
                                        "Naiintindihan ko. Makatutulong iyan.",
                                        "Sige. Gagamitin ang gamit na 'yan.",
                                        "Gagamitin ko ang tinukoy mo.",
                                        "Maganda 'yan. Gagamitin na.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "task.consume",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'll use that.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.task.consume.admitted.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I'll use that.",
                            "Understood. I will consume that item.",
                            "All right, I'll take that.",
                            "Good idea. I'll use it.",
                            "Got it. Taking that now.",
                            "I'll go ahead and apply that.",
                            "Understood. That will help.",
                            "Right. Using that item.",
                            "I'll use what you specified.",
                            "Sounds good. Consuming it.",
                        },
                        ["TL"] = {
                            "Gagamitin ko iyon.",
                            "Naintindihan. Gagamitin ko ang bagay na iyon.",
                            "Sige, gagamitin ko iyon.",
                            "Magandang ideya. Gagamitin ko.",
                            "Nakuha ko. Gagamitin na ngayon.",
                            "Sige, ilalapat ko iyan.",
                            "Naiintindihan ko. Makatutulong iyan.",
                            "Sige. Gagamitin ang gamit na 'yan.",
                            "Gagamitin ko ang tinukoy mo.",
                            "Maganda 'yan. Gagamitin na.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "task.consume.admitted",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "admitted",
            ["sourceId"] = "task.consume.admitted",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_consume_admitted.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
        ["namespace"] = "task.consume",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/consume.json",
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
                                        "I'll use that.",
                                        "Understood. I will consume that item.",
                                        "All right, I'll take that.",
                                        "Good idea. I'll use it.",
                                        "Got it. Taking that now.",
                                        "I'll go ahead and apply that.",
                                        "Understood. That will help.",
                                        "Right. Using that item.",
                                        "I'll use what you specified.",
                                        "Sounds good. Consuming it.",
                                    },
                                    ["TL"] = {
                                        "Gagamitin ko iyon.",
                                        "Naintindihan. Gagamitin ko ang bagay na iyon.",
                                        "Sige, gagamitin ko iyon.",
                                        "Magandang ideya. Gagamitin ko.",
                                        "Nakuha ko. Gagamitin na ngayon.",
                                        "Sige, ilalapat ko iyan.",
                                        "Naiintindihan ko. Makatutulong iyan.",
                                        "Sige. Gagamitin ang gamit na 'yan.",
                                        "Gagamitin ko ang tinukoy mo.",
                                        "Maganda 'yan. Gagamitin na.",
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
            ["responsePlanID"] = "task.consume.admitted",
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
                            ["fallback"] = "I'll use that.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.task.consume.admitted.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_consume_admitted.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'll use that.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.task.consume.admitted.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I'll use that.",
                        "Understood. I will consume that item.",
                        "All right, I'll take that.",
                        "Good idea. I'll use it.",
                        "Got it. Taking that now.",
                        "I'll go ahead and apply that.",
                        "Understood. That will help.",
                        "Right. Using that item.",
                        "I'll use what you specified.",
                        "Sounds good. Consuming it.",
                    },
                    ["TL"] = {
                        "Gagamitin ko iyon.",
                        "Naintindihan. Gagamitin ko ang bagay na iyon.",
                        "Sige, gagamitin ko iyon.",
                        "Magandang ideya. Gagamitin ko.",
                        "Nakuha ko. Gagamitin na ngayon.",
                        "Sige, ilalapat ko iyan.",
                        "Naiintindihan ko. Makatutulong iyan.",
                        "Sige. Gagamitin ang gamit na 'yan.",
                        "Gagamitin ko ang tinukoy mo.",
                        "Maganda 'yan. Gagamitin na.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.consume.completed",
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
                                ["fallback"] = "That's done.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.task.consume.completed.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "That's done.",
                                        "Finished using that.",
                                        "All used up. Feeling better.",
                                        "Done. That helped out.",
                                        "Finished consuming the item.",
                                        "That's taken care of.",
                                        "All done with that supply.",
                                        "Consumed. Ready to move on.",
                                        "Finished. Much needed.",
                                        "Done. Put to good use.",
                                    },
                                    ["TL"] = {
                                        "Tapos na iyon.",
                                        "Tapos nang gamitin iyon.",
                                        "Naubos na. Mas maayos na ang pakiramdam.",
                                        "Tapos na. Nakatulong iyon.",
                                        "Natapos nang gamitin ang bagay.",
                                        "Naasikaso na iyon.",
                                        "Tapos na sa gamit na 'yon.",
                                        "Nagamit na. Handa nang magpatuloy.",
                                        "Tapos na. Kailangan ko talaga 'yon.",
                                        "Tapos na. Nagamit nang maayos.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "task.consume",
            ["textRoles"] = {
                {
                    ["fallback"] = "That's done.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.task.consume.completed.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "That's done.",
                            "Finished using that.",
                            "All used up. Feeling better.",
                            "Done. That helped out.",
                            "Finished consuming the item.",
                            "That's taken care of.",
                            "All done with that supply.",
                            "Consumed. Ready to move on.",
                            "Finished. Much needed.",
                            "Done. Put to good use.",
                        },
                        ["TL"] = {
                            "Tapos na iyon.",
                            "Tapos nang gamitin iyon.",
                            "Naubos na. Mas maayos na ang pakiramdam.",
                            "Tapos na. Nakatulong iyon.",
                            "Natapos nang gamitin ang bagay.",
                            "Naasikaso na iyon.",
                            "Tapos na sa gamit na 'yon.",
                            "Nagamit na. Handa nang magpatuloy.",
                            "Tapos na. Kailangan ko talaga 'yon.",
                            "Tapos na. Nagamit nang maayos.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "task.consume.completed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "completed",
            ["sourceId"] = "task.consume.completed",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_consume_completed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
        ["namespace"] = "task.consume",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/consume.json",
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
                                        "That's done.",
                                        "Finished using that.",
                                        "All used up. Feeling better.",
                                        "Done. That helped out.",
                                        "Finished consuming the item.",
                                        "That's taken care of.",
                                        "All done with that supply.",
                                        "Consumed. Ready to move on.",
                                        "Finished. Much needed.",
                                        "Done. Put to good use.",
                                    },
                                    ["TL"] = {
                                        "Tapos na iyon.",
                                        "Tapos nang gamitin iyon.",
                                        "Naubos na. Mas maayos na ang pakiramdam.",
                                        "Tapos na. Nakatulong iyon.",
                                        "Natapos nang gamitin ang bagay.",
                                        "Naasikaso na iyon.",
                                        "Tapos na sa gamit na 'yon.",
                                        "Nagamit na. Handa nang magpatuloy.",
                                        "Tapos na. Kailangan ko talaga 'yon.",
                                        "Tapos na. Nagamit nang maayos.",
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
            ["responsePlanID"] = "task.consume.completed",
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
                            ["fallback"] = "That's done.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.task.consume.completed.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_consume_completed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "That's done.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.task.consume.completed.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "That's done.",
                        "Finished using that.",
                        "All used up. Feeling better.",
                        "Done. That helped out.",
                        "Finished consuming the item.",
                        "That's taken care of.",
                        "All done with that supply.",
                        "Consumed. Ready to move on.",
                        "Finished. Much needed.",
                        "Done. Put to good use.",
                    },
                    ["TL"] = {
                        "Tapos na iyon.",
                        "Tapos nang gamitin iyon.",
                        "Naubos na. Mas maayos na ang pakiramdam.",
                        "Tapos na. Nakatulong iyon.",
                        "Natapos nang gamitin ang bagay.",
                        "Naasikaso na iyon.",
                        "Tapos na sa gamit na 'yon.",
                        "Nagamit na. Handa nang magpatuloy.",
                        "Tapos na. Kailangan ko talaga 'yon.",
                        "Tapos na. Nagamit nang maayos.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.consume.failed",
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
                                ["fallback"] = "I couldn't use that.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.task.consume.failed.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I couldn't use that.",
                                        "Failed to consume that item.",
                                        "Something interrupted me while trying to use that.",
                                        "Couldn't finish using it.",
                                        "Unable to apply that right now.",
                                        "Using that failed. Something went wrong.",
                                        "I lost hold of it or couldn't use it.",
                                        "Couldn't consume it. Area wasn't secure.",
                                        "Action interrupted. Item not consumed.",
                                        "Failed to take that.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko nagamit iyon.",
                                        "Bigo sa paggamit ng bagay na iyon.",
                                        "May umabala sa akin habang sinusubukang gamitin iyon.",
                                        "Di natapos gamitin.",
                                        "Di mailapat iyan sa ngayon.",
                                        "Pumalpak ang paggamit. May nangyaring mali.",
                                        "Nabitawan ko o di nagamit.",
                                        "Di nagamit. Di ligtas ang paligid.",
                                        "Naabala ang kilos. Di nagamit ang bagay.",
                                        "Bigo sa paggamit niyan.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "task.consume",
            ["textRoles"] = {
                {
                    ["fallback"] = "I couldn't use that.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.task.consume.failed.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I couldn't use that.",
                            "Failed to consume that item.",
                            "Something interrupted me while trying to use that.",
                            "Couldn't finish using it.",
                            "Unable to apply that right now.",
                            "Using that failed. Something went wrong.",
                            "I lost hold of it or couldn't use it.",
                            "Couldn't consume it. Area wasn't secure.",
                            "Action interrupted. Item not consumed.",
                            "Failed to take that.",
                        },
                        ["TL"] = {
                            "Hindi ko nagamit iyon.",
                            "Bigo sa paggamit ng bagay na iyon.",
                            "May umabala sa akin habang sinusubukang gamitin iyon.",
                            "Di natapos gamitin.",
                            "Di mailapat iyan sa ngayon.",
                            "Pumalpak ang paggamit. May nangyaring mali.",
                            "Nabitawan ko o di nagamit.",
                            "Di nagamit. Di ligtas ang paligid.",
                            "Naabala ang kilos. Di nagamit ang bagay.",
                            "Bigo sa paggamit niyan.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "task.consume.failed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "failed",
            ["sourceId"] = "task.consume.failed",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_consume_failed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
        ["namespace"] = "task.consume",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/consume.json",
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
                                        "I couldn't use that.",
                                        "Failed to consume that item.",
                                        "Something interrupted me while trying to use that.",
                                        "Couldn't finish using it.",
                                        "Unable to apply that right now.",
                                        "Using that failed. Something went wrong.",
                                        "I lost hold of it or couldn't use it.",
                                        "Couldn't consume it. Area wasn't secure.",
                                        "Action interrupted. Item not consumed.",
                                        "Failed to take that.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko nagamit iyon.",
                                        "Bigo sa paggamit ng bagay na iyon.",
                                        "May umabala sa akin habang sinusubukang gamitin iyon.",
                                        "Di natapos gamitin.",
                                        "Di mailapat iyan sa ngayon.",
                                        "Pumalpak ang paggamit. May nangyaring mali.",
                                        "Nabitawan ko o di nagamit.",
                                        "Di nagamit. Di ligtas ang paligid.",
                                        "Naabala ang kilos. Di nagamit ang bagay.",
                                        "Bigo sa paggamit niyan.",
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
            ["responsePlanID"] = "task.consume.failed",
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
                            ["fallback"] = "I couldn't use that.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.task.consume.failed.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_consume_failed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I couldn't use that.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.task.consume.failed.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I couldn't use that.",
                        "Failed to consume that item.",
                        "Something interrupted me while trying to use that.",
                        "Couldn't finish using it.",
                        "Unable to apply that right now.",
                        "Using that failed. Something went wrong.",
                        "I lost hold of it or couldn't use it.",
                        "Couldn't consume it. Area wasn't secure.",
                        "Action interrupted. Item not consumed.",
                        "Failed to take that.",
                    },
                    ["TL"] = {
                        "Hindi ko nagamit iyon.",
                        "Bigo sa paggamit ng bagay na iyon.",
                        "May umabala sa akin habang sinusubukang gamitin iyon.",
                        "Di natapos gamitin.",
                        "Di mailapat iyan sa ngayon.",
                        "Pumalpak ang paggamit. May nangyaring mali.",
                        "Nabitawan ko o di nagamit.",
                        "Di nagamit. Di ligtas ang paligid.",
                        "Naabala ang kilos. Di nagamit ang bagay.",
                        "Bigo sa paggamit niyan.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.consume.rejected",
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
                                ["fallback"] = "I can't use that right now.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.task.consume.rejected.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I can't use that right now.",
                                        "I don't need to use that at the moment.",
                                        "That's not suitable for me right now.",
                                        "Unable to consume that. Not needed.",
                                        "I can't use that under these conditions.",
                                        "Save it for later. I don't need it now.",
                                        "Refusing to consume that. Not appropriate.",
                                        "I don't have a use for that right now.",
                                        "Can't use that. Not the right time.",
                                        "Consume order rejected.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko magamit iyon ngayon.",
                                        "Di ko kailangang gamitin iyan sa sandaling ito.",
                                        "Di angkop sa akin 'yan ngayon.",
                                        "Di magagamit 'yan. Di kailangan.",
                                        "Di ko magagamit 'yan sa ganitong kalagayan.",
                                        "Itabi mo muna. Di ko kailangan ngayon.",
                                        "Tumatangging gamitin 'yan. Di nararapat.",
                                        "Wala akong paggagamitan niyan ngayon.",
                                        "Di magagamit 'yan. Maling oras.",
                                        "Tinatanggihan ang utos na gamitin.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "task.consume",
            ["textRoles"] = {
                {
                    ["fallback"] = "I can't use that right now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.task.consume.rejected.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I can't use that right now.",
                            "I don't need to use that at the moment.",
                            "That's not suitable for me right now.",
                            "Unable to consume that. Not needed.",
                            "I can't use that under these conditions.",
                            "Save it for later. I don't need it now.",
                            "Refusing to consume that. Not appropriate.",
                            "I don't have a use for that right now.",
                            "Can't use that. Not the right time.",
                            "Consume order rejected.",
                        },
                        ["TL"] = {
                            "Hindi ko magamit iyon ngayon.",
                            "Di ko kailangang gamitin iyan sa sandaling ito.",
                            "Di angkop sa akin 'yan ngayon.",
                            "Di magagamit 'yan. Di kailangan.",
                            "Di ko magagamit 'yan sa ganitong kalagayan.",
                            "Itabi mo muna. Di ko kailangan ngayon.",
                            "Tumatangging gamitin 'yan. Di nararapat.",
                            "Wala akong paggagamitan niyan ngayon.",
                            "Di magagamit 'yan. Maling oras.",
                            "Tinatanggihan ang utos na gamitin.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "task.consume.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "rejected",
            ["sourceId"] = "task.consume.rejected",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_consume_rejected.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
        ["namespace"] = "task.consume",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/consume.json",
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
                                        "I can't use that right now.",
                                        "I don't need to use that at the moment.",
                                        "That's not suitable for me right now.",
                                        "Unable to consume that. Not needed.",
                                        "I can't use that under these conditions.",
                                        "Save it for later. I don't need it now.",
                                        "Refusing to consume that. Not appropriate.",
                                        "I don't have a use for that right now.",
                                        "Can't use that. Not the right time.",
                                        "Consume order rejected.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko magamit iyon ngayon.",
                                        "Di ko kailangang gamitin iyan sa sandaling ito.",
                                        "Di angkop sa akin 'yan ngayon.",
                                        "Di magagamit 'yan. Di kailangan.",
                                        "Di ko magagamit 'yan sa ganitong kalagayan.",
                                        "Itabi mo muna. Di ko kailangan ngayon.",
                                        "Tumatangging gamitin 'yan. Di nararapat.",
                                        "Wala akong paggagamitan niyan ngayon.",
                                        "Di magagamit 'yan. Maling oras.",
                                        "Tinatanggihan ang utos na gamitin.",
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
            ["responsePlanID"] = "task.consume.rejected",
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
                            ["fallback"] = "I can't use that right now.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.task.consume.rejected.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_consume_rejected.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I can't use that right now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.task.consume.rejected.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I can't use that right now.",
                        "I don't need to use that at the moment.",
                        "That's not suitable for me right now.",
                        "Unable to consume that. Not needed.",
                        "I can't use that under these conditions.",
                        "Save it for later. I don't need it now.",
                        "Refusing to consume that. Not appropriate.",
                        "I don't have a use for that right now.",
                        "Can't use that. Not the right time.",
                        "Consume order rejected.",
                    },
                    ["TL"] = {
                        "Hindi ko magamit iyon ngayon.",
                        "Di ko kailangang gamitin iyan sa sandaling ito.",
                        "Di angkop sa akin 'yan ngayon.",
                        "Di magagamit 'yan. Di kailangan.",
                        "Di ko magagamit 'yan sa ganitong kalagayan.",
                        "Itabi mo muna. Di ko kailangan ngayon.",
                        "Tumatangging gamitin 'yan. Di nararapat.",
                        "Wala akong paggagamitan niyan ngayon.",
                        "Di magagamit 'yan. Maling oras.",
                        "Tinatanggihan ang utos na gamitin.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.drink.active",
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
                                ["fallback"] = "Taking a drink now.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.task.drink.active.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Taking a drink now.",
                                        "Drinking some water right now.",
                                        "Quenching my thirst. Give me a second.",
                                        "Currently having a drink.",
                                        "Taking some fluids now.",
                                        "Drinking. Needed this badly.",
                                        "Getting some water in me.",
                                        "Taking a quick drink.",
                                        "Drinking now. Won't take long.",
                                        "Having a drink as ordered.",
                                    },
                                    ["TL"] = {
                                        "Umiinom na ako ngayon.",
                                        "Umiinom ng kaunting tubig ngayon.",
                                        "Pinapawi ang uhaw. Sandali lang.",
                                        "Kasalukuyang umiinom.",
                                        "Umiinom na ngayon.",
                                        "Umiinom. Kailangang-kailangan ko ito.",
                                        "Nagpapasok ng tubig sa katawan.",
                                        "Umiinom nang mabilisan.",
                                        "Umiinom na. Di magtatagal.",
                                        "Umiinom ayon sa utos.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "task.drink",
            ["textRoles"] = {
                {
                    ["fallback"] = "Taking a drink now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.task.drink.active.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Taking a drink now.",
                            "Drinking some water right now.",
                            "Quenching my thirst. Give me a second.",
                            "Currently having a drink.",
                            "Taking some fluids now.",
                            "Drinking. Needed this badly.",
                            "Getting some water in me.",
                            "Taking a quick drink.",
                            "Drinking now. Won't take long.",
                            "Having a drink as ordered.",
                        },
                        ["TL"] = {
                            "Umiinom na ako ngayon.",
                            "Umiinom ng kaunting tubig ngayon.",
                            "Pinapawi ang uhaw. Sandali lang.",
                            "Kasalukuyang umiinom.",
                            "Umiinom na ngayon.",
                            "Umiinom. Kailangang-kailangan ko ito.",
                            "Nagpapasok ng tubig sa katawan.",
                            "Umiinom nang mabilisan.",
                            "Umiinom na. Di magtatagal.",
                            "Umiinom ayon sa utos.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "task.drink.active",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "active",
            ["sourceId"] = "task.drink.active",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_drink_active.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
        ["namespace"] = "task.drink",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/drink.json",
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
                                        "Taking a drink now.",
                                        "Drinking some water right now.",
                                        "Quenching my thirst. Give me a second.",
                                        "Currently having a drink.",
                                        "Taking some fluids now.",
                                        "Drinking. Needed this badly.",
                                        "Getting some water in me.",
                                        "Taking a quick drink.",
                                        "Drinking now. Won't take long.",
                                        "Having a drink as ordered.",
                                    },
                                    ["TL"] = {
                                        "Umiinom na ako ngayon.",
                                        "Umiinom ng kaunting tubig ngayon.",
                                        "Pinapawi ang uhaw. Sandali lang.",
                                        "Kasalukuyang umiinom.",
                                        "Umiinom na ngayon.",
                                        "Umiinom. Kailangang-kailangan ko ito.",
                                        "Nagpapasok ng tubig sa katawan.",
                                        "Umiinom nang mabilisan.",
                                        "Umiinom na. Di magtatagal.",
                                        "Umiinom ayon sa utos.",
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
            ["responsePlanID"] = "task.drink.active",
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
                            ["fallback"] = "Taking a drink now.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.task.drink.active.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_drink_active.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Taking a drink now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.task.drink.active.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Taking a drink now.",
                        "Drinking some water right now.",
                        "Quenching my thirst. Give me a second.",
                        "Currently having a drink.",
                        "Taking some fluids now.",
                        "Drinking. Needed this badly.",
                        "Getting some water in me.",
                        "Taking a quick drink.",
                        "Drinking now. Won't take long.",
                        "Having a drink as ordered.",
                    },
                    ["TL"] = {
                        "Umiinom na ako ngayon.",
                        "Umiinom ng kaunting tubig ngayon.",
                        "Pinapawi ang uhaw. Sandali lang.",
                        "Kasalukuyang umiinom.",
                        "Umiinom na ngayon.",
                        "Umiinom. Kailangang-kailangan ko ito.",
                        "Nagpapasok ng tubig sa katawan.",
                        "Umiinom nang mabilisan.",
                        "Umiinom na. Di magtatagal.",
                        "Umiinom ayon sa utos.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.drink.admitted",
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
                                ["fallback"] = "I'll have a drink.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.task.drink.admitted.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'll have a drink.",
                                        "Understood. Getting some water.",
                                        "I could use some water. Drinking now.",
                                        "All right, I'll hydrate.",
                                        "Good call. I was getting thirsty.",
                                        "I'll take a drink from my supply.",
                                        "Understood. Hydrating immediately.",
                                        "Right. Taking a sip.",
                                        "I'll drink that now.",
                                        "Sounds good. Drinking.",
                                    },
                                    ["TL"] = {
                                        "Iinom ako.",
                                        "Naintindihan. Kukuha ng tubig.",
                                        "Kailangan ko nga ng tubig. Iinom na.",
                                        "Sige, magpapatubig ako.",
                                        "Magandang paalala. Nauuhaw na nga ako.",
                                        "Iinom ako mula sa baon ko.",
                                        "Naiintindihan ko. Iinom agad.",
                                        "Sige. Iinom nang kaunti.",
                                        "Iinumin ko na iyan ngayon.",
                                        "Maganda 'yan. Iinom na.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "task.drink",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'll have a drink.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.task.drink.admitted.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I'll have a drink.",
                            "Understood. Getting some water.",
                            "I could use some water. Drinking now.",
                            "All right, I'll hydrate.",
                            "Good call. I was getting thirsty.",
                            "I'll take a drink from my supply.",
                            "Understood. Hydrating immediately.",
                            "Right. Taking a sip.",
                            "I'll drink that now.",
                            "Sounds good. Drinking.",
                        },
                        ["TL"] = {
                            "Iinom ako.",
                            "Naintindihan. Kukuha ng tubig.",
                            "Kailangan ko nga ng tubig. Iinom na.",
                            "Sige, magpapatubig ako.",
                            "Magandang paalala. Nauuhaw na nga ako.",
                            "Iinom ako mula sa baon ko.",
                            "Naiintindihan ko. Iinom agad.",
                            "Sige. Iinom nang kaunti.",
                            "Iinumin ko na iyan ngayon.",
                            "Maganda 'yan. Iinom na.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "task.drink.admitted",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "admitted",
            ["sourceId"] = "task.drink.admitted",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_drink_admitted.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
        ["namespace"] = "task.drink",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/drink.json",
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
                                        "I'll have a drink.",
                                        "Understood. Getting some water.",
                                        "I could use some water. Drinking now.",
                                        "All right, I'll hydrate.",
                                        "Good call. I was getting thirsty.",
                                        "I'll take a drink from my supply.",
                                        "Understood. Hydrating immediately.",
                                        "Right. Taking a sip.",
                                        "I'll drink that now.",
                                        "Sounds good. Drinking.",
                                    },
                                    ["TL"] = {
                                        "Iinom ako.",
                                        "Naintindihan. Kukuha ng tubig.",
                                        "Kailangan ko nga ng tubig. Iinom na.",
                                        "Sige, magpapatubig ako.",
                                        "Magandang paalala. Nauuhaw na nga ako.",
                                        "Iinom ako mula sa baon ko.",
                                        "Naiintindihan ko. Iinom agad.",
                                        "Sige. Iinom nang kaunti.",
                                        "Iinumin ko na iyan ngayon.",
                                        "Maganda 'yan. Iinom na.",
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
            ["responsePlanID"] = "task.drink.admitted",
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
                            ["fallback"] = "I'll have a drink.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.task.drink.admitted.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_drink_admitted.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'll have a drink.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.task.drink.admitted.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I'll have a drink.",
                        "Understood. Getting some water.",
                        "I could use some water. Drinking now.",
                        "All right, I'll hydrate.",
                        "Good call. I was getting thirsty.",
                        "I'll take a drink from my supply.",
                        "Understood. Hydrating immediately.",
                        "Right. Taking a sip.",
                        "I'll drink that now.",
                        "Sounds good. Drinking.",
                    },
                    ["TL"] = {
                        "Iinom ako.",
                        "Naintindihan. Kukuha ng tubig.",
                        "Kailangan ko nga ng tubig. Iinom na.",
                        "Sige, magpapatubig ako.",
                        "Magandang paalala. Nauuhaw na nga ako.",
                        "Iinom ako mula sa baon ko.",
                        "Naiintindihan ko. Iinom agad.",
                        "Sige. Iinom nang kaunti.",
                        "Iinumin ko na iyan ngayon.",
                        "Maganda 'yan. Iinom na.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.drink.completed",
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
                                ["fallback"] = "Much better. Thirst is gone.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.task.drink.completed.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Much better. Thirst is gone.",
                                        "Finished drinking. Feeling refreshed.",
                                        "That hit the spot. Done drinking.",
                                        "Hydrated and ready to move.",
                                        "Finished that drink.",
                                        "Done. Throat isn't parched anymore.",
                                        "All drank. Ready for action.",
                                        "Finished having a drink.",
                                        "Done drinking. Let's keep going.",
                                        "Hydration complete.",
                                    },
                                    ["TL"] = {
                                        "Mas maayos na. Wala na ang uhaw.",
                                        "Tapos nang uminom. Maginhawa na ang pakiramdam.",
                                        "Eksakto 'yon. Tapos nang uminom.",
                                        "May sapat nang tubig at handang kumilos.",
                                        "Naubos na ang inumin.",
                                        "Tapos na. Di na tuyo ang lalamunan ko.",
                                        "Nainom na lahat. Handa na sa aksyon.",
                                        "Natapos nang uminom.",
                                        "Tapos nang uminom. Tuloy na tayo.",
                                        "Kumpleto na ang pag-inom.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "task.drink",
            ["textRoles"] = {
                {
                    ["fallback"] = "Much better. Thirst is gone.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.task.drink.completed.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Much better. Thirst is gone.",
                            "Finished drinking. Feeling refreshed.",
                            "That hit the spot. Done drinking.",
                            "Hydrated and ready to move.",
                            "Finished that drink.",
                            "Done. Throat isn't parched anymore.",
                            "All drank. Ready for action.",
                            "Finished having a drink.",
                            "Done drinking. Let's keep going.",
                            "Hydration complete.",
                        },
                        ["TL"] = {
                            "Mas maayos na. Wala na ang uhaw.",
                            "Tapos nang uminom. Maginhawa na ang pakiramdam.",
                            "Eksakto 'yon. Tapos nang uminom.",
                            "May sapat nang tubig at handang kumilos.",
                            "Naubos na ang inumin.",
                            "Tapos na. Di na tuyo ang lalamunan ko.",
                            "Nainom na lahat. Handa na sa aksyon.",
                            "Natapos nang uminom.",
                            "Tapos nang uminom. Tuloy na tayo.",
                            "Kumpleto na ang pag-inom.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "task.drink.completed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "completed",
            ["sourceId"] = "task.drink.completed",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_drink_completed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
        ["namespace"] = "task.drink",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/drink.json",
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
                                        "Much better. Thirst is gone.",
                                        "Finished drinking. Feeling refreshed.",
                                        "That hit the spot. Done drinking.",
                                        "Hydrated and ready to move.",
                                        "Finished that drink.",
                                        "Done. Throat isn't parched anymore.",
                                        "All drank. Ready for action.",
                                        "Finished having a drink.",
                                        "Done drinking. Let's keep going.",
                                        "Hydration complete.",
                                    },
                                    ["TL"] = {
                                        "Mas maayos na. Wala na ang uhaw.",
                                        "Tapos nang uminom. Maginhawa na ang pakiramdam.",
                                        "Eksakto 'yon. Tapos nang uminom.",
                                        "May sapat nang tubig at handang kumilos.",
                                        "Naubos na ang inumin.",
                                        "Tapos na. Di na tuyo ang lalamunan ko.",
                                        "Nainom na lahat. Handa na sa aksyon.",
                                        "Natapos nang uminom.",
                                        "Tapos nang uminom. Tuloy na tayo.",
                                        "Kumpleto na ang pag-inom.",
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
            ["responsePlanID"] = "task.drink.completed",
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
                            ["fallback"] = "Much better. Thirst is gone.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.task.drink.completed.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_drink_completed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Much better. Thirst is gone.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.task.drink.completed.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Much better. Thirst is gone.",
                        "Finished drinking. Feeling refreshed.",
                        "That hit the spot. Done drinking.",
                        "Hydrated and ready to move.",
                        "Finished that drink.",
                        "Done. Throat isn't parched anymore.",
                        "All drank. Ready for action.",
                        "Finished having a drink.",
                        "Done drinking. Let's keep going.",
                        "Hydration complete.",
                    },
                    ["TL"] = {
                        "Mas maayos na. Wala na ang uhaw.",
                        "Tapos nang uminom. Maginhawa na ang pakiramdam.",
                        "Eksakto 'yon. Tapos nang uminom.",
                        "May sapat nang tubig at handang kumilos.",
                        "Naubos na ang inumin.",
                        "Tapos na. Di na tuyo ang lalamunan ko.",
                        "Nainom na lahat. Handa na sa aksyon.",
                        "Natapos nang uminom.",
                        "Tapos nang uminom. Tuloy na tayo.",
                        "Kumpleto na ang pag-inom.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.drink.failed",
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
                                ["fallback"] = "I couldn't get a drink.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.task.drink.failed.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I couldn't get a drink.",
                                        "Failed to drink. Container was empty or tainted.",
                                        "Couldn't drink that. It wasn't clean water.",
                                        "I was interrupted before I could drink.",
                                        "Unable to have a drink right now.",
                                        "Spilled it or couldn't reach it. Drinking failed.",
                                        "Water container is dry.",
                                        "Couldn't drink. Threat forced me to stop.",
                                        "Action failed. Still thirsty.",
                                        "Failed to take a drink.",
                                    },
                                    ["TL"] = {
                                        "Hindi ako nakainom.",
                                        "Bigo sa pag-inom. Walang laman o marumi ang lalagyan.",
                                        "Di mainom 'yon. Di malinis na tubig.",
                                        "Naabala ako bago ako nakainom.",
                                        "Di makainom sa ngayon.",
                                        "Natapon o di naabot. Pumalpak ang pag-inom.",
                                        "Tuyot ang lalagyan ng tubig.",
                                        "Di nakainom. Napilitang huminto dahil sa banta.",
                                        "Bigo ang kilos. Nauuhaw pa rin.",
                                        "Bigo sa pag-inom.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "task.drink",
            ["textRoles"] = {
                {
                    ["fallback"] = "I couldn't get a drink.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.task.drink.failed.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I couldn't get a drink.",
                            "Failed to drink. Container was empty or tainted.",
                            "Couldn't drink that. It wasn't clean water.",
                            "I was interrupted before I could drink.",
                            "Unable to have a drink right now.",
                            "Spilled it or couldn't reach it. Drinking failed.",
                            "Water container is dry.",
                            "Couldn't drink. Threat forced me to stop.",
                            "Action failed. Still thirsty.",
                            "Failed to take a drink.",
                        },
                        ["TL"] = {
                            "Hindi ako nakainom.",
                            "Bigo sa pag-inom. Walang laman o marumi ang lalagyan.",
                            "Di mainom 'yon. Di malinis na tubig.",
                            "Naabala ako bago ako nakainom.",
                            "Di makainom sa ngayon.",
                            "Natapon o di naabot. Pumalpak ang pag-inom.",
                            "Tuyot ang lalagyan ng tubig.",
                            "Di nakainom. Napilitang huminto dahil sa banta.",
                            "Bigo ang kilos. Nauuhaw pa rin.",
                            "Bigo sa pag-inom.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "task.drink.failed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "failed",
            ["sourceId"] = "task.drink.failed",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_drink_failed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
        ["namespace"] = "task.drink",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/drink.json",
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
                                        "I couldn't get a drink.",
                                        "Failed to drink. Container was empty or tainted.",
                                        "Couldn't drink that. It wasn't clean water.",
                                        "I was interrupted before I could drink.",
                                        "Unable to have a drink right now.",
                                        "Spilled it or couldn't reach it. Drinking failed.",
                                        "Water container is dry.",
                                        "Couldn't drink. Threat forced me to stop.",
                                        "Action failed. Still thirsty.",
                                        "Failed to take a drink.",
                                    },
                                    ["TL"] = {
                                        "Hindi ako nakainom.",
                                        "Bigo sa pag-inom. Walang laman o marumi ang lalagyan.",
                                        "Di mainom 'yon. Di malinis na tubig.",
                                        "Naabala ako bago ako nakainom.",
                                        "Di makainom sa ngayon.",
                                        "Natapon o di naabot. Pumalpak ang pag-inom.",
                                        "Tuyot ang lalagyan ng tubig.",
                                        "Di nakainom. Napilitang huminto dahil sa banta.",
                                        "Bigo ang kilos. Nauuhaw pa rin.",
                                        "Bigo sa pag-inom.",
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
            ["responsePlanID"] = "task.drink.failed",
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
                            ["fallback"] = "I couldn't get a drink.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.task.drink.failed.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_drink_failed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I couldn't get a drink.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.task.drink.failed.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I couldn't get a drink.",
                        "Failed to drink. Container was empty or tainted.",
                        "Couldn't drink that. It wasn't clean water.",
                        "I was interrupted before I could drink.",
                        "Unable to have a drink right now.",
                        "Spilled it or couldn't reach it. Drinking failed.",
                        "Water container is dry.",
                        "Couldn't drink. Threat forced me to stop.",
                        "Action failed. Still thirsty.",
                        "Failed to take a drink.",
                    },
                    ["TL"] = {
                        "Hindi ako nakainom.",
                        "Bigo sa pag-inom. Walang laman o marumi ang lalagyan.",
                        "Di mainom 'yon. Di malinis na tubig.",
                        "Naabala ako bago ako nakainom.",
                        "Di makainom sa ngayon.",
                        "Natapon o di naabot. Pumalpak ang pag-inom.",
                        "Tuyot ang lalagyan ng tubig.",
                        "Di nakainom. Napilitang huminto dahil sa banta.",
                        "Bigo ang kilos. Nauuhaw pa rin.",
                        "Bigo sa pag-inom.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.drink.rejected",
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
                                ["fallback"] = "I'm not thirsty right now.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.task.drink.rejected.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'm not thirsty right now.",
                                        "I don't need to drink at the moment.",
                                        "I'm fully hydrated. Saving the water.",
                                        "Can't drink right now. Too dangerous to pause.",
                                        "Refusing to drink that water. It looks tainted.",
                                        "I have plenty of fluids. Don't need to drink.",
                                        "No need for a drink yet.",
                                        "I'll save our clean water for later.",
                                        "Drink order rejected. Not parched.",
                                        "Can't drink that right now.",
                                    },
                                    ["TL"] = {
                                        "Hindi ako nauuhaw ngayon.",
                                        "Di ko kailangang uminom sa sandaling ito.",
                                        "Busog pa ako sa tubig. Itatabi ang inumin.",
                                        "Di pwedeng uminom ngayon. Masyadong mapanganib huminto.",
                                        "Tumatangging inumin ang tubig na 'yan. Mukhang kontaminado.",
                                        "Marami pa akong tubig sa katawan. Di kailangang uminom.",
                                        "Wala pang pangangailangan sa inumin.",
                                        "Itatabi ko ang malinis na tubig mamaya.",
                                        "Tinatanggihan ang pag-inom. Di ako uhaw.",
                                        "Di ko maiinom 'yan ngayon.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "task.drink",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'm not thirsty right now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.task.drink.rejected.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I'm not thirsty right now.",
                            "I don't need to drink at the moment.",
                            "I'm fully hydrated. Saving the water.",
                            "Can't drink right now. Too dangerous to pause.",
                            "Refusing to drink that water. It looks tainted.",
                            "I have plenty of fluids. Don't need to drink.",
                            "No need for a drink yet.",
                            "I'll save our clean water for later.",
                            "Drink order rejected. Not parched.",
                            "Can't drink that right now.",
                        },
                        ["TL"] = {
                            "Hindi ako nauuhaw ngayon.",
                            "Di ko kailangang uminom sa sandaling ito.",
                            "Busog pa ako sa tubig. Itatabi ang inumin.",
                            "Di pwedeng uminom ngayon. Masyadong mapanganib huminto.",
                            "Tumatangging inumin ang tubig na 'yan. Mukhang kontaminado.",
                            "Marami pa akong tubig sa katawan. Di kailangang uminom.",
                            "Wala pang pangangailangan sa inumin.",
                            "Itatabi ko ang malinis na tubig mamaya.",
                            "Tinatanggihan ang pag-inom. Di ako uhaw.",
                            "Di ko maiinom 'yan ngayon.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "task.drink.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "rejected",
            ["sourceId"] = "task.drink.rejected",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_drink_rejected.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
        ["namespace"] = "task.drink",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/drink.json",
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
                                        "I'm not thirsty right now.",
                                        "I don't need to drink at the moment.",
                                        "I'm fully hydrated. Saving the water.",
                                        "Can't drink right now. Too dangerous to pause.",
                                        "Refusing to drink that water. It looks tainted.",
                                        "I have plenty of fluids. Don't need to drink.",
                                        "No need for a drink yet.",
                                        "I'll save our clean water for later.",
                                        "Drink order rejected. Not parched.",
                                        "Can't drink that right now.",
                                    },
                                    ["TL"] = {
                                        "Hindi ako nauuhaw ngayon.",
                                        "Di ko kailangang uminom sa sandaling ito.",
                                        "Busog pa ako sa tubig. Itatabi ang inumin.",
                                        "Di pwedeng uminom ngayon. Masyadong mapanganib huminto.",
                                        "Tumatangging inumin ang tubig na 'yan. Mukhang kontaminado.",
                                        "Marami pa akong tubig sa katawan. Di kailangang uminom.",
                                        "Wala pang pangangailangan sa inumin.",
                                        "Itatabi ko ang malinis na tubig mamaya.",
                                        "Tinatanggihan ang pag-inom. Di ako uhaw.",
                                        "Di ko maiinom 'yan ngayon.",
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
            ["responsePlanID"] = "task.drink.rejected",
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
                            ["fallback"] = "I'm not thirsty right now.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.task.drink.rejected.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_drink_rejected.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'm not thirsty right now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.task.drink.rejected.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I'm not thirsty right now.",
                        "I don't need to drink at the moment.",
                        "I'm fully hydrated. Saving the water.",
                        "Can't drink right now. Too dangerous to pause.",
                        "Refusing to drink that water. It looks tainted.",
                        "I have plenty of fluids. Don't need to drink.",
                        "No need for a drink yet.",
                        "I'll save our clean water for later.",
                        "Drink order rejected. Not parched.",
                        "Can't drink that right now.",
                    },
                    ["TL"] = {
                        "Hindi ako nauuhaw ngayon.",
                        "Di ko kailangang uminom sa sandaling ito.",
                        "Busog pa ako sa tubig. Itatabi ang inumin.",
                        "Di pwedeng uminom ngayon. Masyadong mapanganib huminto.",
                        "Tumatangging inumin ang tubig na 'yan. Mukhang kontaminado.",
                        "Marami pa akong tubig sa katawan. Di kailangang uminom.",
                        "Wala pang pangangailangan sa inumin.",
                        "Itatabi ko ang malinis na tubig mamaya.",
                        "Tinatanggihan ang pag-inom. Di ako uhaw.",
                        "Di ko maiinom 'yan ngayon.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.eat.active",
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
                                ["fallback"] = "Eating now.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.task.eat.active.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Eating now.",
                                        "Having a bite right now.",
                                        "Chewing through some food. Give me a moment.",
                                        "Currently eating.",
                                        "Getting some calories in me.",
                                        "Eating my rations now.",
                                        "Taking a meal break as instructed.",
                                        "Eating. Needed the energy.",
                                        "Having some food now.",
                                        "Eating quietly. Won't be long.",
                                    },
                                    ["TL"] = {
                                        "Kumakain na ako ngayon.",
                                        "Kumakain ng kaunti ngayon.",
                                        "Kumakain ng pagkain. Sandali lang.",
                                        "Kasalukuyang kumakain.",
                                        "Nagpapasok ng lakas sa katawan.",
                                        "Kinakain ang baong pagkain ngayon.",
                                        "Kumakain ayon sa utos.",
                                        "Kumakain. Kailangan ko ng lakas.",
                                        "Kumakain na ngayon.",
                                        "Kumakain nang tahimik. Saglit lang ito.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "task.eat",
            ["textRoles"] = {
                {
                    ["fallback"] = "Eating now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.task.eat.active.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Eating now.",
                            "Having a bite right now.",
                            "Chewing through some food. Give me a moment.",
                            "Currently eating.",
                            "Getting some calories in me.",
                            "Eating my rations now.",
                            "Taking a meal break as instructed.",
                            "Eating. Needed the energy.",
                            "Having some food now.",
                            "Eating quietly. Won't be long.",
                        },
                        ["TL"] = {
                            "Kumakain na ako ngayon.",
                            "Kumakain ng kaunti ngayon.",
                            "Kumakain ng pagkain. Sandali lang.",
                            "Kasalukuyang kumakain.",
                            "Nagpapasok ng lakas sa katawan.",
                            "Kinakain ang baong pagkain ngayon.",
                            "Kumakain ayon sa utos.",
                            "Kumakain. Kailangan ko ng lakas.",
                            "Kumakain na ngayon.",
                            "Kumakain nang tahimik. Saglit lang ito.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "task.eat.active",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "active",
            ["sourceId"] = "task.eat.active",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_eat_active.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
        ["namespace"] = "task.eat",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/eat.json",
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
                                        "Eating now.",
                                        "Having a bite right now.",
                                        "Chewing through some food. Give me a moment.",
                                        "Currently eating.",
                                        "Getting some calories in me.",
                                        "Eating my rations now.",
                                        "Taking a meal break as instructed.",
                                        "Eating. Needed the energy.",
                                        "Having some food now.",
                                        "Eating quietly. Won't be long.",
                                    },
                                    ["TL"] = {
                                        "Kumakain na ako ngayon.",
                                        "Kumakain ng kaunti ngayon.",
                                        "Kumakain ng pagkain. Sandali lang.",
                                        "Kasalukuyang kumakain.",
                                        "Nagpapasok ng lakas sa katawan.",
                                        "Kinakain ang baong pagkain ngayon.",
                                        "Kumakain ayon sa utos.",
                                        "Kumakain. Kailangan ko ng lakas.",
                                        "Kumakain na ngayon.",
                                        "Kumakain nang tahimik. Saglit lang ito.",
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
            ["responsePlanID"] = "task.eat.active",
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
                            ["fallback"] = "Eating now.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.task.eat.active.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_eat_active.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Eating now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.task.eat.active.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Eating now.",
                        "Having a bite right now.",
                        "Chewing through some food. Give me a moment.",
                        "Currently eating.",
                        "Getting some calories in me.",
                        "Eating my rations now.",
                        "Taking a meal break as instructed.",
                        "Eating. Needed the energy.",
                        "Having some food now.",
                        "Eating quietly. Won't be long.",
                    },
                    ["TL"] = {
                        "Kumakain na ako ngayon.",
                        "Kumakain ng kaunti ngayon.",
                        "Kumakain ng pagkain. Sandali lang.",
                        "Kasalukuyang kumakain.",
                        "Nagpapasok ng lakas sa katawan.",
                        "Kinakain ang baong pagkain ngayon.",
                        "Kumakain ayon sa utos.",
                        "Kumakain. Kailangan ko ng lakas.",
                        "Kumakain na ngayon.",
                        "Kumakain nang tahimik. Saglit lang ito.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.eat.admitted",
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
                                ["fallback"] = "I'll eat that.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.task.eat.admitted.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'll eat that.",
                                        "Understood. Getting something to eat.",
                                        "Good call. My stomach was growling.",
                                        "All right, I'll eat some food.",
                                        "Taking a bite to keep my strength up.",
                                        "Understood. Eating now.",
                                        "I'll consume those rations.",
                                        "Right. Time for a meal.",
                                        "I'll eat what you designated.",
                                        "Sounds good. Grabbing food.",
                                    },
                                    ["TL"] = {
                                        "Kakainin ko iyon.",
                                        "Naintindihan. Kukuha ng makakain.",
                                        "Magandang paalala. Kumakalam na ang tiyan ko.",
                                        "Sige, kakain ako ng pagkain.",
                                        "Kakain para mapanatili ang lakas.",
                                        "Naiintindihan ko. Kakain na.",
                                        "Kakainin ko ang mga rasyong 'yan.",
                                        "Sige. Oras na para kumain.",
                                        "Kakainin ko ang tinukoy mo.",
                                        "Maganda 'yan. Kukuha ng pagkain.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "task.eat",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'll eat that.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.task.eat.admitted.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I'll eat that.",
                            "Understood. Getting something to eat.",
                            "Good call. My stomach was growling.",
                            "All right, I'll eat some food.",
                            "Taking a bite to keep my strength up.",
                            "Understood. Eating now.",
                            "I'll consume those rations.",
                            "Right. Time for a meal.",
                            "I'll eat what you designated.",
                            "Sounds good. Grabbing food.",
                        },
                        ["TL"] = {
                            "Kakainin ko iyon.",
                            "Naintindihan. Kukuha ng makakain.",
                            "Magandang paalala. Kumakalam na ang tiyan ko.",
                            "Sige, kakain ako ng pagkain.",
                            "Kakain para mapanatili ang lakas.",
                            "Naiintindihan ko. Kakain na.",
                            "Kakainin ko ang mga rasyong 'yan.",
                            "Sige. Oras na para kumain.",
                            "Kakainin ko ang tinukoy mo.",
                            "Maganda 'yan. Kukuha ng pagkain.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "task.eat.admitted",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "admitted",
            ["sourceId"] = "task.eat.admitted",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_eat_admitted.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
        ["namespace"] = "task.eat",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/eat.json",
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
                                        "I'll eat that.",
                                        "Understood. Getting something to eat.",
                                        "Good call. My stomach was growling.",
                                        "All right, I'll eat some food.",
                                        "Taking a bite to keep my strength up.",
                                        "Understood. Eating now.",
                                        "I'll consume those rations.",
                                        "Right. Time for a meal.",
                                        "I'll eat what you designated.",
                                        "Sounds good. Grabbing food.",
                                    },
                                    ["TL"] = {
                                        "Kakainin ko iyon.",
                                        "Naintindihan. Kukuha ng makakain.",
                                        "Magandang paalala. Kumakalam na ang tiyan ko.",
                                        "Sige, kakain ako ng pagkain.",
                                        "Kakain para mapanatili ang lakas.",
                                        "Naiintindihan ko. Kakain na.",
                                        "Kakainin ko ang mga rasyong 'yan.",
                                        "Sige. Oras na para kumain.",
                                        "Kakainin ko ang tinukoy mo.",
                                        "Maganda 'yan. Kukuha ng pagkain.",
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
            ["responsePlanID"] = "task.eat.admitted",
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
                            ["fallback"] = "I'll eat that.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.task.eat.admitted.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_eat_admitted.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'll eat that.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.task.eat.admitted.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I'll eat that.",
                        "Understood. Getting something to eat.",
                        "Good call. My stomach was growling.",
                        "All right, I'll eat some food.",
                        "Taking a bite to keep my strength up.",
                        "Understood. Eating now.",
                        "I'll consume those rations.",
                        "Right. Time for a meal.",
                        "I'll eat what you designated.",
                        "Sounds good. Grabbing food.",
                    },
                    ["TL"] = {
                        "Kakainin ko iyon.",
                        "Naintindihan. Kukuha ng makakain.",
                        "Magandang paalala. Kumakalam na ang tiyan ko.",
                        "Sige, kakain ako ng pagkain.",
                        "Kakain para mapanatili ang lakas.",
                        "Naiintindihan ko. Kakain na.",
                        "Kakainin ko ang mga rasyong 'yan.",
                        "Sige. Oras na para kumain.",
                        "Kakainin ko ang tinukoy mo.",
                        "Maganda 'yan. Kukuha ng pagkain.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.eat.completed",
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
                                ["fallback"] = "Finished eating. Feeling much better.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.task.eat.completed.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Finished eating. Feeling much better.",
                                        "That food helped a lot. Done.",
                                        "Done eating. Energy restored.",
                                        "Stomach is full. Ready to move.",
                                        "Finished that meal.",
                                        "All eaten. Good to keep going.",
                                        "Done. That tasted better than expected.",
                                        "Meal completed.",
                                        "Finished eating. Back on task.",
                                        "Rations finished. Strength is back.",
                                    },
                                    ["TL"] = {
                                        "Tapos nang kumain. Mas maayos na ang pakiramdam.",
                                        "Nakatulong nang malaki ang pagkain. Tapos na.",
                                        "Tapos nang kumain. Bumalik na ang lakas.",
                                        "Busog na ang tiyan. Handa nang kumilos.",
                                        "Natapos na ang pagkain.",
                                        "Naubos na. Maayos na para magpatuloy.",
                                        "Tapos na. Mas masarap kaysa inasahan ko.",
                                        "Kumpleto na ang pagkain.",
                                        "Tapos nang kumain. Balik sa trabaho.",
                                        "Naubos ang rasyon. Nagbalik ang lakas.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "task.eat",
            ["textRoles"] = {
                {
                    ["fallback"] = "Finished eating. Feeling much better.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.task.eat.completed.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Finished eating. Feeling much better.",
                            "That food helped a lot. Done.",
                            "Done eating. Energy restored.",
                            "Stomach is full. Ready to move.",
                            "Finished that meal.",
                            "All eaten. Good to keep going.",
                            "Done. That tasted better than expected.",
                            "Meal completed.",
                            "Finished eating. Back on task.",
                            "Rations finished. Strength is back.",
                        },
                        ["TL"] = {
                            "Tapos nang kumain. Mas maayos na ang pakiramdam.",
                            "Nakatulong nang malaki ang pagkain. Tapos na.",
                            "Tapos nang kumain. Bumalik na ang lakas.",
                            "Busog na ang tiyan. Handa nang kumilos.",
                            "Natapos na ang pagkain.",
                            "Naubos na. Maayos na para magpatuloy.",
                            "Tapos na. Mas masarap kaysa inasahan ko.",
                            "Kumpleto na ang pagkain.",
                            "Tapos nang kumain. Balik sa trabaho.",
                            "Naubos ang rasyon. Nagbalik ang lakas.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "task.eat.completed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "completed",
            ["sourceId"] = "task.eat.completed",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_eat_completed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
        ["namespace"] = "task.eat",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/eat.json",
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
                                        "Finished eating. Feeling much better.",
                                        "That food helped a lot. Done.",
                                        "Done eating. Energy restored.",
                                        "Stomach is full. Ready to move.",
                                        "Finished that meal.",
                                        "All eaten. Good to keep going.",
                                        "Done. That tasted better than expected.",
                                        "Meal completed.",
                                        "Finished eating. Back on task.",
                                        "Rations finished. Strength is back.",
                                    },
                                    ["TL"] = {
                                        "Tapos nang kumain. Mas maayos na ang pakiramdam.",
                                        "Nakatulong nang malaki ang pagkain. Tapos na.",
                                        "Tapos nang kumain. Bumalik na ang lakas.",
                                        "Busog na ang tiyan. Handa nang kumilos.",
                                        "Natapos na ang pagkain.",
                                        "Naubos na. Maayos na para magpatuloy.",
                                        "Tapos na. Mas masarap kaysa inasahan ko.",
                                        "Kumpleto na ang pagkain.",
                                        "Tapos nang kumain. Balik sa trabaho.",
                                        "Naubos ang rasyon. Nagbalik ang lakas.",
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
            ["responsePlanID"] = "task.eat.completed",
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
                            ["fallback"] = "Finished eating. Feeling much better.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.task.eat.completed.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_eat_completed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Finished eating. Feeling much better.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.task.eat.completed.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Finished eating. Feeling much better.",
                        "That food helped a lot. Done.",
                        "Done eating. Energy restored.",
                        "Stomach is full. Ready to move.",
                        "Finished that meal.",
                        "All eaten. Good to keep going.",
                        "Done. That tasted better than expected.",
                        "Meal completed.",
                        "Finished eating. Back on task.",
                        "Rations finished. Strength is back.",
                    },
                    ["TL"] = {
                        "Tapos nang kumain. Mas maayos na ang pakiramdam.",
                        "Nakatulong nang malaki ang pagkain. Tapos na.",
                        "Tapos nang kumain. Bumalik na ang lakas.",
                        "Busog na ang tiyan. Handa nang kumilos.",
                        "Natapos na ang pagkain.",
                        "Naubos na. Maayos na para magpatuloy.",
                        "Tapos na. Mas masarap kaysa inasahan ko.",
                        "Kumpleto na ang pagkain.",
                        "Tapos nang kumain. Balik sa trabaho.",
                        "Naubos ang rasyon. Nagbalik ang lakas.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
