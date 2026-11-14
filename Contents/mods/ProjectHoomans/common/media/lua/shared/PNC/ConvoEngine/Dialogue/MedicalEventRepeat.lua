-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "medical_event_repeat",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress.repeat.bandage",
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
                                ["fallback"] = "I still need these wounds patched! Hurry!",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.medical.distress.repeat.bandage.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I still need these wounds patched! Hurry!",
                                        "Where's that bandage?! Still bleeding out here!",
                                        "Don't forget about me! I need a wrap now!",
                                        "Still waiting on that bandage! It's soaking through!",
                                        "Please, hurry with the bandages! I'm fading!",
                                        "I asked for a bandage! Did you find one?!",
                                        "Wound is still open! Bring the dressing over!",
                                        "Can someone please patch me up already?!",
                                        "Blood is still pooling! Get that bandage on me!",
                                        "Still bleeding here! Hurry with the cloth!",
                                    },
                                    ["TL"] = {
                                        "Kailangan ko pa ring mabendahan ang sugat na 'to! Bilis!",
                                        "Nasaan na 'yung benda?! Dumurugo pa rin ako rito!",
                                        "Huwag niyo akong kalimutan! Kailangan ko ng benda ngayon!",
                                        "Naghihintay pa rin ako sa benda! Bumababad na ang dugo!",
                                        "Pakiusap, bilisan ang benda! Nanghihina na ako!",
                                        "Humihingi ako ng benda! May nahanap ka ba?!",
                                        "Bukas pa rin ang sugat! Dalhin mo na ang pambenda!",
                                        "May magbe-benda ba sa akin ngayon din?!",
                                        "Nag-iipon pa rin ang dugo! Ilagay mo na ang benda sa akin!",
                                        "Dumurugo pa rin ako rito! Bilisan mo ang tela!",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.distress.repeat",
            ["textRoles"] = {
                {
                    ["fallback"] = "I still need these wounds patched! Hurry!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.repeat.bandage.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I still need these wounds patched! Hurry!",
                            "Where's that bandage?! Still bleeding out here!",
                            "Don't forget about me! I need a wrap now!",
                            "Still waiting on that bandage! It's soaking through!",
                            "Please, hurry with the bandages! I'm fading!",
                            "I asked for a bandage! Did you find one?!",
                            "Wound is still open! Bring the dressing over!",
                            "Can someone please patch me up already?!",
                            "Blood is still pooling! Get that bandage on me!",
                            "Still bleeding here! Hurry with the cloth!",
                        },
                        ["TL"] = {
                            "Kailangan ko pa ring mabendahan ang sugat na 'to! Bilis!",
                            "Nasaan na 'yung benda?! Dumurugo pa rin ako rito!",
                            "Huwag niyo akong kalimutan! Kailangan ko ng benda ngayon!",
                            "Naghihintay pa rin ako sa benda! Bumababad na ang dugo!",
                            "Pakiusap, bilisan ang benda! Nanghihina na ako!",
                            "Humihingi ako ng benda! May nahanap ka ba?!",
                            "Bukas pa rin ang sugat! Dalhin mo na ang pambenda!",
                            "May magbe-benda ba sa akin ngayon din?!",
                            "Nag-iipon pa rin ang dugo! Ilagay mo na ang benda sa akin!",
                            "Dumurugo pa rin ako rito! Bilisan mo ang tela!",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "medical.distress.repeat.bandage",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "bandage",
            ["sourceId"] = "medical.distress.repeat.bandage",
            ["sourcePath"] = "adopters/hoomans/dialogue/medical_event_repeat/medical_distress_repeat_bandage.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalEventRepeat",
        ["namespace"] = "medical.distress.repeat",
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
                ["sourceSurface"] = "content/event/medical/repeat.json",
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
                                        "I still need these wounds patched! Hurry!",
                                        "Where's that bandage?! Still bleeding out here!",
                                        "Don't forget about me! I need a wrap now!",
                                        "Still waiting on that bandage! It's soaking through!",
                                        "Please, hurry with the bandages! I'm fading!",
                                        "I asked for a bandage! Did you find one?!",
                                        "Wound is still open! Bring the dressing over!",
                                        "Can someone please patch me up already?!",
                                        "Blood is still pooling! Get that bandage on me!",
                                        "Still bleeding here! Hurry with the cloth!",
                                    },
                                    ["TL"] = {
                                        "Kailangan ko pa ring mabendahan ang sugat na 'to! Bilis!",
                                        "Nasaan na 'yung benda?! Dumurugo pa rin ako rito!",
                                        "Huwag niyo akong kalimutan! Kailangan ko ng benda ngayon!",
                                        "Naghihintay pa rin ako sa benda! Bumababad na ang dugo!",
                                        "Pakiusap, bilisan ang benda! Nanghihina na ako!",
                                        "Humihingi ako ng benda! May nahanap ka ba?!",
                                        "Bukas pa rin ang sugat! Dalhin mo na ang pambenda!",
                                        "May magbe-benda ba sa akin ngayon din?!",
                                        "Nag-iipon pa rin ang dugo! Ilagay mo na ang benda sa akin!",
                                        "Dumurugo pa rin ako rito! Bilisan mo ang tela!",
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
            ["responsePlanID"] = "medical.distress.repeat.bandage",
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
                            ["fallback"] = "I still need these wounds patched! Hurry!",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.medical.distress.repeat.bandage.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/medical_event_repeat/medical_distress_repeat_bandage.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I still need these wounds patched! Hurry!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.repeat.bandage.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I still need these wounds patched! Hurry!",
                        "Where's that bandage?! Still bleeding out here!",
                        "Don't forget about me! I need a wrap now!",
                        "Still waiting on that bandage! It's soaking through!",
                        "Please, hurry with the bandages! I'm fading!",
                        "I asked for a bandage! Did you find one?!",
                        "Wound is still open! Bring the dressing over!",
                        "Can someone please patch me up already?!",
                        "Blood is still pooling! Get that bandage on me!",
                        "Still bleeding here! Hurry with the cloth!",
                    },
                    ["TL"] = {
                        "Kailangan ko pa ring mabendahan ang sugat na 'to! Bilis!",
                        "Nasaan na 'yung benda?! Dumurugo pa rin ako rito!",
                        "Huwag niyo akong kalimutan! Kailangan ko ng benda ngayon!",
                        "Naghihintay pa rin ako sa benda! Bumababad na ang dugo!",
                        "Pakiusap, bilisan ang benda! Nanghihina na ako!",
                        "Humihingi ako ng benda! May nahanap ka ba?!",
                        "Bukas pa rin ang sugat! Dalhin mo na ang pambenda!",
                        "May magbe-benda ba sa akin ngayon din?!",
                        "Nag-iipon pa rin ang dugo! Ilagay mo na ang benda sa akin!",
                        "Dumurugo pa rin ako rito! Bilisan mo ang tela!",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_repeat",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress.repeat.bleedout",
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
                                ["fallback"] = "I am still losing blood! Please, help me!",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.medical.distress.repeat.bleedout.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I am still losing blood! Please, help me!",
                                        "Pressure isn't working! The bleeding won't stop!",
                                        "I don't have much time left... blood is gushing!",
                                        "Hurry, damn it! I'm going to bleed to death!",
                                        "My pulse is getting weak... stop the bleed!",
                                        "Still bleeding out! Don't let me die on this floor!",
                                        "I'm freezing cold from blood loss... hurry!",
                                        "Blood won't clot! I need immediate help!",
                                        "Everything is fading... stop the bleeding, please!",
                                        "Hurry up! I can't hold my own artery closed!",
                                    },
                                    ["TL"] = {
                                        "Nauubusan pa rin ako ng dugo! Pakiusap, tulungan mo ako!",
                                        "Hindi gumagana ang diin! Ayaw tumigil ng pagdurugo!",
                                        "Wala na akong gaanong oras... bumubuhos ang dugo!",
                                        "Bilisan mo naman! Mamamatay na ako sa pagdurugo!",
                                        "Humihina na ang pulso ko... patigilin ang pagdurugo!",
                                        "Nauubusan pa rin ng dugo! Huwag mo akong hayaang mamatay sa sahig!",
                                        "Giniginaw na ako sa nawalang dugo... bilisan mo!",
                                        "Ayaw mamuo ng dugo! Kailangan ko ng agarang tulong!",
                                        "Naglalaho ang lahat... patigilin mo ang dugo, pakiusap!",
                                        "Bilisan mo! Hindi ko kayang pigilin ang ugat ko nang mag-isa!",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.distress.repeat",
            ["textRoles"] = {
                {
                    ["fallback"] = "I am still losing blood! Please, help me!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.repeat.bleedout.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I am still losing blood! Please, help me!",
                            "Pressure isn't working! The bleeding won't stop!",
                            "I don't have much time left... blood is gushing!",
                            "Hurry, damn it! I'm going to bleed to death!",
                            "My pulse is getting weak... stop the bleed!",
                            "Still bleeding out! Don't let me die on this floor!",
                            "I'm freezing cold from blood loss... hurry!",
                            "Blood won't clot! I need immediate help!",
                            "Everything is fading... stop the bleeding, please!",
                            "Hurry up! I can't hold my own artery closed!",
                        },
                        ["TL"] = {
                            "Nauubusan pa rin ako ng dugo! Pakiusap, tulungan mo ako!",
                            "Hindi gumagana ang diin! Ayaw tumigil ng pagdurugo!",
                            "Wala na akong gaanong oras... bumubuhos ang dugo!",
                            "Bilisan mo naman! Mamamatay na ako sa pagdurugo!",
                            "Humihina na ang pulso ko... patigilin ang pagdurugo!",
                            "Nauubusan pa rin ng dugo! Huwag mo akong hayaang mamatay sa sahig!",
                            "Giniginaw na ako sa nawalang dugo... bilisan mo!",
                            "Ayaw mamuo ng dugo! Kailangan ko ng agarang tulong!",
                            "Naglalaho ang lahat... patigilin mo ang dugo, pakiusap!",
                            "Bilisan mo! Hindi ko kayang pigilin ang ugat ko nang mag-isa!",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "medical.distress.repeat.bleedout",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "bleedout",
            ["sourceId"] = "medical.distress.repeat.bleedout",
            ["sourcePath"] = "adopters/hoomans/dialogue/medical_event_repeat/medical_distress_repeat_bleedout.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalEventRepeat",
        ["namespace"] = "medical.distress.repeat",
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
                ["sourceSurface"] = "content/event/medical/repeat.json",
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
                                        "I am still losing blood! Please, help me!",
                                        "Pressure isn't working! The bleeding won't stop!",
                                        "I don't have much time left... blood is gushing!",
                                        "Hurry, damn it! I'm going to bleed to death!",
                                        "My pulse is getting weak... stop the bleed!",
                                        "Still bleeding out! Don't let me die on this floor!",
                                        "I'm freezing cold from blood loss... hurry!",
                                        "Blood won't clot! I need immediate help!",
                                        "Everything is fading... stop the bleeding, please!",
                                        "Hurry up! I can't hold my own artery closed!",
                                    },
                                    ["TL"] = {
                                        "Nauubusan pa rin ako ng dugo! Pakiusap, tulungan mo ako!",
                                        "Hindi gumagana ang diin! Ayaw tumigil ng pagdurugo!",
                                        "Wala na akong gaanong oras... bumubuhos ang dugo!",
                                        "Bilisan mo naman! Mamamatay na ako sa pagdurugo!",
                                        "Humihina na ang pulso ko... patigilin ang pagdurugo!",
                                        "Nauubusan pa rin ng dugo! Huwag mo akong hayaang mamatay sa sahig!",
                                        "Giniginaw na ako sa nawalang dugo... bilisan mo!",
                                        "Ayaw mamuo ng dugo! Kailangan ko ng agarang tulong!",
                                        "Naglalaho ang lahat... patigilin mo ang dugo, pakiusap!",
                                        "Bilisan mo! Hindi ko kayang pigilin ang ugat ko nang mag-isa!",
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
            ["responsePlanID"] = "medical.distress.repeat.bleedout",
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
                            ["fallback"] = "I am still losing blood! Please, help me!",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.medical.distress.repeat.bleedout.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/medical_event_repeat/medical_distress_repeat_bleedout.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I am still losing blood! Please, help me!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.repeat.bleedout.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I am still losing blood! Please, help me!",
                        "Pressure isn't working! The bleeding won't stop!",
                        "I don't have much time left... blood is gushing!",
                        "Hurry, damn it! I'm going to bleed to death!",
                        "My pulse is getting weak... stop the bleed!",
                        "Still bleeding out! Don't let me die on this floor!",
                        "I'm freezing cold from blood loss... hurry!",
                        "Blood won't clot! I need immediate help!",
                        "Everything is fading... stop the bleeding, please!",
                        "Hurry up! I can't hold my own artery closed!",
                    },
                    ["TL"] = {
                        "Nauubusan pa rin ako ng dugo! Pakiusap, tulungan mo ako!",
                        "Hindi gumagana ang diin! Ayaw tumigil ng pagdurugo!",
                        "Wala na akong gaanong oras... bumubuhos ang dugo!",
                        "Bilisan mo naman! Mamamatay na ako sa pagdurugo!",
                        "Humihina na ang pulso ko... patigilin ang pagdurugo!",
                        "Nauubusan pa rin ng dugo! Huwag mo akong hayaang mamatay sa sahig!",
                        "Giniginaw na ako sa nawalang dugo... bilisan mo!",
                        "Ayaw mamuo ng dugo! Kailangan ko ng agarang tulong!",
                        "Naglalaho ang lahat... patigilin mo ang dugo, pakiusap!",
                        "Bilisan mo! Hindi ko kayang pigilin ang ugat ko nang mag-isa!",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_repeat",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress.repeat.default",
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
                                ["fallback"] = "I'm not up yet. Please help me.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.medical.distress.repeat.default.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'm not up yet. Please help me.",
                                        "Still down here! Don't leave me behind!",
                                        "I still need assistance to get on my feet.",
                                        "Can someone help me up? Still grounded.",
                                        "I'm still incapacitated! Come over here!",
                                        "Still hurting, still stuck. Give me a hand.",
                                        "Haven't moved an inch. Need someone to help.",
                                        "Please, I'm still on the ground waiting.",
                                        "Still can't stand. Don't forget I'm down.",
                                        "I'm still here! Help me up already!",
                                    },
                                    ["TL"] = {
                                        "Hindi pa ako nakakabangon. Pakiusap tulungan mo ako.",
                                        "Nandito pa rin ako sa sahig! Huwag mo akong iwan!",
                                        "Kailangan ko pa rin ng tulong para makatayo.",
                                        "May tutulong ba sa aking tumayo? Bagsak pa rin ako.",
                                        "Hindi pa rin ako makakilos! Pumunta ka rito!",
                                        "Masakit pa rin, naipit pa rin. Tulungan mo ako.",
                                        "Hindi pa ako nakakagalaw kahit kaunti. Kailangan ng tulong.",
                                        "Pakiusap, nasa lupa pa rin ako at naghihintay.",
                                        "Hindi pa rin makatayo. Huwag mong kalimutang bagsak ako.",
                                        "Nandito pa rin ako! Tulungan mo na akong tumayo!",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.distress.repeat",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'm not up yet. Please help me.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.repeat.default.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I'm not up yet. Please help me.",
                            "Still down here! Don't leave me behind!",
                            "I still need assistance to get on my feet.",
                            "Can someone help me up? Still grounded.",
                            "I'm still incapacitated! Come over here!",
                            "Still hurting, still stuck. Give me a hand.",
                            "Haven't moved an inch. Need someone to help.",
                            "Please, I'm still on the ground waiting.",
                            "Still can't stand. Don't forget I'm down.",
                            "I'm still here! Help me up already!",
                        },
                        ["TL"] = {
                            "Hindi pa ako nakakabangon. Pakiusap tulungan mo ako.",
                            "Nandito pa rin ako sa sahig! Huwag mo akong iwan!",
                            "Kailangan ko pa rin ng tulong para makatayo.",
                            "May tutulong ba sa aking tumayo? Bagsak pa rin ako.",
                            "Hindi pa rin ako makakilos! Pumunta ka rito!",
                            "Masakit pa rin, naipit pa rin. Tulungan mo ako.",
                            "Hindi pa ako nakakagalaw kahit kaunti. Kailangan ng tulong.",
                            "Pakiusap, nasa lupa pa rin ako at naghihintay.",
                            "Hindi pa rin makatayo. Huwag mong kalimutang bagsak ako.",
                            "Nandito pa rin ako! Tulungan mo na akong tumayo!",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "medical.distress.repeat.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "default",
            ["sourceId"] = "medical.distress.repeat.default",
            ["sourcePath"] = "adopters/hoomans/dialogue/medical_event_repeat/medical_distress_repeat_default.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalEventRepeat",
        ["namespace"] = "medical.distress.repeat",
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
                ["sourceSurface"] = "content/event/medical/repeat.json",
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
                                        "I'm not up yet. Please help me.",
                                        "Still down here! Don't leave me behind!",
                                        "I still need assistance to get on my feet.",
                                        "Can someone help me up? Still grounded.",
                                        "I'm still incapacitated! Come over here!",
                                        "Still hurting, still stuck. Give me a hand.",
                                        "Haven't moved an inch. Need someone to help.",
                                        "Please, I'm still on the ground waiting.",
                                        "Still can't stand. Don't forget I'm down.",
                                        "I'm still here! Help me up already!",
                                    },
                                    ["TL"] = {
                                        "Hindi pa ako nakakabangon. Pakiusap tulungan mo ako.",
                                        "Nandito pa rin ako sa sahig! Huwag mo akong iwan!",
                                        "Kailangan ko pa rin ng tulong para makatayo.",
                                        "May tutulong ba sa aking tumayo? Bagsak pa rin ako.",
                                        "Hindi pa rin ako makakilos! Pumunta ka rito!",
                                        "Masakit pa rin, naipit pa rin. Tulungan mo ako.",
                                        "Hindi pa ako nakakagalaw kahit kaunti. Kailangan ng tulong.",
                                        "Pakiusap, nasa lupa pa rin ako at naghihintay.",
                                        "Hindi pa rin makatayo. Huwag mong kalimutang bagsak ako.",
                                        "Nandito pa rin ako! Tulungan mo na akong tumayo!",
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
            ["responsePlanID"] = "medical.distress.repeat.default",
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
                            ["fallback"] = "I'm not up yet. Please help me.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.medical.distress.repeat.default.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/medical_event_repeat/medical_distress_repeat_default.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'm not up yet. Please help me.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.repeat.default.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I'm not up yet. Please help me.",
                        "Still down here! Don't leave me behind!",
                        "I still need assistance to get on my feet.",
                        "Can someone help me up? Still grounded.",
                        "I'm still incapacitated! Come over here!",
                        "Still hurting, still stuck. Give me a hand.",
                        "Haven't moved an inch. Need someone to help.",
                        "Please, I'm still on the ground waiting.",
                        "Still can't stand. Don't forget I'm down.",
                        "I'm still here! Help me up already!",
                    },
                    ["TL"] = {
                        "Hindi pa ako nakakabangon. Pakiusap tulungan mo ako.",
                        "Nandito pa rin ako sa sahig! Huwag mo akong iwan!",
                        "Kailangan ko pa rin ng tulong para makatayo.",
                        "May tutulong ba sa aking tumayo? Bagsak pa rin ako.",
                        "Hindi pa rin ako makakilos! Pumunta ka rito!",
                        "Masakit pa rin, naipit pa rin. Tulungan mo ako.",
                        "Hindi pa ako nakakagalaw kahit kaunti. Kailangan ng tulong.",
                        "Pakiusap, nasa lupa pa rin ako at naghihintay.",
                        "Hindi pa rin makatayo. Huwag mong kalimutang bagsak ako.",
                        "Nandito pa rin ako! Tulungan mo na akong tumayo!",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_repeat",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress.repeat.dehydration",
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
                                ["fallback"] = "I still need water to recover. My throat is on fire.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.medical.distress.repeat.dehydration.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I still need water to recover. My throat is on fire.",
                                        "Still dying of thirst... did you find any bottle?",
                                        "Water, please! I can't take this parched feeling.",
                                        "I asked for water... please tell me you have some.",
                                        "Tongue feels like sandpaper. Bring water quickly.",
                                        "Still completely dehydrated. I can't stand up like this.",
                                        "Water... I'm begging you, just one cup.",
                                        "Still dry as bone. Please bring hydration.",
                                        "I can't recover without liquids. Help me.",
                                        "Still waiting for a drink... head is pounding.",
                                    },
                                    ["TL"] = {
                                        "Kailangan ko pa rin ng tubig para makabawi. Parang may apoy sa lalamunan ko.",
                                        "Mamamatay pa rin sa uhaw... may nahanap ka bang bote?",
                                        "Tubig, pakiusap! Hindi ko na makayanan ang matinding uhaw.",
                                        "Humihingi ako ng tubig... sabihin mong may dala ka.",
                                        "Parang liha ang dila ko. Magdala ka ng tubig agad.",
                                        "Dehydrated pa rin ako. Hindi ako makakatayo nang ganito.",
                                        "Tubig... nagmamakaawa ako, kahit isang baso lang.",
                                        "Tuyot pa rin ako. Pakiusap dalhan mo ako ng tubig.",
                                        "Hindi ako makakabawi nang walang inumin. Tulong.",
                                        "Naghihintay pa rin ng maiinom... sumasakit ang ulo ko.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.distress.repeat",
            ["textRoles"] = {
                {
                    ["fallback"] = "I still need water to recover. My throat is on fire.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.repeat.dehydration.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I still need water to recover. My throat is on fire.",
                            "Still dying of thirst... did you find any bottle?",
                            "Water, please! I can't take this parched feeling.",
                            "I asked for water... please tell me you have some.",
                            "Tongue feels like sandpaper. Bring water quickly.",
                            "Still completely dehydrated. I can't stand up like this.",
                            "Water... I'm begging you, just one cup.",
                            "Still dry as bone. Please bring hydration.",
                            "I can't recover without liquids. Help me.",
                            "Still waiting for a drink... head is pounding.",
                        },
                        ["TL"] = {
                            "Kailangan ko pa rin ng tubig para makabawi. Parang may apoy sa lalamunan ko.",
                            "Mamamatay pa rin sa uhaw... may nahanap ka bang bote?",
                            "Tubig, pakiusap! Hindi ko na makayanan ang matinding uhaw.",
                            "Humihingi ako ng tubig... sabihin mong may dala ka.",
                            "Parang liha ang dila ko. Magdala ka ng tubig agad.",
                            "Dehydrated pa rin ako. Hindi ako makakatayo nang ganito.",
                            "Tubig... nagmamakaawa ako, kahit isang baso lang.",
                            "Tuyot pa rin ako. Pakiusap dalhan mo ako ng tubig.",
                            "Hindi ako makakabawi nang walang inumin. Tulong.",
                            "Naghihintay pa rin ng maiinom... sumasakit ang ulo ko.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "medical.distress.repeat.dehydration",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "dehydration",
            ["sourceId"] = "medical.distress.repeat.dehydration",
            ["sourcePath"] = "adopters/hoomans/dialogue/medical_event_repeat/medical_distress_repeat_dehydration.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalEventRepeat",
        ["namespace"] = "medical.distress.repeat",
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
                ["sourceSurface"] = "content/event/medical/repeat.json",
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
                                        "I still need water to recover. My throat is on fire.",
                                        "Still dying of thirst... did you find any bottle?",
                                        "Water, please! I can't take this parched feeling.",
                                        "I asked for water... please tell me you have some.",
                                        "Tongue feels like sandpaper. Bring water quickly.",
                                        "Still completely dehydrated. I can't stand up like this.",
                                        "Water... I'm begging you, just one cup.",
                                        "Still dry as bone. Please bring hydration.",
                                        "I can't recover without liquids. Help me.",
                                        "Still waiting for a drink... head is pounding.",
                                    },
                                    ["TL"] = {
                                        "Kailangan ko pa rin ng tubig para makabawi. Parang may apoy sa lalamunan ko.",
                                        "Mamamatay pa rin sa uhaw... may nahanap ka bang bote?",
                                        "Tubig, pakiusap! Hindi ko na makayanan ang matinding uhaw.",
                                        "Humihingi ako ng tubig... sabihin mong may dala ka.",
                                        "Parang liha ang dila ko. Magdala ka ng tubig agad.",
                                        "Dehydrated pa rin ako. Hindi ako makakatayo nang ganito.",
                                        "Tubig... nagmamakaawa ako, kahit isang baso lang.",
                                        "Tuyot pa rin ako. Pakiusap dalhan mo ako ng tubig.",
                                        "Hindi ako makakabawi nang walang inumin. Tulong.",
                                        "Naghihintay pa rin ng maiinom... sumasakit ang ulo ko.",
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
            ["responsePlanID"] = "medical.distress.repeat.dehydration",
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
                            ["fallback"] = "I still need water to recover. My throat is on fire.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.medical.distress.repeat.dehydration.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/medical_event_repeat/medical_distress_repeat_dehydration.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I still need water to recover. My throat is on fire.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.repeat.dehydration.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I still need water to recover. My throat is on fire.",
                        "Still dying of thirst... did you find any bottle?",
                        "Water, please! I can't take this parched feeling.",
                        "I asked for water... please tell me you have some.",
                        "Tongue feels like sandpaper. Bring water quickly.",
                        "Still completely dehydrated. I can't stand up like this.",
                        "Water... I'm begging you, just one cup.",
                        "Still dry as bone. Please bring hydration.",
                        "I can't recover without liquids. Help me.",
                        "Still waiting for a drink... head is pounding.",
                    },
                    ["TL"] = {
                        "Kailangan ko pa rin ng tubig para makabawi. Parang may apoy sa lalamunan ko.",
                        "Mamamatay pa rin sa uhaw... may nahanap ka bang bote?",
                        "Tubig, pakiusap! Hindi ko na makayanan ang matinding uhaw.",
                        "Humihingi ako ng tubig... sabihin mong may dala ka.",
                        "Parang liha ang dila ko. Magdala ka ng tubig agad.",
                        "Dehydrated pa rin ako. Hindi ako makakatayo nang ganito.",
                        "Tubig... nagmamakaawa ako, kahit isang baso lang.",
                        "Tuyot pa rin ako. Pakiusap dalhan mo ako ng tubig.",
                        "Hindi ako makakabawi nang walang inumin. Tulong.",
                        "Naghihintay pa rin ng maiinom... sumasakit ang ulo ko.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_repeat",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress.repeat.exhaustion",
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
                                ["fallback"] = "I still need a little more time to recover.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.medical.distress.repeat.exhaustion.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I still need a little more time to recover.",
                                        "Can't rush this. My muscles are completely dead.",
                                        "Still catching my breath. Give me another minute.",
                                        "Body won't budge yet. Just a bit more rest.",
                                        "Still wiped out. Don't force me to stand yet.",
                                        "Heart is still racing. Need more time sitting down.",
                                        "Not ready to move yet. Fatigue is overwhelming.",
                                        "Give me another thirty seconds... almost there.",
                                        "Still completely spent. Let my legs rest.",
                                        "Can't run yet. Need a little more recovery.",
                                    },
                                    ["TL"] = {
                                        "Kailangan ko pa ng kaunting oras para makabawi.",
                                        "Hindi pwedeng madaliin. Patay na ang lakas ng kalamnan ko.",
                                        "Hinihingal pa rin ako. Bigyan mo pa ako ng isang minuto.",
                                        "Ayaw pang gumalaw ng katawan ko. Kaunting pahinga pa.",
                                        "Ubos pa rin ako. Huwag mo muna akong piliting tumayo.",
                                        "Mabilis pa rin ang kabog ng dibdib ko. Kailangan pang umupo.",
                                        "Hindi pa handang kumilos. Masyadong mabigat ang pagod.",
                                        "Bigyan mo pa ako ng tatlumpung segundo... malapit na.",
                                        "Sagad pa rin ang pagod. Pahingahin mo muna ang mga binti ko.",
                                        "Hindi pa makakatakbo. Kailangan pa ng kaunting lakas.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.distress.repeat",
            ["textRoles"] = {
                {
                    ["fallback"] = "I still need a little more time to recover.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.repeat.exhaustion.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I still need a little more time to recover.",
                            "Can't rush this. My muscles are completely dead.",
                            "Still catching my breath. Give me another minute.",
                            "Body won't budge yet. Just a bit more rest.",
                            "Still wiped out. Don't force me to stand yet.",
                            "Heart is still racing. Need more time sitting down.",
                            "Not ready to move yet. Fatigue is overwhelming.",
                            "Give me another thirty seconds... almost there.",
                            "Still completely spent. Let my legs rest.",
                            "Can't run yet. Need a little more recovery.",
                        },
                        ["TL"] = {
                            "Kailangan ko pa ng kaunting oras para makabawi.",
                            "Hindi pwedeng madaliin. Patay na ang lakas ng kalamnan ko.",
                            "Hinihingal pa rin ako. Bigyan mo pa ako ng isang minuto.",
                            "Ayaw pang gumalaw ng katawan ko. Kaunting pahinga pa.",
                            "Ubos pa rin ako. Huwag mo muna akong piliting tumayo.",
                            "Mabilis pa rin ang kabog ng dibdib ko. Kailangan pang umupo.",
                            "Hindi pa handang kumilos. Masyadong mabigat ang pagod.",
                            "Bigyan mo pa ako ng tatlumpung segundo... malapit na.",
                            "Sagad pa rin ang pagod. Pahingahin mo muna ang mga binti ko.",
                            "Hindi pa makakatakbo. Kailangan pa ng kaunting lakas.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "medical.distress.repeat.exhaustion",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "exhaustion",
            ["sourceId"] = "medical.distress.repeat.exhaustion",
            ["sourcePath"] = "adopters/hoomans/dialogue/medical_event_repeat/medical_distress_repeat_exhaustion.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalEventRepeat",
        ["namespace"] = "medical.distress.repeat",
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
                ["sourceSurface"] = "content/event/medical/repeat.json",
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
                                        "I still need a little more time to recover.",
                                        "Can't rush this. My muscles are completely dead.",
                                        "Still catching my breath. Give me another minute.",
                                        "Body won't budge yet. Just a bit more rest.",
                                        "Still wiped out. Don't force me to stand yet.",
                                        "Heart is still racing. Need more time sitting down.",
                                        "Not ready to move yet. Fatigue is overwhelming.",
                                        "Give me another thirty seconds... almost there.",
                                        "Still completely spent. Let my legs rest.",
                                        "Can't run yet. Need a little more recovery.",
                                    },
                                    ["TL"] = {
                                        "Kailangan ko pa ng kaunting oras para makabawi.",
                                        "Hindi pwedeng madaliin. Patay na ang lakas ng kalamnan ko.",
                                        "Hinihingal pa rin ako. Bigyan mo pa ako ng isang minuto.",
                                        "Ayaw pang gumalaw ng katawan ko. Kaunting pahinga pa.",
                                        "Ubos pa rin ako. Huwag mo muna akong piliting tumayo.",
                                        "Mabilis pa rin ang kabog ng dibdib ko. Kailangan pang umupo.",
                                        "Hindi pa handang kumilos. Masyadong mabigat ang pagod.",
                                        "Bigyan mo pa ako ng tatlumpung segundo... malapit na.",
                                        "Sagad pa rin ang pagod. Pahingahin mo muna ang mga binti ko.",
                                        "Hindi pa makakatakbo. Kailangan pa ng kaunting lakas.",
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
            ["responsePlanID"] = "medical.distress.repeat.exhaustion",
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
                            ["fallback"] = "I still need a little more time to recover.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.medical.distress.repeat.exhaustion.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/medical_event_repeat/medical_distress_repeat_exhaustion.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I still need a little more time to recover.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.repeat.exhaustion.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I still need a little more time to recover.",
                        "Can't rush this. My muscles are completely dead.",
                        "Still catching my breath. Give me another minute.",
                        "Body won't budge yet. Just a bit more rest.",
                        "Still wiped out. Don't force me to stand yet.",
                        "Heart is still racing. Need more time sitting down.",
                        "Not ready to move yet. Fatigue is overwhelming.",
                        "Give me another thirty seconds... almost there.",
                        "Still completely spent. Let my legs rest.",
                        "Can't run yet. Need a little more recovery.",
                    },
                    ["TL"] = {
                        "Kailangan ko pa ng kaunting oras para makabawi.",
                        "Hindi pwedeng madaliin. Patay na ang lakas ng kalamnan ko.",
                        "Hinihingal pa rin ako. Bigyan mo pa ako ng isang minuto.",
                        "Ayaw pang gumalaw ng katawan ko. Kaunting pahinga pa.",
                        "Ubos pa rin ako. Huwag mo muna akong piliting tumayo.",
                        "Mabilis pa rin ang kabog ng dibdib ko. Kailangan pang umupo.",
                        "Hindi pa handang kumilos. Masyadong mabigat ang pagod.",
                        "Bigyan mo pa ako ng tatlumpung segundo... malapit na.",
                        "Sagad pa rin ang pagod. Pahingahin mo muna ang mga binti ko.",
                        "Hindi pa makakatakbo. Kailangan pa ng kaunting lakas.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_repeat",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress.repeat.mercy",
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
                                ["fallback"] = "I am still asking you to spare me. Please.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.medical.distress.repeat.mercy.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I am still asking you to spare me. Please.",
                                        "Please don't change your mind... let me live.",
                                        "I'm still begging for mercy. Don't shoot.",
                                        "Show mercy once more. I mean you no harm.",
                                        "I am defenseless. Please keep your weapon down.",
                                        "Don't finish me off. I surrender completely.",
                                        "Still pleading for my life. Have pity on me.",
                                        "Please... I just want to survive.",
                                        "I'm at your feet. Spare me, I beg you.",
                                        "Don't execute me. Let me crawl away.",
                                    },
                                    ["TL"] = {
                                        "Hinihiling ko pa rin na buhayin mo ako. Pakiusap.",
                                        "Pakiusap huwag magbago ang isip mo... hayaan mo akong mabuhay.",
                                        "Nagmamakaawa pa rin ako sa awa. Huwag kang bumaril.",
                                        "Maawa ka pa ulit. Wala akong masamang balak sa'yo.",
                                        "Wala akong laban. Pakiusap ibaba mo ang sandata mo.",
                                        "Huwag mo akong tapusin. Sumusuko ako nang buo.",
                                        "Nagmamakaawa pa rin para sa buhay ko. Kaawaan mo ako.",
                                        "Pakiusap... gusto ko lang mabuhay.",
                                        "Nasa paanan mo na ako. Huwag mo akong patayin, nagmamakaawa ako.",
                                        "Huwag mo akong patayin. Hayaan mo akong gumapang palayo.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.distress.repeat",
            ["textRoles"] = {
                {
                    ["fallback"] = "I am still asking you to spare me. Please.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.repeat.mercy.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I am still asking you to spare me. Please.",
                            "Please don't change your mind... let me live.",
                            "I'm still begging for mercy. Don't shoot.",
                            "Show mercy once more. I mean you no harm.",
                            "I am defenseless. Please keep your weapon down.",
                            "Don't finish me off. I surrender completely.",
                            "Still pleading for my life. Have pity on me.",
                            "Please... I just want to survive.",
                            "I'm at your feet. Spare me, I beg you.",
                            "Don't execute me. Let me crawl away.",
                        },
                        ["TL"] = {
                            "Hinihiling ko pa rin na buhayin mo ako. Pakiusap.",
                            "Pakiusap huwag magbago ang isip mo... hayaan mo akong mabuhay.",
                            "Nagmamakaawa pa rin ako sa awa. Huwag kang bumaril.",
                            "Maawa ka pa ulit. Wala akong masamang balak sa'yo.",
                            "Wala akong laban. Pakiusap ibaba mo ang sandata mo.",
                            "Huwag mo akong tapusin. Sumusuko ako nang buo.",
                            "Nagmamakaawa pa rin para sa buhay ko. Kaawaan mo ako.",
                            "Pakiusap... gusto ko lang mabuhay.",
                            "Nasa paanan mo na ako. Huwag mo akong patayin, nagmamakaawa ako.",
                            "Huwag mo akong patayin. Hayaan mo akong gumapang palayo.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "medical.distress.repeat.mercy",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "mercy",
            ["sourceId"] = "medical.distress.repeat.mercy",
            ["sourcePath"] = "adopters/hoomans/dialogue/medical_event_repeat/medical_distress_repeat_mercy.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalEventRepeat",
        ["namespace"] = "medical.distress.repeat",
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
                ["sourceSurface"] = "content/event/medical/repeat.json",
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
                                        "I am still asking you to spare me. Please.",
                                        "Please don't change your mind... let me live.",
                                        "I'm still begging for mercy. Don't shoot.",
                                        "Show mercy once more. I mean you no harm.",
                                        "I am defenseless. Please keep your weapon down.",
                                        "Don't finish me off. I surrender completely.",
                                        "Still pleading for my life. Have pity on me.",
                                        "Please... I just want to survive.",
                                        "I'm at your feet. Spare me, I beg you.",
                                        "Don't execute me. Let me crawl away.",
                                    },
                                    ["TL"] = {
                                        "Hinihiling ko pa rin na buhayin mo ako. Pakiusap.",
                                        "Pakiusap huwag magbago ang isip mo... hayaan mo akong mabuhay.",
                                        "Nagmamakaawa pa rin ako sa awa. Huwag kang bumaril.",
                                        "Maawa ka pa ulit. Wala akong masamang balak sa'yo.",
                                        "Wala akong laban. Pakiusap ibaba mo ang sandata mo.",
                                        "Huwag mo akong tapusin. Sumusuko ako nang buo.",
                                        "Nagmamakaawa pa rin para sa buhay ko. Kaawaan mo ako.",
                                        "Pakiusap... gusto ko lang mabuhay.",
                                        "Nasa paanan mo na ako. Huwag mo akong patayin, nagmamakaawa ako.",
                                        "Huwag mo akong patayin. Hayaan mo akong gumapang palayo.",
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
            ["responsePlanID"] = "medical.distress.repeat.mercy",
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
                            ["fallback"] = "I am still asking you to spare me. Please.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.medical.distress.repeat.mercy.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/medical_event_repeat/medical_distress_repeat_mercy.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I am still asking you to spare me. Please.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.repeat.mercy.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I am still asking you to spare me. Please.",
                        "Please don't change your mind... let me live.",
                        "I'm still begging for mercy. Don't shoot.",
                        "Show mercy once more. I mean you no harm.",
                        "I am defenseless. Please keep your weapon down.",
                        "Don't finish me off. I surrender completely.",
                        "Still pleading for my life. Have pity on me.",
                        "Please... I just want to survive.",
                        "I'm at your feet. Spare me, I beg you.",
                        "Don't execute me. Let me crawl away.",
                    },
                    ["TL"] = {
                        "Hinihiling ko pa rin na buhayin mo ako. Pakiusap.",
                        "Pakiusap huwag magbago ang isip mo... hayaan mo akong mabuhay.",
                        "Nagmamakaawa pa rin ako sa awa. Huwag kang bumaril.",
                        "Maawa ka pa ulit. Wala akong masamang balak sa'yo.",
                        "Wala akong laban. Pakiusap ibaba mo ang sandata mo.",
                        "Huwag mo akong tapusin. Sumusuko ako nang buo.",
                        "Nagmamakaawa pa rin para sa buhay ko. Kaawaan mo ako.",
                        "Pakiusap... gusto ko lang mabuhay.",
                        "Nasa paanan mo na ako. Huwag mo akong patayin, nagmamakaawa ako.",
                        "Huwag mo akong patayin. Hayaan mo akong gumapang palayo.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_repeat",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress.repeat.rescue",
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
                                ["fallback"] = "I am still down here! Do not leave me!",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.medical.distress.repeat.rescue.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I am still down here! Do not leave me!",
                                        "Don't abandon me! Come back and pull me out!",
                                        "Still trapped in this spot! Need someone here!",
                                        "Where are you going?! I can't walk!",
                                        "Please come back! I'm completely stranded!",
                                        "Don't walk away from my cries! Help me!",
                                        "Still stuck under this weight! Lift it off!",
                                        "I'm still here! Get me out before they find me!",
                                        "Rescue me, damn it! I can't drag myself!",
                                        "Don't leave me behind to rot! Come back!",
                                    },
                                    ["TL"] = {
                                        "Nandito pa rin ako sa sahig! Huwag niyo akong iwan!",
                                        "Huwag niyo akong iwanan! Bumalik kayo at hilahin ako palabas!",
                                        "Naipit pa rin sa pwestong 'to! Kailangan ko ng tao rito!",
                                        "Saan ka pupunta?! Hindi ako makalakad!",
                                        "Pakiusap bumalik ka! Nastranded ako nang buo!",
                                        "Huwag mong talikuran ang tawag ko! Tulungan mo ako!",
                                        "Naipit pa rin sa bigat na 'to! Buhatin mo 'to!",
                                        "Nandito pa rin ako! Ilabas mo ako bago nila ako makita!",
                                        "Saklolohan mo ako! Hindi ko kayang kaladkarin ang sarili ko!",
                                        "Huwag mo akong iwang mabulok dito! Bumalik ka!",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.distress.repeat",
            ["textRoles"] = {
                {
                    ["fallback"] = "I am still down here! Do not leave me!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.repeat.rescue.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I am still down here! Do not leave me!",
                            "Don't abandon me! Come back and pull me out!",
                            "Still trapped in this spot! Need someone here!",
                            "Where are you going?! I can't walk!",
                            "Please come back! I'm completely stranded!",
                            "Don't walk away from my cries! Help me!",
                            "Still stuck under this weight! Lift it off!",
                            "I'm still here! Get me out before they find me!",
                            "Rescue me, damn it! I can't drag myself!",
                            "Don't leave me behind to rot! Come back!",
                        },
                        ["TL"] = {
                            "Nandito pa rin ako sa sahig! Huwag niyo akong iwan!",
                            "Huwag niyo akong iwanan! Bumalik kayo at hilahin ako palabas!",
                            "Naipit pa rin sa pwestong 'to! Kailangan ko ng tao rito!",
                            "Saan ka pupunta?! Hindi ako makalakad!",
                            "Pakiusap bumalik ka! Nastranded ako nang buo!",
                            "Huwag mong talikuran ang tawag ko! Tulungan mo ako!",
                            "Naipit pa rin sa bigat na 'to! Buhatin mo 'to!",
                            "Nandito pa rin ako! Ilabas mo ako bago nila ako makita!",
                            "Saklolohan mo ako! Hindi ko kayang kaladkarin ang sarili ko!",
                            "Huwag mo akong iwang mabulok dito! Bumalik ka!",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "medical.distress.repeat.rescue",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "rescue",
            ["sourceId"] = "medical.distress.repeat.rescue",
            ["sourcePath"] = "adopters/hoomans/dialogue/medical_event_repeat/medical_distress_repeat_rescue.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalEventRepeat",
        ["namespace"] = "medical.distress.repeat",
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
                ["sourceSurface"] = "content/event/medical/repeat.json",
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
                                        "I am still down here! Do not leave me!",
                                        "Don't abandon me! Come back and pull me out!",
                                        "Still trapped in this spot! Need someone here!",
                                        "Where are you going?! I can't walk!",
                                        "Please come back! I'm completely stranded!",
                                        "Don't walk away from my cries! Help me!",
                                        "Still stuck under this weight! Lift it off!",
                                        "I'm still here! Get me out before they find me!",
                                        "Rescue me, damn it! I can't drag myself!",
                                        "Don't leave me behind to rot! Come back!",
                                    },
                                    ["TL"] = {
                                        "Nandito pa rin ako sa sahig! Huwag niyo akong iwan!",
                                        "Huwag niyo akong iwanan! Bumalik kayo at hilahin ako palabas!",
                                        "Naipit pa rin sa pwestong 'to! Kailangan ko ng tao rito!",
                                        "Saan ka pupunta?! Hindi ako makalakad!",
                                        "Pakiusap bumalik ka! Nastranded ako nang buo!",
                                        "Huwag mong talikuran ang tawag ko! Tulungan mo ako!",
                                        "Naipit pa rin sa bigat na 'to! Buhatin mo 'to!",
                                        "Nandito pa rin ako! Ilabas mo ako bago nila ako makita!",
                                        "Saklolohan mo ako! Hindi ko kayang kaladkarin ang sarili ko!",
                                        "Huwag mo akong iwang mabulok dito! Bumalik ka!",
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
            ["responsePlanID"] = "medical.distress.repeat.rescue",
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
                            ["fallback"] = "I am still down here! Do not leave me!",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.medical.distress.repeat.rescue.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/medical_event_repeat/medical_distress_repeat_rescue.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I am still down here! Do not leave me!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.repeat.rescue.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I am still down here! Do not leave me!",
                        "Don't abandon me! Come back and pull me out!",
                        "Still trapped in this spot! Need someone here!",
                        "Where are you going?! I can't walk!",
                        "Please come back! I'm completely stranded!",
                        "Don't walk away from my cries! Help me!",
                        "Still stuck under this weight! Lift it off!",
                        "I'm still here! Get me out before they find me!",
                        "Rescue me, damn it! I can't drag myself!",
                        "Don't leave me behind to rot! Come back!",
                    },
                    ["TL"] = {
                        "Nandito pa rin ako sa sahig! Huwag niyo akong iwan!",
                        "Huwag niyo akong iwanan! Bumalik kayo at hilahin ako palabas!",
                        "Naipit pa rin sa pwestong 'to! Kailangan ko ng tao rito!",
                        "Saan ka pupunta?! Hindi ako makalakad!",
                        "Pakiusap bumalik ka! Nastranded ako nang buo!",
                        "Huwag mong talikuran ang tawag ko! Tulungan mo ako!",
                        "Naipit pa rin sa bigat na 'to! Buhatin mo 'to!",
                        "Nandito pa rin ako! Ilabas mo ako bago nila ako makita!",
                        "Saklolohan mo ako! Hindi ko kayang kaladkarin ang sarili ko!",
                        "Huwag mo akong iwang mabulok dito! Bumalik ka!",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_repeat",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress.repeat.starvation",
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
                                ["fallback"] = "I still need something to eat. I'm fading fast.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.medical.distress.repeat.starvation.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I still need something to eat. I'm fading fast.",
                                        "Still starving... any canned food, anything?",
                                        "Can't recover without calories. Bring food, please.",
                                        "Stomach pains won't stop. I need nourishment.",
                                        "Still starving to the bone. Did you find a ration?",
                                        "Please hurry with some food. I'm too dizzy to stand.",
                                        "Hunger is unbearable now. Help me.",
                                        "Still haven't eaten. Don't let me starve on this floor.",
                                        "Need a meal to get back on my feet.",
                                        "Still empty... please, just a cracker or some beans.",
                                    },
                                    ["TL"] = {
                                        "Kailangan ko pa rin ng makakain. Mabilis akong nanghihina.",
                                        "Gutom na gutom pa rin... kahit anong de-lata, kahit ano?",
                                        "Hindi makakabawi nang walang laman ang tiyan. Magdala ka ng pagkain.",
                                        "Ayaw tumigil ng sakit ng tiyan ko. Kailangan ko ng pagkain.",
                                        "Gutom na gutom pa rin hanggang buto. May nahanap ka bang rasyon?",
                                        "Pakiusap bilisan ang pagkain. Nahihilo na ako para makatayo.",
                                        "Hindi na makayanan ang gutom. Tulungan mo ako.",
                                        "Wala pa ring kinakain. Huwag mo akong hayaang magutom sa sahig.",
                                        "Kailangan ko ng makakain para makatayo ulit.",
                                        "Walang laman pa rin... kahit biskwit o kaunting beans lang.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.distress.repeat",
            ["textRoles"] = {
                {
                    ["fallback"] = "I still need something to eat. I'm fading fast.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.repeat.starvation.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I still need something to eat. I'm fading fast.",
                            "Still starving... any canned food, anything?",
                            "Can't recover without calories. Bring food, please.",
                            "Stomach pains won't stop. I need nourishment.",
                            "Still starving to the bone. Did you find a ration?",
                            "Please hurry with some food. I'm too dizzy to stand.",
                            "Hunger is unbearable now. Help me.",
                            "Still haven't eaten. Don't let me starve on this floor.",
                            "Need a meal to get back on my feet.",
                            "Still empty... please, just a cracker or some beans.",
                        },
                        ["TL"] = {
                            "Kailangan ko pa rin ng makakain. Mabilis akong nanghihina.",
                            "Gutom na gutom pa rin... kahit anong de-lata, kahit ano?",
                            "Hindi makakabawi nang walang laman ang tiyan. Magdala ka ng pagkain.",
                            "Ayaw tumigil ng sakit ng tiyan ko. Kailangan ko ng pagkain.",
                            "Gutom na gutom pa rin hanggang buto. May nahanap ka bang rasyon?",
                            "Pakiusap bilisan ang pagkain. Nahihilo na ako para makatayo.",
                            "Hindi na makayanan ang gutom. Tulungan mo ako.",
                            "Wala pa ring kinakain. Huwag mo akong hayaang magutom sa sahig.",
                            "Kailangan ko ng makakain para makatayo ulit.",
                            "Walang laman pa rin... kahit biskwit o kaunting beans lang.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "medical.distress.repeat.starvation",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "starvation",
            ["sourceId"] = "medical.distress.repeat.starvation",
            ["sourcePath"] = "adopters/hoomans/dialogue/medical_event_repeat/medical_distress_repeat_starvation.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalEventRepeat",
        ["namespace"] = "medical.distress.repeat",
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
                ["sourceSurface"] = "content/event/medical/repeat.json",
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
                                        "I still need something to eat. I'm fading fast.",
                                        "Still starving... any canned food, anything?",
                                        "Can't recover without calories. Bring food, please.",
                                        "Stomach pains won't stop. I need nourishment.",
                                        "Still starving to the bone. Did you find a ration?",
                                        "Please hurry with some food. I'm too dizzy to stand.",
                                        "Hunger is unbearable now. Help me.",
                                        "Still haven't eaten. Don't let me starve on this floor.",
                                        "Need a meal to get back on my feet.",
                                        "Still empty... please, just a cracker or some beans.",
                                    },
                                    ["TL"] = {
                                        "Kailangan ko pa rin ng makakain. Mabilis akong nanghihina.",
                                        "Gutom na gutom pa rin... kahit anong de-lata, kahit ano?",
                                        "Hindi makakabawi nang walang laman ang tiyan. Magdala ka ng pagkain.",
                                        "Ayaw tumigil ng sakit ng tiyan ko. Kailangan ko ng pagkain.",
                                        "Gutom na gutom pa rin hanggang buto. May nahanap ka bang rasyon?",
                                        "Pakiusap bilisan ang pagkain. Nahihilo na ako para makatayo.",
                                        "Hindi na makayanan ang gutom. Tulungan mo ako.",
                                        "Wala pa ring kinakain. Huwag mo akong hayaang magutom sa sahig.",
                                        "Kailangan ko ng makakain para makatayo ulit.",
                                        "Walang laman pa rin... kahit biskwit o kaunting beans lang.",
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
            ["responsePlanID"] = "medical.distress.repeat.starvation",
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
                            ["fallback"] = "I still need something to eat. I'm fading fast.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.medical.distress.repeat.starvation.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/medical_event_repeat/medical_distress_repeat_starvation.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I still need something to eat. I'm fading fast.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.repeat.starvation.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I still need something to eat. I'm fading fast.",
                        "Still starving... any canned food, anything?",
                        "Can't recover without calories. Bring food, please.",
                        "Stomach pains won't stop. I need nourishment.",
                        "Still starving to the bone. Did you find a ration?",
                        "Please hurry with some food. I'm too dizzy to stand.",
                        "Hunger is unbearable now. Help me.",
                        "Still haven't eaten. Don't let me starve on this floor.",
                        "Need a meal to get back on my feet.",
                        "Still empty... please, just a cracker or some beans.",
                    },
                    ["TL"] = {
                        "Kailangan ko pa rin ng makakain. Mabilis akong nanghihina.",
                        "Gutom na gutom pa rin... kahit anong de-lata, kahit ano?",
                        "Hindi makakabawi nang walang laman ang tiyan. Magdala ka ng pagkain.",
                        "Ayaw tumigil ng sakit ng tiyan ko. Kailangan ko ng pagkain.",
                        "Gutom na gutom pa rin hanggang buto. May nahanap ka bang rasyon?",
                        "Pakiusap bilisan ang pagkain. Nahihilo na ako para makatayo.",
                        "Hindi na makayanan ang gutom. Tulungan mo ako.",
                        "Wala pa ring kinakain. Huwag mo akong hayaang magutom sa sahig.",
                        "Kailangan ko ng makakain para makatayo ulit.",
                        "Walang laman pa rin... kahit biskwit o kaunting beans lang.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
