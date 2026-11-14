-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "medical_event_teammate",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress.teammate.default",
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
                                ["fallback"] = "They are hurt! Stay with them while I cover you.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.medical.distress.teammate.default.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "They are hurt! Stay with them while I cover you.",
                                        "Our companion is down! Tend to them, I've got guard.",
                                        "They're injured! Get them patched up while I watch.",
                                        "Check on them right now! I'll hold off the threats.",
                                        "They took a hit! See to their wounds, I'm watching.",
                                        "Partner is wounded! Apply first aid, I've got your back.",
                                        "They're bleeding! Patch them while I keep perimeter.",
                                        "Help them up! I'll keep the lane clear.",
                                        "They need attention! Administer aid, I'll protect you both.",
                                        "Our friend is hurt! Help them, I'm standing sentry.",
                                    },
                                    ["TL"] = {
                                        "Nasaktan sila! Samahan mo sila habang binabantayan ko kayo.",
                                        "Bagsak ang kasama natin! Gamutin mo, babantayan ko kayo.",
                                        "Sugatan sila! Bendahan mo habang nagmamasid ako.",
                                        "Tignan mo sila ngayon din! Haharangin ko ang mga kalaban.",
                                        "Tinamaan sila! Tingnan mo ang sugat nila, nakabantay ako.",
                                        "Sugatan ang kasama! Maglapat ng first aid, hawak ko likod niyo.",
                                        "Dumurugo sila! Gamutin mo habang binabantayan ko ang paligid.",
                                        "Tulungan mo silang tumayo! Lilinisin ko ang daanan.",
                                        "Kailangan nila ng lunas! Gamutin mo, poprotektahan ko kayong dalawa.",
                                        "Nasaktan ang kaibigan natin! Tulungan mo sila, nakabantay ako.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.distress.teammate",
            ["textRoles"] = {
                {
                    ["fallback"] = "They are hurt! Stay with them while I cover you.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.teammate.default.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "They are hurt! Stay with them while I cover you.",
                            "Our companion is down! Tend to them, I've got guard.",
                            "They're injured! Get them patched up while I watch.",
                            "Check on them right now! I'll hold off the threats.",
                            "They took a hit! See to their wounds, I'm watching.",
                            "Partner is wounded! Apply first aid, I've got your back.",
                            "They're bleeding! Patch them while I keep perimeter.",
                            "Help them up! I'll keep the lane clear.",
                            "They need attention! Administer aid, I'll protect you both.",
                            "Our friend is hurt! Help them, I'm standing sentry.",
                        },
                        ["TL"] = {
                            "Nasaktan sila! Samahan mo sila habang binabantayan ko kayo.",
                            "Bagsak ang kasama natin! Gamutin mo, babantayan ko kayo.",
                            "Sugatan sila! Bendahan mo habang nagmamasid ako.",
                            "Tignan mo sila ngayon din! Haharangin ko ang mga kalaban.",
                            "Tinamaan sila! Tingnan mo ang sugat nila, nakabantay ako.",
                            "Sugatan ang kasama! Maglapat ng first aid, hawak ko likod niyo.",
                            "Dumurugo sila! Gamutin mo habang binabantayan ko ang paligid.",
                            "Tulungan mo silang tumayo! Lilinisin ko ang daanan.",
                            "Kailangan nila ng lunas! Gamutin mo, poprotektahan ko kayong dalawa.",
                            "Nasaktan ang kaibigan natin! Tulungan mo sila, nakabantay ako.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "medical.distress.teammate.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "default",
            ["sourceId"] = "medical.distress.teammate.default",
            ["sourcePath"] = "adopters/hoomans/dialogue/medical_event_teammate/medical_distress_teammate_default.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalEventTeammate",
        ["namespace"] = "medical.distress.teammate",
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
                ["category"] = "projecthoomans:medical_event",
                ["responseAct"] = "MEDICAL_RESPONSE",
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
                                        "They are hurt! Stay with them while I cover you.",
                                        "Our companion is down! Tend to them, I've got guard.",
                                        "They're injured! Get them patched up while I watch.",
                                        "Check on them right now! I'll hold off the threats.",
                                        "They took a hit! See to their wounds, I'm watching.",
                                        "Partner is wounded! Apply first aid, I've got your back.",
                                        "They're bleeding! Patch them while I keep perimeter.",
                                        "Help them up! I'll keep the lane clear.",
                                        "They need attention! Administer aid, I'll protect you both.",
                                        "Our friend is hurt! Help them, I'm standing sentry.",
                                    },
                                    ["TL"] = {
                                        "Nasaktan sila! Samahan mo sila habang binabantayan ko kayo.",
                                        "Bagsak ang kasama natin! Gamutin mo, babantayan ko kayo.",
                                        "Sugatan sila! Bendahan mo habang nagmamasid ako.",
                                        "Tignan mo sila ngayon din! Haharangin ko ang mga kalaban.",
                                        "Tinamaan sila! Tingnan mo ang sugat nila, nakabantay ako.",
                                        "Sugatan ang kasama! Maglapat ng first aid, hawak ko likod niyo.",
                                        "Dumurugo sila! Gamutin mo habang binabantayan ko ang paligid.",
                                        "Tulungan mo silang tumayo! Lilinisin ko ang daanan.",
                                        "Kailangan nila ng lunas! Gamutin mo, poprotektahan ko kayong dalawa.",
                                        "Nasaktan ang kaibigan natin! Tulungan mo sila, nakabantay ako.",
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
            ["dialogueAct"] = "MEDICAL_RESPONSE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "medical.distress.teammate.default",
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
                            ["fallback"] = "They are hurt! Stay with them while I cover you.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.medical.distress.teammate.default.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/medical_event_teammate/medical_distress_teammate_default.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "They are hurt! Stay with them while I cover you.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.teammate.default.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "They are hurt! Stay with them while I cover you.",
                        "Our companion is down! Tend to them, I've got guard.",
                        "They're injured! Get them patched up while I watch.",
                        "Check on them right now! I'll hold off the threats.",
                        "They took a hit! See to their wounds, I'm watching.",
                        "Partner is wounded! Apply first aid, I've got your back.",
                        "They're bleeding! Patch them while I keep perimeter.",
                        "Help them up! I'll keep the lane clear.",
                        "They need attention! Administer aid, I'll protect you both.",
                        "Our friend is hurt! Help them, I'm standing sentry.",
                    },
                    ["TL"] = {
                        "Nasaktan sila! Samahan mo sila habang binabantayan ko kayo.",
                        "Bagsak ang kasama natin! Gamutin mo, babantayan ko kayo.",
                        "Sugatan sila! Bendahan mo habang nagmamasid ako.",
                        "Tignan mo sila ngayon din! Haharangin ko ang mga kalaban.",
                        "Tinamaan sila! Tingnan mo ang sugat nila, nakabantay ako.",
                        "Sugatan ang kasama! Maglapat ng first aid, hawak ko likod niyo.",
                        "Dumurugo sila! Gamutin mo habang binabantayan ko ang paligid.",
                        "Tulungan mo silang tumayo! Lilinisin ko ang daanan.",
                        "Kailangan nila ng lunas! Gamutin mo, poprotektahan ko kayong dalawa.",
                        "Nasaktan ang kaibigan natin! Tulungan mo sila, nakabantay ako.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_teammate",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress.teammate.found",
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
                                ["fallback"] = "I found a bandage for them. Hold still while I patch them up.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.medical.distress.teammate.found.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I found a bandage for them. Hold still while I patch them up.",
                                        "Got a dressing right here. Wrapping the wound now.",
                                        "Found medical supplies! Hold on, I'm dressing the injury.",
                                        "I've got clean cloth. Hold steady while I bind it.",
                                        "Located a bandage. Applying pressure to their cut now.",
                                        "I've got medical wrap. Don't squirm, I'm securing it.",
                                        "Found supplies for them. Wrapping it up tightly now.",
                                        "Got the bandage ready. Applying it to the laceration.",
                                        "I have aid gear. Hold still, you'll be stable in a minute.",
                                        "Bandage in hand! Dressing their wounds right now.",
                                    },
                                    ["TL"] = {
                                        "Nakahanap ako ng benda para sa kanila. Huwag kang gagalaw habang ginagamot ko sila.",
                                        "May pambenda ako rito. Binabalot ko na ang sugat ngayon.",
                                        "Nakahanap ako ng gamot! Kapit lang, ginagamot ko na ang pinsala.",
                                        "May malinis akong tela. Manatiling nakapirmi habang itinatali ko.",
                                        "May nahanap na benda. Dinidiinan ko na ang hiwa nila.",
                                        "May medical wrap ako. Huwag kang pumalag, inaayos ko na.",
                                        "May nahanap na gamit para sa kanila. Binabalot ko na nang mahigpit.",
                                        "Handa na ang benda. Nilalapat ko na sa sugat.",
                                        "May gamit ako rito. Huwag gagalaw, magiging maayos ka rin agad.",
                                        "Hawak ko na ang benda! Ginagamot ko na ang mga sugat nila.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.distress.teammate",
            ["textRoles"] = {
                {
                    ["fallback"] = "I found a bandage for them. Hold still while I patch them up.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.teammate.found.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I found a bandage for them. Hold still while I patch them up.",
                            "Got a dressing right here. Wrapping the wound now.",
                            "Found medical supplies! Hold on, I'm dressing the injury.",
                            "I've got clean cloth. Hold steady while I bind it.",
                            "Located a bandage. Applying pressure to their cut now.",
                            "I've got medical wrap. Don't squirm, I'm securing it.",
                            "Found supplies for them. Wrapping it up tightly now.",
                            "Got the bandage ready. Applying it to the laceration.",
                            "I have aid gear. Hold still, you'll be stable in a minute.",
                            "Bandage in hand! Dressing their wounds right now.",
                        },
                        ["TL"] = {
                            "Nakahanap ako ng benda para sa kanila. Huwag kang gagalaw habang ginagamot ko sila.",
                            "May pambenda ako rito. Binabalot ko na ang sugat ngayon.",
                            "Nakahanap ako ng gamot! Kapit lang, ginagamot ko na ang pinsala.",
                            "May malinis akong tela. Manatiling nakapirmi habang itinatali ko.",
                            "May nahanap na benda. Dinidiinan ko na ang hiwa nila.",
                            "May medical wrap ako. Huwag kang pumalag, inaayos ko na.",
                            "May nahanap na gamit para sa kanila. Binabalot ko na nang mahigpit.",
                            "Handa na ang benda. Nilalapat ko na sa sugat.",
                            "May gamit ako rito. Huwag gagalaw, magiging maayos ka rin agad.",
                            "Hawak ko na ang benda! Ginagamot ko na ang mga sugat nila.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "medical.distress.teammate.found",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "found",
            ["sourceId"] = "medical.distress.teammate.found",
            ["sourcePath"] = "adopters/hoomans/dialogue/medical_event_teammate/medical_distress_teammate_found.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalEventTeammate",
        ["namespace"] = "medical.distress.teammate",
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
                ["category"] = "projecthoomans:medical_event",
                ["responseAct"] = "MEDICAL_RESPONSE",
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
                                        "I found a bandage for them. Hold still while I patch them up.",
                                        "Got a dressing right here. Wrapping the wound now.",
                                        "Found medical supplies! Hold on, I'm dressing the injury.",
                                        "I've got clean cloth. Hold steady while I bind it.",
                                        "Located a bandage. Applying pressure to their cut now.",
                                        "I've got medical wrap. Don't squirm, I'm securing it.",
                                        "Found supplies for them. Wrapping it up tightly now.",
                                        "Got the bandage ready. Applying it to the laceration.",
                                        "I have aid gear. Hold still, you'll be stable in a minute.",
                                        "Bandage in hand! Dressing their wounds right now.",
                                    },
                                    ["TL"] = {
                                        "Nakahanap ako ng benda para sa kanila. Huwag kang gagalaw habang ginagamot ko sila.",
                                        "May pambenda ako rito. Binabalot ko na ang sugat ngayon.",
                                        "Nakahanap ako ng gamot! Kapit lang, ginagamot ko na ang pinsala.",
                                        "May malinis akong tela. Manatiling nakapirmi habang itinatali ko.",
                                        "May nahanap na benda. Dinidiinan ko na ang hiwa nila.",
                                        "May medical wrap ako. Huwag kang pumalag, inaayos ko na.",
                                        "May nahanap na gamit para sa kanila. Binabalot ko na nang mahigpit.",
                                        "Handa na ang benda. Nilalapat ko na sa sugat.",
                                        "May gamit ako rito. Huwag gagalaw, magiging maayos ka rin agad.",
                                        "Hawak ko na ang benda! Ginagamot ko na ang mga sugat nila.",
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
            ["dialogueAct"] = "MEDICAL_RESPONSE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "medical.distress.teammate.found",
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
                            ["fallback"] = "I found a bandage for them. Hold still while I patch them up.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.medical.distress.teammate.found.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/medical_event_teammate/medical_distress_teammate_found.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I found a bandage for them. Hold still while I patch them up.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.teammate.found.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I found a bandage for them. Hold still while I patch them up.",
                        "Got a dressing right here. Wrapping the wound now.",
                        "Found medical supplies! Hold on, I'm dressing the injury.",
                        "I've got clean cloth. Hold steady while I bind it.",
                        "Located a bandage. Applying pressure to their cut now.",
                        "I've got medical wrap. Don't squirm, I'm securing it.",
                        "Found supplies for them. Wrapping it up tightly now.",
                        "Got the bandage ready. Applying it to the laceration.",
                        "I have aid gear. Hold still, you'll be stable in a minute.",
                        "Bandage in hand! Dressing their wounds right now.",
                    },
                    ["TL"] = {
                        "Nakahanap ako ng benda para sa kanila. Huwag kang gagalaw habang ginagamot ko sila.",
                        "May pambenda ako rito. Binabalot ko na ang sugat ngayon.",
                        "Nakahanap ako ng gamot! Kapit lang, ginagamot ko na ang pinsala.",
                        "May malinis akong tela. Manatiling nakapirmi habang itinatali ko.",
                        "May nahanap na benda. Dinidiinan ko na ang hiwa nila.",
                        "May medical wrap ako. Huwag kang pumalag, inaayos ko na.",
                        "May nahanap na gamit para sa kanila. Binabalot ko na nang mahigpit.",
                        "Handa na ang benda. Nilalapat ko na sa sugat.",
                        "May gamit ako rito. Huwag gagalaw, magiging maayos ka rin agad.",
                        "Hawak ko na ang benda! Ginagamot ko na ang mga sugat nila.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_teammate",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress.teammate.missing",
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
                                ["fallback"] = "I am out of bandages! Can someone spare one for them?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.medical.distress.teammate.missing.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I am out of bandages! Can someone spare one for them?",
                                        "No more medical cloth! Does anyone have a bandage?!",
                                        "My pack is empty of dressings! Help them, quick!",
                                        "I can't treat this wound without supplies! Check your packs!",
                                        "We're out of first aid! Who has a clean rag?!",
                                        "I don't have what I need to stop their bleeding! Find supplies!",
                                        "Zero bandages left! Someone hand me medical gear!",
                                        "I'm empty-handed! We need bandages for our friend now!",
                                        "No antiseptic, no bandages. Search the drawers, fast!",
                                        "I can't patch them up alone! Who has medical tools?!",
                                    },
                                    ["TL"] = {
                                        "Naubusan ako ng benda! May makakapagbahagi ba ng isa para sa kanila?",
                                        "Wala nang telang panggamot! May benda ba ang kahit sino sa inyo?!",
                                        "Walang laman ang bag ko para sa benda! Tulungan niyo sila, bilis!",
                                        "Hindi ko magagamot ang sugat na 'to nang walang gamit! Tignan ang mga bag niyo!",
                                        "Wala na tayong first aid! Sino may malinis na basahan?!",
                                        "Wala sa akin ang kailangan para mapatigil ang dugo nila! Maghanap ng gamit!",
                                        "Ubos na ang benda! May mag-abot sa akin ng panggamot!",
                                        "Wala akong hawak! Kailangan natin ng benda para sa kaibigan natin ngayon din!",
                                        "Walang antiseptic, walang benda. Maghalughog sa mga drawer, bilis!",
                                        "Hindi ko sila kayang gamutin mag-isa! Sino may kagamitang medikal?!",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.distress.teammate",
            ["textRoles"] = {
                {
                    ["fallback"] = "I am out of bandages! Can someone spare one for them?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.teammate.missing.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I am out of bandages! Can someone spare one for them?",
                            "No more medical cloth! Does anyone have a bandage?!",
                            "My pack is empty of dressings! Help them, quick!",
                            "I can't treat this wound without supplies! Check your packs!",
                            "We're out of first aid! Who has a clean rag?!",
                            "I don't have what I need to stop their bleeding! Find supplies!",
                            "Zero bandages left! Someone hand me medical gear!",
                            "I'm empty-handed! We need bandages for our friend now!",
                            "No antiseptic, no bandages. Search the drawers, fast!",
                            "I can't patch them up alone! Who has medical tools?!",
                        },
                        ["TL"] = {
                            "Naubusan ako ng benda! May makakapagbahagi ba ng isa para sa kanila?",
                            "Wala nang telang panggamot! May benda ba ang kahit sino sa inyo?!",
                            "Walang laman ang bag ko para sa benda! Tulungan niyo sila, bilis!",
                            "Hindi ko magagamot ang sugat na 'to nang walang gamit! Tignan ang mga bag niyo!",
                            "Wala na tayong first aid! Sino may malinis na basahan?!",
                            "Wala sa akin ang kailangan para mapatigil ang dugo nila! Maghanap ng gamit!",
                            "Ubos na ang benda! May mag-abot sa akin ng panggamot!",
                            "Wala akong hawak! Kailangan natin ng benda para sa kaibigan natin ngayon din!",
                            "Walang antiseptic, walang benda. Maghalughog sa mga drawer, bilis!",
                            "Hindi ko sila kayang gamutin mag-isa! Sino may kagamitang medikal?!",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "medical.distress.teammate.missing",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "missing",
            ["sourceId"] = "medical.distress.teammate.missing",
            ["sourcePath"] = "adopters/hoomans/dialogue/medical_event_teammate/medical_distress_teammate_missing.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalEventTeammate",
        ["namespace"] = "medical.distress.teammate",
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
                ["category"] = "projecthoomans:medical_event",
                ["responseAct"] = "MEDICAL_RESPONSE",
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
                                        "I am out of bandages! Can someone spare one for them?",
                                        "No more medical cloth! Does anyone have a bandage?!",
                                        "My pack is empty of dressings! Help them, quick!",
                                        "I can't treat this wound without supplies! Check your packs!",
                                        "We're out of first aid! Who has a clean rag?!",
                                        "I don't have what I need to stop their bleeding! Find supplies!",
                                        "Zero bandages left! Someone hand me medical gear!",
                                        "I'm empty-handed! We need bandages for our friend now!",
                                        "No antiseptic, no bandages. Search the drawers, fast!",
                                        "I can't patch them up alone! Who has medical tools?!",
                                    },
                                    ["TL"] = {
                                        "Naubusan ako ng benda! May makakapagbahagi ba ng isa para sa kanila?",
                                        "Wala nang telang panggamot! May benda ba ang kahit sino sa inyo?!",
                                        "Walang laman ang bag ko para sa benda! Tulungan niyo sila, bilis!",
                                        "Hindi ko magagamot ang sugat na 'to nang walang gamit! Tignan ang mga bag niyo!",
                                        "Wala na tayong first aid! Sino may malinis na basahan?!",
                                        "Wala sa akin ang kailangan para mapatigil ang dugo nila! Maghanap ng gamit!",
                                        "Ubos na ang benda! May mag-abot sa akin ng panggamot!",
                                        "Wala akong hawak! Kailangan natin ng benda para sa kaibigan natin ngayon din!",
                                        "Walang antiseptic, walang benda. Maghalughog sa mga drawer, bilis!",
                                        "Hindi ko sila kayang gamutin mag-isa! Sino may kagamitang medikal?!",
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
            ["dialogueAct"] = "MEDICAL_RESPONSE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "medical.distress.teammate.missing",
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
                            ["fallback"] = "I am out of bandages! Can someone spare one for them?",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.medical.distress.teammate.missing.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/medical_event_teammate/medical_distress_teammate_missing.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I am out of bandages! Can someone spare one for them?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.teammate.missing.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I am out of bandages! Can someone spare one for them?",
                        "No more medical cloth! Does anyone have a bandage?!",
                        "My pack is empty of dressings! Help them, quick!",
                        "I can't treat this wound without supplies! Check your packs!",
                        "We're out of first aid! Who has a clean rag?!",
                        "I don't have what I need to stop their bleeding! Find supplies!",
                        "Zero bandages left! Someone hand me medical gear!",
                        "I'm empty-handed! We need bandages for our friend now!",
                        "No antiseptic, no bandages. Search the drawers, fast!",
                        "I can't patch them up alone! Who has medical tools?!",
                    },
                    ["TL"] = {
                        "Naubusan ako ng benda! May makakapagbahagi ba ng isa para sa kanila?",
                        "Wala nang telang panggamot! May benda ba ang kahit sino sa inyo?!",
                        "Walang laman ang bag ko para sa benda! Tulungan niyo sila, bilis!",
                        "Hindi ko magagamot ang sugat na 'to nang walang gamit! Tignan ang mga bag niyo!",
                        "Wala na tayong first aid! Sino may malinis na basahan?!",
                        "Wala sa akin ang kailangan para mapatigil ang dugo nila! Maghanap ng gamit!",
                        "Ubos na ang benda! May mag-abot sa akin ng panggamot!",
                        "Wala akong hawak! Kailangan natin ng benda para sa kaibigan natin ngayon din!",
                        "Walang antiseptic, walang benda. Maghalughog sa mga drawer, bilis!",
                        "Hindi ko sila kayang gamutin mag-isa! Sino may kagamitang medikal?!",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
