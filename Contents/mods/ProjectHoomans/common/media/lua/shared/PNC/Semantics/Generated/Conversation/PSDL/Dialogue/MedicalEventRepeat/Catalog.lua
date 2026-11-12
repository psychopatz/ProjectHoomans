-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "medical_event_repeat",
        ["id"] = "semantic.medical.distress.repeat.bandage",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.repeat.bandage",
            ["sourcePath"] = "psdl/dialogue/medical_event_repeat.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/MedicalEventRepeat/Catalog",
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
                ["responseTemplateID"] = "semantic.medical.distress.repeat.bandage",
                ["sourceSurface"] = "content/event/medical/repeat.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bandage.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I still need these wounds patched! Hurry!",
                            },
                            ["TL"] = {
                                "Kailangan ko pa ring mabendahan ang sugat na 'to! Bilis!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bandage.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Where's that bandage?! Still bleeding out here!",
                            },
                            ["TL"] = {
                                "Nasaan na 'yung benda?! Dumurugo pa rin ako rito!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bandage.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't forget about me! I need a wrap now!",
                            },
                            ["TL"] = {
                                "Huwag niyo akong kalimutan! Kailangan ko ng benda ngayon!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bandage.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still waiting on that bandage! It's soaking through!",
                            },
                            ["TL"] = {
                                "Naghihintay pa rin ako sa benda! Bumababad na ang dugo!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bandage.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Please, hurry with the bandages! I'm fading!",
                            },
                            ["TL"] = {
                                "Pakiusap, bilisan ang benda! Nanghihina na ako!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bandage.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I asked for a bandage! Did you find one?!",
                            },
                            ["TL"] = {
                                "Humihingi ako ng benda! May nahanap ka ba?!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bandage.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Wound is still open! Bring the dressing over!",
                            },
                            ["TL"] = {
                                "Bukas pa rin ang sugat! Dalhin mo na ang pambenda!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bandage.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Can someone please patch me up already?!",
                            },
                            ["TL"] = {
                                "May magbe-benda ba sa akin ngayon din?!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bandage.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Blood is still pooling! Get that bandage on me!",
                            },
                            ["TL"] = {
                                "Nag-iipon pa rin ang dugo! Ilagay mo na ang benda sa akin!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bandage.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still bleeding here! Hurry with the cloth!",
                            },
                            ["TL"] = {
                                "Dumurugo pa rin ako rito! Bilisan mo ang tela!",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_repeat.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_repeat",
        ["id"] = "semantic.medical.distress.repeat.bleedout",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.repeat.bleedout",
            ["sourcePath"] = "psdl/dialogue/medical_event_repeat.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/MedicalEventRepeat/Catalog",
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
                ["responseTemplateID"] = "semantic.medical.distress.repeat.bleedout",
                ["sourceSurface"] = "content/event/medical/repeat.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bleedout.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I am still losing blood! Please, help me!",
                            },
                            ["TL"] = {
                                "Nauubusan pa rin ako ng dugo! Pakiusap, tulungan mo ako!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bleedout.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Pressure isn't working! The bleeding won't stop!",
                            },
                            ["TL"] = {
                                "Hindi gumagana ang diin! Ayaw tumigil ng pagdurugo!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bleedout.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I don't have much time left... blood is gushing!",
                            },
                            ["TL"] = {
                                "Wala na akong gaanong oras... bumubuhos ang dugo!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bleedout.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Hurry, damn it! I'm going to bleed to death!",
                            },
                            ["TL"] = {
                                "Bilisan mo naman! Mamamatay na ako sa pagdurugo!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bleedout.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "My pulse is getting weak... stop the bleed!",
                            },
                            ["TL"] = {
                                "Humihina na ang pulso ko... patigilin ang pagdurugo!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bleedout.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still bleeding out! Don't let me die on this floor!",
                            },
                            ["TL"] = {
                                "Nauubusan pa rin ng dugo! Huwag mo akong hayaang mamatay sa sahig!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bleedout.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm freezing cold from blood loss... hurry!",
                            },
                            ["TL"] = {
                                "Giniginaw na ako sa nawalang dugo... bilisan mo!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bleedout.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Blood won't clot! I need immediate help!",
                            },
                            ["TL"] = {
                                "Ayaw mamuo ng dugo! Kailangan ko ng agarang tulong!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bleedout.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Everything is fading... stop the bleeding, please!",
                            },
                            ["TL"] = {
                                "Naglalaho ang lahat... patigilin mo ang dugo, pakiusap!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bleedout.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Hurry up! I can't hold my own artery closed!",
                            },
                            ["TL"] = {
                                "Bilisan mo! Hindi ko kayang pigilin ang ugat ko nang mag-isa!",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_repeat.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_repeat",
        ["id"] = "semantic.medical.distress.repeat.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.repeat.default",
            ["sourcePath"] = "psdl/dialogue/medical_event_repeat.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/MedicalEventRepeat/Catalog",
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
                ["responseTemplateID"] = "semantic.medical.distress.repeat.default",
                ["sourceSurface"] = "content/event/medical/repeat.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.default.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm not up yet. Please help me.",
                            },
                            ["TL"] = {
                                "Hindi pa ako nakakabangon. Pakiusap tulungan mo ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.default.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still down here! Don't leave me behind!",
                            },
                            ["TL"] = {
                                "Nandito pa rin ako sa sahig! Huwag mo akong iwan!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.default.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I still need assistance to get on my feet.",
                            },
                            ["TL"] = {
                                "Kailangan ko pa rin ng tulong para makatayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.default.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Can someone help me up? Still grounded.",
                            },
                            ["TL"] = {
                                "May tutulong ba sa aking tumayo? Bagsak pa rin ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.default.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm still incapacitated! Come over here!",
                            },
                            ["TL"] = {
                                "Hindi pa rin ako makakilos! Pumunta ka rito!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.default.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still hurting, still stuck. Give me a hand.",
                            },
                            ["TL"] = {
                                "Masakit pa rin, naipit pa rin. Tulungan mo ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.default.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Haven't moved an inch. Need someone to help.",
                            },
                            ["TL"] = {
                                "Hindi pa ako nakakagalaw kahit kaunti. Kailangan ng tulong.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.default.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Please, I'm still on the ground waiting.",
                            },
                            ["TL"] = {
                                "Pakiusap, nasa lupa pa rin ako at naghihintay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.default.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still can't stand. Don't forget I'm down.",
                            },
                            ["TL"] = {
                                "Hindi pa rin makatayo. Huwag mong kalimutang bagsak ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.default.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm still here! Help me up already!",
                            },
                            ["TL"] = {
                                "Nandito pa rin ako! Tulungan mo na akong tumayo!",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_repeat.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_repeat",
        ["id"] = "semantic.medical.distress.repeat.dehydration",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.repeat.dehydration",
            ["sourcePath"] = "psdl/dialogue/medical_event_repeat.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/MedicalEventRepeat/Catalog",
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
                ["responseTemplateID"] = "semantic.medical.distress.repeat.dehydration",
                ["sourceSurface"] = "content/event/medical/repeat.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.dehydration.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I still need water to recover. My throat is on fire.",
                            },
                            ["TL"] = {
                                "Kailangan ko pa rin ng tubig para makabawi. Parang may apoy sa lalamunan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.dehydration.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still dying of thirst... did you find any bottle?",
                            },
                            ["TL"] = {
                                "Mamamatay pa rin sa uhaw... may nahanap ka bang bote?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.dehydration.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Water, please! I can't take this parched feeling.",
                            },
                            ["TL"] = {
                                "Tubig, pakiusap! Hindi ko na makayanan ang matinding uhaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.dehydration.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I asked for water... please tell me you have some.",
                            },
                            ["TL"] = {
                                "Humihingi ako ng tubig... sabihin mong may dala ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.dehydration.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Tongue feels like sandpaper. Bring water quickly.",
                            },
                            ["TL"] = {
                                "Parang liha ang dila ko. Magdala ka ng tubig agad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.dehydration.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still completely dehydrated. I can't stand up like this.",
                            },
                            ["TL"] = {
                                "Dehydrated pa rin ako. Hindi ako makakatayo nang ganito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.dehydration.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Water... I'm begging you, just one cup.",
                            },
                            ["TL"] = {
                                "Tubig... nagmamakaawa ako, kahit isang baso lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.dehydration.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still dry as bone. Please bring hydration.",
                            },
                            ["TL"] = {
                                "Tuyot pa rin ako. Pakiusap dalhan mo ako ng tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.dehydration.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I can't recover without liquids. Help me.",
                            },
                            ["TL"] = {
                                "Hindi ako makakabawi nang walang inumin. Tulong.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.dehydration.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still waiting for a drink... head is pounding.",
                            },
                            ["TL"] = {
                                "Naghihintay pa rin ng maiinom... sumasakit ang ulo ko.",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_repeat.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_repeat",
        ["id"] = "semantic.medical.distress.repeat.exhaustion",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.repeat.exhaustion",
            ["sourcePath"] = "psdl/dialogue/medical_event_repeat.json#records[4]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/MedicalEventRepeat/Catalog",
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
                ["responseTemplateID"] = "semantic.medical.distress.repeat.exhaustion",
                ["sourceSurface"] = "content/event/medical/repeat.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.exhaustion.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I still need a little more time to recover.",
                            },
                            ["TL"] = {
                                "Kailangan ko pa ng kaunting oras para makabawi.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.exhaustion.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Can't rush this. My muscles are completely dead.",
                            },
                            ["TL"] = {
                                "Hindi pwedeng madaliin. Patay na ang lakas ng kalamnan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.exhaustion.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still catching my breath. Give me another minute.",
                            },
                            ["TL"] = {
                                "Hinihingal pa rin ako. Bigyan mo pa ako ng isang minuto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.exhaustion.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Body won't budge yet. Just a bit more rest.",
                            },
                            ["TL"] = {
                                "Ayaw pang gumalaw ng katawan ko. Kaunting pahinga pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.exhaustion.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still wiped out. Don't force me to stand yet.",
                            },
                            ["TL"] = {
                                "Ubos pa rin ako. Huwag mo muna akong piliting tumayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.exhaustion.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Heart is still racing. Need more time sitting down.",
                            },
                            ["TL"] = {
                                "Mabilis pa rin ang kabog ng dibdib ko. Kailangan pang umupo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.exhaustion.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Not ready to move yet. Fatigue is overwhelming.",
                            },
                            ["TL"] = {
                                "Hindi pa handang kumilos. Masyadong mabigat ang pagod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.exhaustion.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Give me another thirty seconds... almost there.",
                            },
                            ["TL"] = {
                                "Bigyan mo pa ako ng tatlumpung segundo... malapit na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.exhaustion.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still completely spent. Let my legs rest.",
                            },
                            ["TL"] = {
                                "Sagad pa rin ang pagod. Pahingahin mo muna ang mga binti ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.exhaustion.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Can't run yet. Need a little more recovery.",
                            },
                            ["TL"] = {
                                "Hindi pa makakatakbo. Kailangan pa ng kaunting lakas.",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_repeat.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_repeat",
        ["id"] = "semantic.medical.distress.repeat.mercy",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.repeat.mercy",
            ["sourcePath"] = "psdl/dialogue/medical_event_repeat.json#records[5]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/MedicalEventRepeat/Catalog",
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
                ["responseTemplateID"] = "semantic.medical.distress.repeat.mercy",
                ["sourceSurface"] = "content/event/medical/repeat.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.mercy.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I am still asking you to spare me. Please.",
                            },
                            ["TL"] = {
                                "Hinihiling ko pa rin na buhayin mo ako. Pakiusap.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.mercy.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Please don't change your mind... let me live.",
                            },
                            ["TL"] = {
                                "Pakiusap huwag magbago ang isip mo... hayaan mo akong mabuhay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.mercy.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm still begging for mercy. Don't shoot.",
                            },
                            ["TL"] = {
                                "Nagmamakaawa pa rin ako sa awa. Huwag kang bumaril.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.mercy.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Show mercy once more. I mean you no harm.",
                            },
                            ["TL"] = {
                                "Maawa ka pa ulit. Wala akong masamang balak sa'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.mercy.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I am defenseless. Please keep your weapon down.",
                            },
                            ["TL"] = {
                                "Wala akong laban. Pakiusap ibaba mo ang sandata mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.mercy.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't finish me off. I surrender completely.",
                            },
                            ["TL"] = {
                                "Huwag mo akong tapusin. Sumusuko ako nang buo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.mercy.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still pleading for my life. Have pity on me.",
                            },
                            ["TL"] = {
                                "Nagmamakaawa pa rin para sa buhay ko. Kaawaan mo ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.mercy.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Please... I just want to survive.",
                            },
                            ["TL"] = {
                                "Pakiusap... gusto ko lang mabuhay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.mercy.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm at your feet. Spare me, I beg you.",
                            },
                            ["TL"] = {
                                "Nasa paanan mo na ako. Huwag mo akong patayin, nagmamakaawa ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.mercy.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't execute me. Let me crawl away.",
                            },
                            ["TL"] = {
                                "Huwag mo akong patayin. Hayaan mo akong gumapang palayo.",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_repeat.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_repeat",
        ["id"] = "semantic.medical.distress.repeat.rescue",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.repeat.rescue",
            ["sourcePath"] = "psdl/dialogue/medical_event_repeat.json#records[6]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/MedicalEventRepeat/Catalog",
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
                ["responseTemplateID"] = "semantic.medical.distress.repeat.rescue",
                ["sourceSurface"] = "content/event/medical/repeat.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.rescue.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I am still down here! Do not leave me!",
                            },
                            ["TL"] = {
                                "Nandito pa rin ako sa sahig! Huwag niyo akong iwan!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.rescue.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't abandon me! Come back and pull me out!",
                            },
                            ["TL"] = {
                                "Huwag niyo akong iwanan! Bumalik kayo at hilahin ako palabas!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.rescue.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still trapped in this spot! Need someone here!",
                            },
                            ["TL"] = {
                                "Naipit pa rin sa pwestong 'to! Kailangan ko ng tao rito!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.rescue.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Where are you going?! I can't walk!",
                            },
                            ["TL"] = {
                                "Saan ka pupunta?! Hindi ako makalakad!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.rescue.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Please come back! I'm completely stranded!",
                            },
                            ["TL"] = {
                                "Pakiusap bumalik ka! Nastranded ako nang buo!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.rescue.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't walk away from my cries! Help me!",
                            },
                            ["TL"] = {
                                "Huwag mong talikuran ang tawag ko! Tulungan mo ako!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.rescue.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still stuck under this weight! Lift it off!",
                            },
                            ["TL"] = {
                                "Naipit pa rin sa bigat na 'to! Buhatin mo 'to!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.rescue.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm still here! Get me out before they find me!",
                            },
                            ["TL"] = {
                                "Nandito pa rin ako! Ilabas mo ako bago nila ako makita!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.rescue.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Rescue me, damn it! I can't drag myself!",
                            },
                            ["TL"] = {
                                "Saklolohan mo ako! Hindi ko kayang kaladkarin ang sarili ko!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.rescue.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't leave me behind to rot! Come back!",
                            },
                            ["TL"] = {
                                "Huwag mo akong iwang mabulok dito! Bumalik ka!",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_repeat.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_repeat",
        ["id"] = "semantic.medical.distress.repeat.starvation",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.repeat.starvation",
            ["sourcePath"] = "psdl/dialogue/medical_event_repeat.json#records[7]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/MedicalEventRepeat/Catalog",
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
                ["responseTemplateID"] = "semantic.medical.distress.repeat.starvation",
                ["sourceSurface"] = "content/event/medical/repeat.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.starvation.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I still need something to eat. I'm fading fast.",
                            },
                            ["TL"] = {
                                "Kailangan ko pa rin ng makakain. Mabilis akong nanghihina.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.starvation.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still starving... any canned food, anything?",
                            },
                            ["TL"] = {
                                "Gutom na gutom pa rin... kahit anong de-lata, kahit ano?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.starvation.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Can't recover without calories. Bring food, please.",
                            },
                            ["TL"] = {
                                "Hindi makakabawi nang walang laman ang tiyan. Magdala ka ng pagkain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.starvation.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Stomach pains won't stop. I need nourishment.",
                            },
                            ["TL"] = {
                                "Ayaw tumigil ng sakit ng tiyan ko. Kailangan ko ng pagkain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.starvation.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still starving to the bone. Did you find a ration?",
                            },
                            ["TL"] = {
                                "Gutom na gutom pa rin hanggang buto. May nahanap ka bang rasyon?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.starvation.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Please hurry with some food. I'm too dizzy to stand.",
                            },
                            ["TL"] = {
                                "Pakiusap bilisan ang pagkain. Nahihilo na ako para makatayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.starvation.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Hunger is unbearable now. Help me.",
                            },
                            ["TL"] = {
                                "Hindi na makayanan ang gutom. Tulungan mo ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.starvation.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still haven't eaten. Don't let me starve on this floor.",
                            },
                            ["TL"] = {
                                "Wala pa ring kinakain. Huwag mo akong hayaang magutom sa sahig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.starvation.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Need a meal to get back on my feet.",
                            },
                            ["TL"] = {
                                "Kailangan ko ng makakain para makatayo ulit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.starvation.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still empty... please, just a cracker or some beans.",
                            },
                            ["TL"] = {
                                "Walang laman pa rin... kahit biskwit o kaunting beans lang.",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_repeat.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
