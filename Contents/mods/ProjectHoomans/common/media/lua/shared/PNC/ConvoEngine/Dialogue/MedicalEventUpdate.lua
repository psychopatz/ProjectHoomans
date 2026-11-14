-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "medical_event_update",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress.update.bandage",
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
                                ["fallback"] = "I am still down and waiting for a patch.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.medical.distress.update.bandage.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I am still down and waiting for a patch.",
                                        "Still on the floor. Where is that bandage?",
                                        "Wound is still unbandaged. Need it wrapped soon.",
                                        "Still waiting for someone to bind this cut.",
                                        "Blood is still seeping through. Need that wrap.",
                                        "Still grounded until these wounds get dressed.",
                                        "Waiting on clean cloth. Can't stand like this.",
                                        "Still down here waiting for first aid.",
                                        "Unpatched and bleeding. Please hurry.",
                                        "Still need that dressing applied. Don't delay.",
                                    },
                                    ["TL"] = {
                                        "Nasa sahig pa rin ako at naghihintay ng benda.",
                                        "Nasa sahig pa rin. Nasaan na 'yung benda?",
                                        "Wala pa ring benda ang sugat. Kailangang balutin na agad.",
                                        "Naghihintay pa rin ng magtatali sa hiwang 'to.",
                                        "Tumutulo pa rin ang dugo. Kailangan ko ng pambalot.",
                                        "Bagsak pa rin hangga't hindi nagagamot ang mga sugat na 'to.",
                                        "Naghihintay ng malinis na tela. Hindi makatayo nang ganito.",
                                        "Nandito pa rin sa sahig at naghihintay ng first aid.",
                                        "Walang benda at dumurugo. Pakiusap bilisan mo.",
                                        "Kailangan pa ring ilapat ang pambenda. Huwag patagalin.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.distress.update",
            ["textRoles"] = {
                {
                    ["fallback"] = "I am still down and waiting for a patch.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.update.bandage.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I am still down and waiting for a patch.",
                            "Still on the floor. Where is that bandage?",
                            "Wound is still unbandaged. Need it wrapped soon.",
                            "Still waiting for someone to bind this cut.",
                            "Blood is still seeping through. Need that wrap.",
                            "Still grounded until these wounds get dressed.",
                            "Waiting on clean cloth. Can't stand like this.",
                            "Still down here waiting for first aid.",
                            "Unpatched and bleeding. Please hurry.",
                            "Still need that dressing applied. Don't delay.",
                        },
                        ["TL"] = {
                            "Nasa sahig pa rin ako at naghihintay ng benda.",
                            "Nasa sahig pa rin. Nasaan na 'yung benda?",
                            "Wala pa ring benda ang sugat. Kailangang balutin na agad.",
                            "Naghihintay pa rin ng magtatali sa hiwang 'to.",
                            "Tumutulo pa rin ang dugo. Kailangan ko ng pambalot.",
                            "Bagsak pa rin hangga't hindi nagagamot ang mga sugat na 'to.",
                            "Naghihintay ng malinis na tela. Hindi makatayo nang ganito.",
                            "Nandito pa rin sa sahig at naghihintay ng first aid.",
                            "Walang benda at dumurugo. Pakiusap bilisan mo.",
                            "Kailangan pa ring ilapat ang pambenda. Huwag patagalin.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "medical.distress.update.bandage",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "bandage",
            ["sourceId"] = "medical.distress.update.bandage",
            ["sourcePath"] = "adopters/hoomans/dialogue/medical_event_update/medical_distress_update_bandage.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalEventUpdate",
        ["namespace"] = "medical.distress.update",
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
                                        "I am still down and waiting for a patch.",
                                        "Still on the floor. Where is that bandage?",
                                        "Wound is still unbandaged. Need it wrapped soon.",
                                        "Still waiting for someone to bind this cut.",
                                        "Blood is still seeping through. Need that wrap.",
                                        "Still grounded until these wounds get dressed.",
                                        "Waiting on clean cloth. Can't stand like this.",
                                        "Still down here waiting for first aid.",
                                        "Unpatched and bleeding. Please hurry.",
                                        "Still need that dressing applied. Don't delay.",
                                    },
                                    ["TL"] = {
                                        "Nasa sahig pa rin ako at naghihintay ng benda.",
                                        "Nasa sahig pa rin. Nasaan na 'yung benda?",
                                        "Wala pa ring benda ang sugat. Kailangang balutin na agad.",
                                        "Naghihintay pa rin ng magtatali sa hiwang 'to.",
                                        "Tumutulo pa rin ang dugo. Kailangan ko ng pambalot.",
                                        "Bagsak pa rin hangga't hindi nagagamot ang mga sugat na 'to.",
                                        "Naghihintay ng malinis na tela. Hindi makatayo nang ganito.",
                                        "Nandito pa rin sa sahig at naghihintay ng first aid.",
                                        "Walang benda at dumurugo. Pakiusap bilisan mo.",
                                        "Kailangan pa ring ilapat ang pambenda. Huwag patagalin.",
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
            ["responsePlanID"] = "medical.distress.update.bandage",
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
                            ["fallback"] = "I am still down and waiting for a patch.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.medical.distress.update.bandage.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/medical_event_update/medical_distress_update_bandage.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I am still down and waiting for a patch.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.update.bandage.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I am still down and waiting for a patch.",
                        "Still on the floor. Where is that bandage?",
                        "Wound is still unbandaged. Need it wrapped soon.",
                        "Still waiting for someone to bind this cut.",
                        "Blood is still seeping through. Need that wrap.",
                        "Still grounded until these wounds get dressed.",
                        "Waiting on clean cloth. Can't stand like this.",
                        "Still down here waiting for first aid.",
                        "Unpatched and bleeding. Please hurry.",
                        "Still need that dressing applied. Don't delay.",
                    },
                    ["TL"] = {
                        "Nasa sahig pa rin ako at naghihintay ng benda.",
                        "Nasa sahig pa rin. Nasaan na 'yung benda?",
                        "Wala pa ring benda ang sugat. Kailangang balutin na agad.",
                        "Naghihintay pa rin ng magtatali sa hiwang 'to.",
                        "Tumutulo pa rin ang dugo. Kailangan ko ng pambalot.",
                        "Bagsak pa rin hangga't hindi nagagamot ang mga sugat na 'to.",
                        "Naghihintay ng malinis na tela. Hindi makatayo nang ganito.",
                        "Nandito pa rin sa sahig at naghihintay ng first aid.",
                        "Walang benda at dumurugo. Pakiusap bilisan mo.",
                        "Kailangan pa ring ilapat ang pambenda. Huwag patagalin.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_update",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress.update.bleedout",
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
                                ["fallback"] = "The bleeding has not stopped. I still need a bandage.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.medical.distress.update.bleedout.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "The bleeding has not stopped. I still need a bandage.",
                                        "Still hemorrhaging. I need pressure and a wrap immediately.",
                                        "Bleeding is continuing. I'm getting lightheaded.",
                                        "Blood is still flowing. Please get that bandage on me.",
                                        "Hasn't stopped bleeding yet. Running out of time.",
                                        "Still losing red. My clothes are soaked.",
                                        "The wound won't seal itself. Need a dressing now.",
                                        "Still bleeding steadily. Hurry up with the aid.",
                                        "Losing blood by the second. Please hurry.",
                                        "The cut won't stop bleeding. Wrap it, please.",
                                    },
                                    ["TL"] = {
                                        "Hindi pa tumitigil ang dugo. Kailangan ko pa rin ng benda.",
                                        "Patuloy pa ring umaagos ang dugo. Kailangan ng diin at benda agad.",
                                        "Dumurugo pa rin. Nahihilo na ako.",
                                        "Umaagos pa rin ang dugo. Pakiusap lagyan mo na ako ng benda.",
                                        "Hindi pa rin humihinto ang pagdurugo. Nauubusan na ako ng oras.",
                                        "Nauubusan pa rin ng dugo. Babad na ang damit ko.",
                                        "Hindi kusang magsasara ang sugat. Kailangan ng benda ngayon din.",
                                        "Tuloy-tuloy pa rin ang pagdurugo. Bilisan mo ang tulong.",
                                        "Bawat segundo nauubusan ako ng dugo. Pakiusap magmadali ka.",
                                        "Ayaw tumigil ng pagdurugo ng hiwa. Balutin mo na, pakiusap.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.distress.update",
            ["textRoles"] = {
                {
                    ["fallback"] = "The bleeding has not stopped. I still need a bandage.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.update.bleedout.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "The bleeding has not stopped. I still need a bandage.",
                            "Still hemorrhaging. I need pressure and a wrap immediately.",
                            "Bleeding is continuing. I'm getting lightheaded.",
                            "Blood is still flowing. Please get that bandage on me.",
                            "Hasn't stopped bleeding yet. Running out of time.",
                            "Still losing red. My clothes are soaked.",
                            "The wound won't seal itself. Need a dressing now.",
                            "Still bleeding steadily. Hurry up with the aid.",
                            "Losing blood by the second. Please hurry.",
                            "The cut won't stop bleeding. Wrap it, please.",
                        },
                        ["TL"] = {
                            "Hindi pa tumitigil ang dugo. Kailangan ko pa rin ng benda.",
                            "Patuloy pa ring umaagos ang dugo. Kailangan ng diin at benda agad.",
                            "Dumurugo pa rin. Nahihilo na ako.",
                            "Umaagos pa rin ang dugo. Pakiusap lagyan mo na ako ng benda.",
                            "Hindi pa rin humihinto ang pagdurugo. Nauubusan na ako ng oras.",
                            "Nauubusan pa rin ng dugo. Babad na ang damit ko.",
                            "Hindi kusang magsasara ang sugat. Kailangan ng benda ngayon din.",
                            "Tuloy-tuloy pa rin ang pagdurugo. Bilisan mo ang tulong.",
                            "Bawat segundo nauubusan ako ng dugo. Pakiusap magmadali ka.",
                            "Ayaw tumigil ng pagdurugo ng hiwa. Balutin mo na, pakiusap.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "medical.distress.update.bleedout",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "bleedout",
            ["sourceId"] = "medical.distress.update.bleedout",
            ["sourcePath"] = "adopters/hoomans/dialogue/medical_event_update/medical_distress_update_bleedout.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalEventUpdate",
        ["namespace"] = "medical.distress.update",
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
                                        "The bleeding has not stopped. I still need a bandage.",
                                        "Still hemorrhaging. I need pressure and a wrap immediately.",
                                        "Bleeding is continuing. I'm getting lightheaded.",
                                        "Blood is still flowing. Please get that bandage on me.",
                                        "Hasn't stopped bleeding yet. Running out of time.",
                                        "Still losing red. My clothes are soaked.",
                                        "The wound won't seal itself. Need a dressing now.",
                                        "Still bleeding steadily. Hurry up with the aid.",
                                        "Losing blood by the second. Please hurry.",
                                        "The cut won't stop bleeding. Wrap it, please.",
                                    },
                                    ["TL"] = {
                                        "Hindi pa tumitigil ang dugo. Kailangan ko pa rin ng benda.",
                                        "Patuloy pa ring umaagos ang dugo. Kailangan ng diin at benda agad.",
                                        "Dumurugo pa rin. Nahihilo na ako.",
                                        "Umaagos pa rin ang dugo. Pakiusap lagyan mo na ako ng benda.",
                                        "Hindi pa rin humihinto ang pagdurugo. Nauubusan na ako ng oras.",
                                        "Nauubusan pa rin ng dugo. Babad na ang damit ko.",
                                        "Hindi kusang magsasara ang sugat. Kailangan ng benda ngayon din.",
                                        "Tuloy-tuloy pa rin ang pagdurugo. Bilisan mo ang tulong.",
                                        "Bawat segundo nauubusan ako ng dugo. Pakiusap magmadali ka.",
                                        "Ayaw tumigil ng pagdurugo ng hiwa. Balutin mo na, pakiusap.",
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
            ["responsePlanID"] = "medical.distress.update.bleedout",
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
                            ["fallback"] = "The bleeding has not stopped. I still need a bandage.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.medical.distress.update.bleedout.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/medical_event_update/medical_distress_update_bleedout.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "The bleeding has not stopped. I still need a bandage.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.update.bleedout.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "The bleeding has not stopped. I still need a bandage.",
                        "Still hemorrhaging. I need pressure and a wrap immediately.",
                        "Bleeding is continuing. I'm getting lightheaded.",
                        "Blood is still flowing. Please get that bandage on me.",
                        "Hasn't stopped bleeding yet. Running out of time.",
                        "Still losing red. My clothes are soaked.",
                        "The wound won't seal itself. Need a dressing now.",
                        "Still bleeding steadily. Hurry up with the aid.",
                        "Losing blood by the second. Please hurry.",
                        "The cut won't stop bleeding. Wrap it, please.",
                    },
                    ["TL"] = {
                        "Hindi pa tumitigil ang dugo. Kailangan ko pa rin ng benda.",
                        "Patuloy pa ring umaagos ang dugo. Kailangan ng diin at benda agad.",
                        "Dumurugo pa rin. Nahihilo na ako.",
                        "Umaagos pa rin ang dugo. Pakiusap lagyan mo na ako ng benda.",
                        "Hindi pa rin humihinto ang pagdurugo. Nauubusan na ako ng oras.",
                        "Nauubusan pa rin ng dugo. Babad na ang damit ko.",
                        "Hindi kusang magsasara ang sugat. Kailangan ng benda ngayon din.",
                        "Tuloy-tuloy pa rin ang pagdurugo. Bilisan mo ang tulong.",
                        "Bawat segundo nauubusan ako ng dugo. Pakiusap magmadali ka.",
                        "Ayaw tumigil ng pagdurugo ng hiwa. Balutin mo na, pakiusap.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_update",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress.update.default",
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
                                ["fallback"] = "I am still down. I still need help.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.medical.distress.update.default.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I am still down. I still need help.",
                                        "Still incapacitated on the ground. Please assist.",
                                        "Haven't recovered yet. Still need a hand.",
                                        "Still down here. Don't leave me alone.",
                                        "Status unchanged: still injured and waiting.",
                                        "Still grounded. I need someone to help me up.",
                                        "Can't move on my own yet. Still need aid.",
                                        "Still unable to stand. Waiting for help.",
                                        "I'm still down in the dirt. Please assist me.",
                                        "Still waiting for support. Don't forget me.",
                                    },
                                    ["TL"] = {
                                        "Bagsak pa rin ako. Kailangan ko pa rin ng tulong.",
                                        "Hindi pa rin makakilos sa lupa. Pakiusap tulungan mo ako.",
                                        "Hindi pa nakakabawi. Kailangan pa rin ng saklolo.",
                                        "Nandito pa rin sa sahig. Huwag mo akong iwang mag-isa.",
                                        "Walang pagbabago: sugatan pa rin at naghihintay.",
                                        "Bagsak pa rin. Kailangan ko ng tutulong sa akin makatayo.",
                                        "Hindi pa makagalaw mag-isa. Kailangan pa rin ng lunas.",
                                        "Hindi pa rin makatayo. Naghihintay ng tulong.",
                                        "Nasa lupa pa rin ako. Pakiusap saklolohan mo ako.",
                                        "Naghihintay pa rin ng suporta. Huwag mo akong kalimutan.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.distress.update",
            ["textRoles"] = {
                {
                    ["fallback"] = "I am still down. I still need help.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.update.default.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I am still down. I still need help.",
                            "Still incapacitated on the ground. Please assist.",
                            "Haven't recovered yet. Still need a hand.",
                            "Still down here. Don't leave me alone.",
                            "Status unchanged: still injured and waiting.",
                            "Still grounded. I need someone to help me up.",
                            "Can't move on my own yet. Still need aid.",
                            "Still unable to stand. Waiting for help.",
                            "I'm still down in the dirt. Please assist me.",
                            "Still waiting for support. Don't forget me.",
                        },
                        ["TL"] = {
                            "Bagsak pa rin ako. Kailangan ko pa rin ng tulong.",
                            "Hindi pa rin makakilos sa lupa. Pakiusap tulungan mo ako.",
                            "Hindi pa nakakabawi. Kailangan pa rin ng saklolo.",
                            "Nandito pa rin sa sahig. Huwag mo akong iwang mag-isa.",
                            "Walang pagbabago: sugatan pa rin at naghihintay.",
                            "Bagsak pa rin. Kailangan ko ng tutulong sa akin makatayo.",
                            "Hindi pa makagalaw mag-isa. Kailangan pa rin ng lunas.",
                            "Hindi pa rin makatayo. Naghihintay ng tulong.",
                            "Nasa lupa pa rin ako. Pakiusap saklolohan mo ako.",
                            "Naghihintay pa rin ng suporta. Huwag mo akong kalimutan.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "medical.distress.update.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "default",
            ["sourceId"] = "medical.distress.update.default",
            ["sourcePath"] = "adopters/hoomans/dialogue/medical_event_update/medical_distress_update_default.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalEventUpdate",
        ["namespace"] = "medical.distress.update",
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
                                        "I am still down. I still need help.",
                                        "Still incapacitated on the ground. Please assist.",
                                        "Haven't recovered yet. Still need a hand.",
                                        "Still down here. Don't leave me alone.",
                                        "Status unchanged: still injured and waiting.",
                                        "Still grounded. I need someone to help me up.",
                                        "Can't move on my own yet. Still need aid.",
                                        "Still unable to stand. Waiting for help.",
                                        "I'm still down in the dirt. Please assist me.",
                                        "Still waiting for support. Don't forget me.",
                                    },
                                    ["TL"] = {
                                        "Bagsak pa rin ako. Kailangan ko pa rin ng tulong.",
                                        "Hindi pa rin makakilos sa lupa. Pakiusap tulungan mo ako.",
                                        "Hindi pa nakakabawi. Kailangan pa rin ng saklolo.",
                                        "Nandito pa rin sa sahig. Huwag mo akong iwang mag-isa.",
                                        "Walang pagbabago: sugatan pa rin at naghihintay.",
                                        "Bagsak pa rin. Kailangan ko ng tutulong sa akin makatayo.",
                                        "Hindi pa makagalaw mag-isa. Kailangan pa rin ng lunas.",
                                        "Hindi pa rin makatayo. Naghihintay ng tulong.",
                                        "Nasa lupa pa rin ako. Pakiusap saklolohan mo ako.",
                                        "Naghihintay pa rin ng suporta. Huwag mo akong kalimutan.",
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
            ["responsePlanID"] = "medical.distress.update.default",
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
                            ["fallback"] = "I am still down. I still need help.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.medical.distress.update.default.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/medical_event_update/medical_distress_update_default.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I am still down. I still need help.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.update.default.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I am still down. I still need help.",
                        "Still incapacitated on the ground. Please assist.",
                        "Haven't recovered yet. Still need a hand.",
                        "Still down here. Don't leave me alone.",
                        "Status unchanged: still injured and waiting.",
                        "Still grounded. I need someone to help me up.",
                        "Can't move on my own yet. Still need aid.",
                        "Still unable to stand. Waiting for help.",
                        "I'm still down in the dirt. Please assist me.",
                        "Still waiting for support. Don't forget me.",
                    },
                    ["TL"] = {
                        "Bagsak pa rin ako. Kailangan ko pa rin ng tulong.",
                        "Hindi pa rin makakilos sa lupa. Pakiusap tulungan mo ako.",
                        "Hindi pa nakakabawi. Kailangan pa rin ng saklolo.",
                        "Nandito pa rin sa sahig. Huwag mo akong iwang mag-isa.",
                        "Walang pagbabago: sugatan pa rin at naghihintay.",
                        "Bagsak pa rin. Kailangan ko ng tutulong sa akin makatayo.",
                        "Hindi pa makagalaw mag-isa. Kailangan pa rin ng lunas.",
                        "Hindi pa rin makatayo. Naghihintay ng tulong.",
                        "Nasa lupa pa rin ako. Pakiusap saklolohan mo ako.",
                        "Naghihintay pa rin ng suporta. Huwag mo akong kalimutan.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_update",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress.update.dehydration",
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
                                ["fallback"] = "I still need water before I can move.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.medical.distress.update.dehydration.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I still need water before I can move.",
                                        "Thirst is still crippling me. Bring hydration.",
                                        "Can't stand until I drink something clean.",
                                        "Still parched and dizzy. Where is the water?",
                                        "Dehydration hasn't improved. I need fluids now.",
                                        "Still desperately thirsty. Bring a bottle over.",
                                        "Throat is still locked up dry. Need water.",
                                        "Can't make progress without hydration. Help me.",
                                        "Still waiting on that drink. Feeling very weak.",
                                        "Need fluids before my legs will work again.",
                                    },
                                    ["TL"] = {
                                        "Kailangan ko pa rin ng tubig bago makakilos.",
                                        "Pinapahirapan pa rin ako ng uhaw. Magdala ka ng tubig.",
                                        "Hindi makakatayo hangga't hindi umiinom ng malinis.",
                                        "Tuyot at nahihilo pa rin. Nasaan na ang tubig?",
                                        "Hindi pa gumagaling ang dehydration. Kailangan ko ng inumin ngayon.",
                                        "Uhaw na uhaw pa rin ako. Dalhin mo ang bote rito.",
                                        "Nakatuyot pa rin ang lalamunan ko. Kailangan ng tubig.",
                                        "Hindi makakausad nang walang tubig. Tulungan mo ako.",
                                        "Naghihintay pa rin sa inumin. Sobrang nanghihina na.",
                                        "Kailangan ng inumin bago gumana ulit ang mga binti ko.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.distress.update",
            ["textRoles"] = {
                {
                    ["fallback"] = "I still need water before I can move.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.update.dehydration.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I still need water before I can move.",
                            "Thirst is still crippling me. Bring hydration.",
                            "Can't stand until I drink something clean.",
                            "Still parched and dizzy. Where is the water?",
                            "Dehydration hasn't improved. I need fluids now.",
                            "Still desperately thirsty. Bring a bottle over.",
                            "Throat is still locked up dry. Need water.",
                            "Can't make progress without hydration. Help me.",
                            "Still waiting on that drink. Feeling very weak.",
                            "Need fluids before my legs will work again.",
                        },
                        ["TL"] = {
                            "Kailangan ko pa rin ng tubig bago makakilos.",
                            "Pinapahirapan pa rin ako ng uhaw. Magdala ka ng tubig.",
                            "Hindi makakatayo hangga't hindi umiinom ng malinis.",
                            "Tuyot at nahihilo pa rin. Nasaan na ang tubig?",
                            "Hindi pa gumagaling ang dehydration. Kailangan ko ng inumin ngayon.",
                            "Uhaw na uhaw pa rin ako. Dalhin mo ang bote rito.",
                            "Nakatuyot pa rin ang lalamunan ko. Kailangan ng tubig.",
                            "Hindi makakausad nang walang tubig. Tulungan mo ako.",
                            "Naghihintay pa rin sa inumin. Sobrang nanghihina na.",
                            "Kailangan ng inumin bago gumana ulit ang mga binti ko.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "medical.distress.update.dehydration",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "dehydration",
            ["sourceId"] = "medical.distress.update.dehydration",
            ["sourcePath"] = "adopters/hoomans/dialogue/medical_event_update/medical_distress_update_dehydration.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalEventUpdate",
        ["namespace"] = "medical.distress.update",
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
                                        "I still need water before I can move.",
                                        "Thirst is still crippling me. Bring hydration.",
                                        "Can't stand until I drink something clean.",
                                        "Still parched and dizzy. Where is the water?",
                                        "Dehydration hasn't improved. I need fluids now.",
                                        "Still desperately thirsty. Bring a bottle over.",
                                        "Throat is still locked up dry. Need water.",
                                        "Can't make progress without hydration. Help me.",
                                        "Still waiting on that drink. Feeling very weak.",
                                        "Need fluids before my legs will work again.",
                                    },
                                    ["TL"] = {
                                        "Kailangan ko pa rin ng tubig bago makakilos.",
                                        "Pinapahirapan pa rin ako ng uhaw. Magdala ka ng tubig.",
                                        "Hindi makakatayo hangga't hindi umiinom ng malinis.",
                                        "Tuyot at nahihilo pa rin. Nasaan na ang tubig?",
                                        "Hindi pa gumagaling ang dehydration. Kailangan ko ng inumin ngayon.",
                                        "Uhaw na uhaw pa rin ako. Dalhin mo ang bote rito.",
                                        "Nakatuyot pa rin ang lalamunan ko. Kailangan ng tubig.",
                                        "Hindi makakausad nang walang tubig. Tulungan mo ako.",
                                        "Naghihintay pa rin sa inumin. Sobrang nanghihina na.",
                                        "Kailangan ng inumin bago gumana ulit ang mga binti ko.",
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
            ["responsePlanID"] = "medical.distress.update.dehydration",
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
                            ["fallback"] = "I still need water before I can move.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.medical.distress.update.dehydration.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/medical_event_update/medical_distress_update_dehydration.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I still need water before I can move.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.update.dehydration.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I still need water before I can move.",
                        "Thirst is still crippling me. Bring hydration.",
                        "Can't stand until I drink something clean.",
                        "Still parched and dizzy. Where is the water?",
                        "Dehydration hasn't improved. I need fluids now.",
                        "Still desperately thirsty. Bring a bottle over.",
                        "Throat is still locked up dry. Need water.",
                        "Can't make progress without hydration. Help me.",
                        "Still waiting on that drink. Feeling very weak.",
                        "Need fluids before my legs will work again.",
                    },
                    ["TL"] = {
                        "Kailangan ko pa rin ng tubig bago makakilos.",
                        "Pinapahirapan pa rin ako ng uhaw. Magdala ka ng tubig.",
                        "Hindi makakatayo hangga't hindi umiinom ng malinis.",
                        "Tuyot at nahihilo pa rin. Nasaan na ang tubig?",
                        "Hindi pa gumagaling ang dehydration. Kailangan ko ng inumin ngayon.",
                        "Uhaw na uhaw pa rin ako. Dalhin mo ang bote rito.",
                        "Nakatuyot pa rin ang lalamunan ko. Kailangan ng tubig.",
                        "Hindi makakausad nang walang tubig. Tulungan mo ako.",
                        "Naghihintay pa rin sa inumin. Sobrang nanghihina na.",
                        "Kailangan ng inumin bago gumana ulit ang mga binti ko.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_update",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress.update.exhaustion",
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
                                ["fallback"] = "I still need time to recover my strength.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.medical.distress.update.exhaustion.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I still need time to recover my strength.",
                                        "Stamina is still drained. Catching my breath.",
                                        "Still exhausted. Give me a little more time.",
                                        "Muscles are still aching. Recovering slowly.",
                                        "Lungs still burning from running. Give me a moment.",
                                        "Fatigue hasn't cleared yet. Still resting here.",
                                        "Energy is very low. Still need a few breaths.",
                                        "Legs are still shaking from exhaustion. Give me time.",
                                        "Still spent. Don't rush me to run again.",
                                        "Recharging my stamina. Just a little longer.",
                                    },
                                    ["TL"] = {
                                        "Kailangan ko pa ng oras para manumbalik ang lakas ko.",
                                        "Ubos pa rin ang stamina. Humihinga pa rin.",
                                        "Pagod na pagod pa rin. Bigyan mo pa ako ng kaunting oras.",
                                        "Kumikirot pa rin ang kalamnan. Dahan-dahang nagpapagaling.",
                                        "Nasusunog pa rin ang baga sa pagtakbo. Bigyan mo ako ng saglit.",
                                        "Hindi pa humuhupa ang pagod. Nagpapahinga pa rin dito.",
                                        "Napakababa pa ng lakas. Kailangan pa ng ilang malalalim na hininga.",
                                        "Nanginginig pa rin ang mga binti sa pagod. Bigyan mo ako ng oras.",
                                        "Ubos pa rin. Huwag mo akong apurahin tumakbo ulit.",
                                        "Nagpapalakas ulit. Kaunti na lang.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.distress.update",
            ["textRoles"] = {
                {
                    ["fallback"] = "I still need time to recover my strength.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.update.exhaustion.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I still need time to recover my strength.",
                            "Stamina is still drained. Catching my breath.",
                            "Still exhausted. Give me a little more time.",
                            "Muscles are still aching. Recovering slowly.",
                            "Lungs still burning from running. Give me a moment.",
                            "Fatigue hasn't cleared yet. Still resting here.",
                            "Energy is very low. Still need a few breaths.",
                            "Legs are still shaking from exhaustion. Give me time.",
                            "Still spent. Don't rush me to run again.",
                            "Recharging my stamina. Just a little longer.",
                        },
                        ["TL"] = {
                            "Kailangan ko pa ng oras para manumbalik ang lakas ko.",
                            "Ubos pa rin ang stamina. Humihinga pa rin.",
                            "Pagod na pagod pa rin. Bigyan mo pa ako ng kaunting oras.",
                            "Kumikirot pa rin ang kalamnan. Dahan-dahang nagpapagaling.",
                            "Nasusunog pa rin ang baga sa pagtakbo. Bigyan mo ako ng saglit.",
                            "Hindi pa humuhupa ang pagod. Nagpapahinga pa rin dito.",
                            "Napakababa pa ng lakas. Kailangan pa ng ilang malalalim na hininga.",
                            "Nanginginig pa rin ang mga binti sa pagod. Bigyan mo ako ng oras.",
                            "Ubos pa rin. Huwag mo akong apurahin tumakbo ulit.",
                            "Nagpapalakas ulit. Kaunti na lang.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "medical.distress.update.exhaustion",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "exhaustion",
            ["sourceId"] = "medical.distress.update.exhaustion",
            ["sourcePath"] = "adopters/hoomans/dialogue/medical_event_update/medical_distress_update_exhaustion.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalEventUpdate",
        ["namespace"] = "medical.distress.update",
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
                                        "I still need time to recover my strength.",
                                        "Stamina is still drained. Catching my breath.",
                                        "Still exhausted. Give me a little more time.",
                                        "Muscles are still aching. Recovering slowly.",
                                        "Lungs still burning from running. Give me a moment.",
                                        "Fatigue hasn't cleared yet. Still resting here.",
                                        "Energy is very low. Still need a few breaths.",
                                        "Legs are still shaking from exhaustion. Give me time.",
                                        "Still spent. Don't rush me to run again.",
                                        "Recharging my stamina. Just a little longer.",
                                    },
                                    ["TL"] = {
                                        "Kailangan ko pa ng oras para manumbalik ang lakas ko.",
                                        "Ubos pa rin ang stamina. Humihinga pa rin.",
                                        "Pagod na pagod pa rin. Bigyan mo pa ako ng kaunting oras.",
                                        "Kumikirot pa rin ang kalamnan. Dahan-dahang nagpapagaling.",
                                        "Nasusunog pa rin ang baga sa pagtakbo. Bigyan mo ako ng saglit.",
                                        "Hindi pa humuhupa ang pagod. Nagpapahinga pa rin dito.",
                                        "Napakababa pa ng lakas. Kailangan pa ng ilang malalalim na hininga.",
                                        "Nanginginig pa rin ang mga binti sa pagod. Bigyan mo ako ng oras.",
                                        "Ubos pa rin. Huwag mo akong apurahin tumakbo ulit.",
                                        "Nagpapalakas ulit. Kaunti na lang.",
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
            ["responsePlanID"] = "medical.distress.update.exhaustion",
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
                            ["fallback"] = "I still need time to recover my strength.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.medical.distress.update.exhaustion.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/medical_event_update/medical_distress_update_exhaustion.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I still need time to recover my strength.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.update.exhaustion.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I still need time to recover my strength.",
                        "Stamina is still drained. Catching my breath.",
                        "Still exhausted. Give me a little more time.",
                        "Muscles are still aching. Recovering slowly.",
                        "Lungs still burning from running. Give me a moment.",
                        "Fatigue hasn't cleared yet. Still resting here.",
                        "Energy is very low. Still need a few breaths.",
                        "Legs are still shaking from exhaustion. Give me time.",
                        "Still spent. Don't rush me to run again.",
                        "Recharging my stamina. Just a little longer.",
                    },
                    ["TL"] = {
                        "Kailangan ko pa ng oras para manumbalik ang lakas ko.",
                        "Ubos pa rin ang stamina. Humihinga pa rin.",
                        "Pagod na pagod pa rin. Bigyan mo pa ako ng kaunting oras.",
                        "Kumikirot pa rin ang kalamnan. Dahan-dahang nagpapagaling.",
                        "Nasusunog pa rin ang baga sa pagtakbo. Bigyan mo ako ng saglit.",
                        "Hindi pa humuhupa ang pagod. Nagpapahinga pa rin dito.",
                        "Napakababa pa ng lakas. Kailangan pa ng ilang malalalim na hininga.",
                        "Nanginginig pa rin ang mga binti sa pagod. Bigyan mo ako ng oras.",
                        "Ubos pa rin. Huwag mo akong apurahin tumakbo ulit.",
                        "Nagpapalakas ulit. Kaunti na lang.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_update",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress.update.mercy",
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
                                ["fallback"] = "I am still down. Please do not finish me.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.medical.distress.update.mercy.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I am still down. Please do not finish me.",
                                        "Still helpless here. Spare my life, please.",
                                        "I'm still no threat to you. Please have mercy.",
                                        "Still begging for survival. Don't hurt me.",
                                        "Plea remains: spare me and let me crawl away.",
                                        "I surrender completely. Please do not execute me.",
                                        "Still at your mercy. Please keep that weapon away.",
                                        "I have surrendered. Don't strike a downed person.",
                                        "Please honor your mercy. Don't kill me.",
                                        "Still alive, still pleading. Let me survive this.",
                                    },
                                    ["TL"] = {
                                        "Bagsak pa rin ako. Pakiusap huwag mo akong tapusin.",
                                        "Walang laban pa rin dito. Buhayin mo ako, pakiusap.",
                                        "Wala pa rin akong banta sa'yo. Pakiusap maawa ka.",
                                        "Nagmamakaawa pa rin para mabuhay. Huwag mo akong saktan.",
                                        "Hiling ko pa rin: buhayin mo ako at hayaang gumapang palayo.",
                                        "Sumusuko ako nang buo. Pakiusap huwag mo akong patayin.",
                                        "Nasa awa mo pa rin ako. Pakiusap ilayo mo ang sandata na 'yan.",
                                        "Sumuko na ako. Huwag kang manakit ng taong nakahandusay.",
                                        "Pakiusap tuparin mo ang awa mo. Huwag mo akong patayin.",
                                        "Buhay pa, nagmamakaawa pa rin. Hayaan mo akong makaraos dito.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.distress.update",
            ["textRoles"] = {
                {
                    ["fallback"] = "I am still down. Please do not finish me.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.update.mercy.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I am still down. Please do not finish me.",
                            "Still helpless here. Spare my life, please.",
                            "I'm still no threat to you. Please have mercy.",
                            "Still begging for survival. Don't hurt me.",
                            "Plea remains: spare me and let me crawl away.",
                            "I surrender completely. Please do not execute me.",
                            "Still at your mercy. Please keep that weapon away.",
                            "I have surrendered. Don't strike a downed person.",
                            "Please honor your mercy. Don't kill me.",
                            "Still alive, still pleading. Let me survive this.",
                        },
                        ["TL"] = {
                            "Bagsak pa rin ako. Pakiusap huwag mo akong tapusin.",
                            "Walang laban pa rin dito. Buhayin mo ako, pakiusap.",
                            "Wala pa rin akong banta sa'yo. Pakiusap maawa ka.",
                            "Nagmamakaawa pa rin para mabuhay. Huwag mo akong saktan.",
                            "Hiling ko pa rin: buhayin mo ako at hayaang gumapang palayo.",
                            "Sumusuko ako nang buo. Pakiusap huwag mo akong patayin.",
                            "Nasa awa mo pa rin ako. Pakiusap ilayo mo ang sandata na 'yan.",
                            "Sumuko na ako. Huwag kang manakit ng taong nakahandusay.",
                            "Pakiusap tuparin mo ang awa mo. Huwag mo akong patayin.",
                            "Buhay pa, nagmamakaawa pa rin. Hayaan mo akong makaraos dito.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "medical.distress.update.mercy",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "mercy",
            ["sourceId"] = "medical.distress.update.mercy",
            ["sourcePath"] = "adopters/hoomans/dialogue/medical_event_update/medical_distress_update_mercy.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalEventUpdate",
        ["namespace"] = "medical.distress.update",
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
                                        "I am still down. Please do not finish me.",
                                        "Still helpless here. Spare my life, please.",
                                        "I'm still no threat to you. Please have mercy.",
                                        "Still begging for survival. Don't hurt me.",
                                        "Plea remains: spare me and let me crawl away.",
                                        "I surrender completely. Please do not execute me.",
                                        "Still at your mercy. Please keep that weapon away.",
                                        "I have surrendered. Don't strike a downed person.",
                                        "Please honor your mercy. Don't kill me.",
                                        "Still alive, still pleading. Let me survive this.",
                                    },
                                    ["TL"] = {
                                        "Bagsak pa rin ako. Pakiusap huwag mo akong tapusin.",
                                        "Walang laban pa rin dito. Buhayin mo ako, pakiusap.",
                                        "Wala pa rin akong banta sa'yo. Pakiusap maawa ka.",
                                        "Nagmamakaawa pa rin para mabuhay. Huwag mo akong saktan.",
                                        "Hiling ko pa rin: buhayin mo ako at hayaang gumapang palayo.",
                                        "Sumusuko ako nang buo. Pakiusap huwag mo akong patayin.",
                                        "Nasa awa mo pa rin ako. Pakiusap ilayo mo ang sandata na 'yan.",
                                        "Sumuko na ako. Huwag kang manakit ng taong nakahandusay.",
                                        "Pakiusap tuparin mo ang awa mo. Huwag mo akong patayin.",
                                        "Buhay pa, nagmamakaawa pa rin. Hayaan mo akong makaraos dito.",
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
            ["responsePlanID"] = "medical.distress.update.mercy",
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
                            ["fallback"] = "I am still down. Please do not finish me.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.medical.distress.update.mercy.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/medical_event_update/medical_distress_update_mercy.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I am still down. Please do not finish me.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.update.mercy.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I am still down. Please do not finish me.",
                        "Still helpless here. Spare my life, please.",
                        "I'm still no threat to you. Please have mercy.",
                        "Still begging for survival. Don't hurt me.",
                        "Plea remains: spare me and let me crawl away.",
                        "I surrender completely. Please do not execute me.",
                        "Still at your mercy. Please keep that weapon away.",
                        "I have surrendered. Don't strike a downed person.",
                        "Please honor your mercy. Don't kill me.",
                        "Still alive, still pleading. Let me survive this.",
                    },
                    ["TL"] = {
                        "Bagsak pa rin ako. Pakiusap huwag mo akong tapusin.",
                        "Walang laban pa rin dito. Buhayin mo ako, pakiusap.",
                        "Wala pa rin akong banta sa'yo. Pakiusap maawa ka.",
                        "Nagmamakaawa pa rin para mabuhay. Huwag mo akong saktan.",
                        "Hiling ko pa rin: buhayin mo ako at hayaang gumapang palayo.",
                        "Sumusuko ako nang buo. Pakiusap huwag mo akong patayin.",
                        "Nasa awa mo pa rin ako. Pakiusap ilayo mo ang sandata na 'yan.",
                        "Sumuko na ako. Huwag kang manakit ng taong nakahandusay.",
                        "Pakiusap tuparin mo ang awa mo. Huwag mo akong patayin.",
                        "Buhay pa, nagmamakaawa pa rin. Hayaan mo akong makaraos dito.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_update",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress.update.rescue",
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
                                ["fallback"] = "I am still here. Please come back for me.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.medical.distress.update.rescue.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I am still here. Please come back for me.",
                                        "Still trapped in place. Waiting for your rescue.",
                                        "Don't leave me stranded! I'm still where you left me.",
                                        "Still cannot walk out alone. Come help me.",
                                        "Waiting on rescue here. Hurry before dead arrive.",
                                        "Still pinned down. Please extract me.",
                                        "Don't forget me here! Still need someone to pull me out.",
                                        "Status unchanged: trapped and waiting for assistance.",
                                        "Still waiting for someone to drag me to safety.",
                                        "I'm still right here. Please don't leave me behind.",
                                    },
                                    ["TL"] = {
                                        "Nandito pa rin ako. Pakiusap balikan mo ako.",
                                        "Naipit pa rin sa pwesto. Naghihintay sa saklolo mo.",
                                        "Huwag mo akong iwang nastranded! Nandito pa rin ako sa iniwanan mo.",
                                        "Hindi pa rin makalabas nang mag-isa. Halika tulungan mo ako.",
                                        "Naghihintay ng saklolo rito. Bilisan mo bago dumating ang mga patay.",
                                        "Naiipit pa rin. Pakiusap hilahin mo ako palabas.",
                                        "Huwag mo akong kalimutan dito! Kailangan pa rin ng maghihila sa akin.",
                                        "Walang pagbabago: naipit at naghihintay ng saklolo.",
                                        "Naghihintay pa rin ng hihila sa akin sa ligtas na lugar.",
                                        "Nandito lang ako. Pakiusap huwag mo akong iwan.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.distress.update",
            ["textRoles"] = {
                {
                    ["fallback"] = "I am still here. Please come back for me.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.update.rescue.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I am still here. Please come back for me.",
                            "Still trapped in place. Waiting for your rescue.",
                            "Don't leave me stranded! I'm still where you left me.",
                            "Still cannot walk out alone. Come help me.",
                            "Waiting on rescue here. Hurry before dead arrive.",
                            "Still pinned down. Please extract me.",
                            "Don't forget me here! Still need someone to pull me out.",
                            "Status unchanged: trapped and waiting for assistance.",
                            "Still waiting for someone to drag me to safety.",
                            "I'm still right here. Please don't leave me behind.",
                        },
                        ["TL"] = {
                            "Nandito pa rin ako. Pakiusap balikan mo ako.",
                            "Naipit pa rin sa pwesto. Naghihintay sa saklolo mo.",
                            "Huwag mo akong iwang nastranded! Nandito pa rin ako sa iniwanan mo.",
                            "Hindi pa rin makalabas nang mag-isa. Halika tulungan mo ako.",
                            "Naghihintay ng saklolo rito. Bilisan mo bago dumating ang mga patay.",
                            "Naiipit pa rin. Pakiusap hilahin mo ako palabas.",
                            "Huwag mo akong kalimutan dito! Kailangan pa rin ng maghihila sa akin.",
                            "Walang pagbabago: naipit at naghihintay ng saklolo.",
                            "Naghihintay pa rin ng hihila sa akin sa ligtas na lugar.",
                            "Nandito lang ako. Pakiusap huwag mo akong iwan.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "medical.distress.update.rescue",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "rescue",
            ["sourceId"] = "medical.distress.update.rescue",
            ["sourcePath"] = "adopters/hoomans/dialogue/medical_event_update/medical_distress_update_rescue.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalEventUpdate",
        ["namespace"] = "medical.distress.update",
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
                                        "I am still here. Please come back for me.",
                                        "Still trapped in place. Waiting for your rescue.",
                                        "Don't leave me stranded! I'm still where you left me.",
                                        "Still cannot walk out alone. Come help me.",
                                        "Waiting on rescue here. Hurry before dead arrive.",
                                        "Still pinned down. Please extract me.",
                                        "Don't forget me here! Still need someone to pull me out.",
                                        "Status unchanged: trapped and waiting for assistance.",
                                        "Still waiting for someone to drag me to safety.",
                                        "I'm still right here. Please don't leave me behind.",
                                    },
                                    ["TL"] = {
                                        "Nandito pa rin ako. Pakiusap balikan mo ako.",
                                        "Naipit pa rin sa pwesto. Naghihintay sa saklolo mo.",
                                        "Huwag mo akong iwang nastranded! Nandito pa rin ako sa iniwanan mo.",
                                        "Hindi pa rin makalabas nang mag-isa. Halika tulungan mo ako.",
                                        "Naghihintay ng saklolo rito. Bilisan mo bago dumating ang mga patay.",
                                        "Naiipit pa rin. Pakiusap hilahin mo ako palabas.",
                                        "Huwag mo akong kalimutan dito! Kailangan pa rin ng maghihila sa akin.",
                                        "Walang pagbabago: naipit at naghihintay ng saklolo.",
                                        "Naghihintay pa rin ng hihila sa akin sa ligtas na lugar.",
                                        "Nandito lang ako. Pakiusap huwag mo akong iwan.",
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
            ["responsePlanID"] = "medical.distress.update.rescue",
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
                            ["fallback"] = "I am still here. Please come back for me.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.medical.distress.update.rescue.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/medical_event_update/medical_distress_update_rescue.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I am still here. Please come back for me.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.update.rescue.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I am still here. Please come back for me.",
                        "Still trapped in place. Waiting for your rescue.",
                        "Don't leave me stranded! I'm still where you left me.",
                        "Still cannot walk out alone. Come help me.",
                        "Waiting on rescue here. Hurry before dead arrive.",
                        "Still pinned down. Please extract me.",
                        "Don't forget me here! Still need someone to pull me out.",
                        "Status unchanged: trapped and waiting for assistance.",
                        "Still waiting for someone to drag me to safety.",
                        "I'm still right here. Please don't leave me behind.",
                    },
                    ["TL"] = {
                        "Nandito pa rin ako. Pakiusap balikan mo ako.",
                        "Naipit pa rin sa pwesto. Naghihintay sa saklolo mo.",
                        "Huwag mo akong iwang nastranded! Nandito pa rin ako sa iniwanan mo.",
                        "Hindi pa rin makalabas nang mag-isa. Halika tulungan mo ako.",
                        "Naghihintay ng saklolo rito. Bilisan mo bago dumating ang mga patay.",
                        "Naiipit pa rin. Pakiusap hilahin mo ako palabas.",
                        "Huwag mo akong kalimutan dito! Kailangan pa rin ng maghihila sa akin.",
                        "Walang pagbabago: naipit at naghihintay ng saklolo.",
                        "Naghihintay pa rin ng hihila sa akin sa ligtas na lugar.",
                        "Nandito lang ako. Pakiusap huwag mo akong iwan.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_update",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress.update.starvation",
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
                                ["fallback"] = "I still need food before I can get up.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.medical.distress.update.starvation.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I still need food before I can get up.",
                                        "Starvation is worsening. Did you find anything edible?",
                                        "Still too weak from hunger to stand.",
                                        "Can't move on an empty stomach. Bring food.",
                                        "Still starving on the floor. Please bring a ration.",
                                        "Body needs calories right now. I'm fading.",
                                        "Still waiting for a meal. Stomach cramps are brutal.",
                                        "Can't regain strength without food. Help me.",
                                        "Still starving here. Any can of beans or soup?",
                                        "Need nourishment before I can take a step.",
                                    },
                                    ["TL"] = {
                                        "Kailangan ko pa rin ng pagkain bago makatayo.",
                                        "Lumalala ang gutom ko. May nahanap ka bang makakain?",
                                        "Nanghihina pa rin sa gutom para makatayo.",
                                        "Hindi makakilos nang walang laman ang tiyan. Dalhan mo ako ng pagkain.",
                                        "Nagugutom pa rin sa sahig. Pakiusap dalhan mo ako ng rasyon.",
                                        "Kailangan ng katawan ng pagkain ngayon din. Nanghihina na ako.",
                                        "Naghihintay pa rin ng pagkain. Matindi ang pulikat ng tiyan ko.",
                                        "Hindi maibabalik ang lakas nang walang pagkain. Tulungan mo ako.",
                                        "Gutom pa rin ako rito. May de-latang beans ba o sabaw?",
                                        "Kailangan ko ng makakain bago ako makahakbang.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.distress.update",
            ["textRoles"] = {
                {
                    ["fallback"] = "I still need food before I can get up.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.update.starvation.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I still need food before I can get up.",
                            "Starvation is worsening. Did you find anything edible?",
                            "Still too weak from hunger to stand.",
                            "Can't move on an empty stomach. Bring food.",
                            "Still starving on the floor. Please bring a ration.",
                            "Body needs calories right now. I'm fading.",
                            "Still waiting for a meal. Stomach cramps are brutal.",
                            "Can't regain strength without food. Help me.",
                            "Still starving here. Any can of beans or soup?",
                            "Need nourishment before I can take a step.",
                        },
                        ["TL"] = {
                            "Kailangan ko pa rin ng pagkain bago makatayo.",
                            "Lumalala ang gutom ko. May nahanap ka bang makakain?",
                            "Nanghihina pa rin sa gutom para makatayo.",
                            "Hindi makakilos nang walang laman ang tiyan. Dalhan mo ako ng pagkain.",
                            "Nagugutom pa rin sa sahig. Pakiusap dalhan mo ako ng rasyon.",
                            "Kailangan ng katawan ng pagkain ngayon din. Nanghihina na ako.",
                            "Naghihintay pa rin ng pagkain. Matindi ang pulikat ng tiyan ko.",
                            "Hindi maibabalik ang lakas nang walang pagkain. Tulungan mo ako.",
                            "Gutom pa rin ako rito. May de-latang beans ba o sabaw?",
                            "Kailangan ko ng makakain bago ako makahakbang.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "medical.distress.update.starvation",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "starvation",
            ["sourceId"] = "medical.distress.update.starvation",
            ["sourcePath"] = "adopters/hoomans/dialogue/medical_event_update/medical_distress_update_starvation.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalEventUpdate",
        ["namespace"] = "medical.distress.update",
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
                                        "I still need food before I can get up.",
                                        "Starvation is worsening. Did you find anything edible?",
                                        "Still too weak from hunger to stand.",
                                        "Can't move on an empty stomach. Bring food.",
                                        "Still starving on the floor. Please bring a ration.",
                                        "Body needs calories right now. I'm fading.",
                                        "Still waiting for a meal. Stomach cramps are brutal.",
                                        "Can't regain strength without food. Help me.",
                                        "Still starving here. Any can of beans or soup?",
                                        "Need nourishment before I can take a step.",
                                    },
                                    ["TL"] = {
                                        "Kailangan ko pa rin ng pagkain bago makatayo.",
                                        "Lumalala ang gutom ko. May nahanap ka bang makakain?",
                                        "Nanghihina pa rin sa gutom para makatayo.",
                                        "Hindi makakilos nang walang laman ang tiyan. Dalhan mo ako ng pagkain.",
                                        "Nagugutom pa rin sa sahig. Pakiusap dalhan mo ako ng rasyon.",
                                        "Kailangan ng katawan ng pagkain ngayon din. Nanghihina na ako.",
                                        "Naghihintay pa rin ng pagkain. Matindi ang pulikat ng tiyan ko.",
                                        "Hindi maibabalik ang lakas nang walang pagkain. Tulungan mo ako.",
                                        "Gutom pa rin ako rito. May de-latang beans ba o sabaw?",
                                        "Kailangan ko ng makakain bago ako makahakbang.",
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
            ["responsePlanID"] = "medical.distress.update.starvation",
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
                            ["fallback"] = "I still need food before I can get up.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.medical.distress.update.starvation.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/medical_event_update/medical_distress_update_starvation.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I still need food before I can get up.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.update.starvation.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I still need food before I can get up.",
                        "Starvation is worsening. Did you find anything edible?",
                        "Still too weak from hunger to stand.",
                        "Can't move on an empty stomach. Bring food.",
                        "Still starving on the floor. Please bring a ration.",
                        "Body needs calories right now. I'm fading.",
                        "Still waiting for a meal. Stomach cramps are brutal.",
                        "Can't regain strength without food. Help me.",
                        "Still starving here. Any can of beans or soup?",
                        "Need nourishment before I can take a step.",
                    },
                    ["TL"] = {
                        "Kailangan ko pa rin ng pagkain bago makatayo.",
                        "Lumalala ang gutom ko. May nahanap ka bang makakain?",
                        "Nanghihina pa rin sa gutom para makatayo.",
                        "Hindi makakilos nang walang laman ang tiyan. Dalhan mo ako ng pagkain.",
                        "Nagugutom pa rin sa sahig. Pakiusap dalhan mo ako ng rasyon.",
                        "Kailangan ng katawan ng pagkain ngayon din. Nanghihina na ako.",
                        "Naghihintay pa rin ng pagkain. Matindi ang pulikat ng tiyan ko.",
                        "Hindi maibabalik ang lakas nang walang pagkain. Tulungan mo ako.",
                        "Gutom pa rin ako rito. May de-latang beans ba o sabaw?",
                        "Kailangan ko ng makakain bago ako makahakbang.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
