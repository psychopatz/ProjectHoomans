-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "medical_event_treatment",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress.treatment.bandage",
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
                                ["fallback"] = "The wound is treated. I can move when you are ready.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.medical.distress.treatment.bandage.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "The wound is treated. I can move when you are ready.",
                                        "Bandaged up tight. Good to go when you are.",
                                        "Bleeding has stopped. Ready to step out.",
                                        "Dressings are secure. I can walk now.",
                                        "That did the trick. I'm back on my feet.",
                                        "Wrapped up properly. Lead on.",
                                        "Wound is stabilized. Ready for your call.",
                                        "Bandage is holding. Let's get moving.",
                                        "Cleanly wrapped. I'm ready to follow.",
                                        "All patched up. Let's hit the road.",
                                    },
                                    ["TL"] = {
                                        "Nagamot na ang sugat. Makakakilos na ako kapag handa ka na.",
                                        "Nabendahan nang mahigpit. Handa nang umalis kapag handa ka na.",
                                        "Tumigil na ang dugo. Handa nang lumabas.",
                                        "Ligtas na ang benda. Makakalakad na ako ngayon.",
                                        "Bumisa 'yon. Nakatayo na ulit ako.",
                                        "Nabalot na nang maayos. Manguna ka na.",
                                        "Maayos na ang sugat. Handa sa utos mo.",
                                        "Kumakapit ang benda. Kilos na tayo.",
                                        "Malinis na nabalutan. Handa na akong sumunod.",
                                        "Maayos na ang lahat. Tara na sa daan.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.distress.treatment",
            ["textRoles"] = {
                {
                    ["fallback"] = "The wound is treated. I can move when you are ready.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.treatment.bandage.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "The wound is treated. I can move when you are ready.",
                            "Bandaged up tight. Good to go when you are.",
                            "Bleeding has stopped. Ready to step out.",
                            "Dressings are secure. I can walk now.",
                            "That did the trick. I'm back on my feet.",
                            "Wrapped up properly. Lead on.",
                            "Wound is stabilized. Ready for your call.",
                            "Bandage is holding. Let's get moving.",
                            "Cleanly wrapped. I'm ready to follow.",
                            "All patched up. Let's hit the road.",
                        },
                        ["TL"] = {
                            "Nagamot na ang sugat. Makakakilos na ako kapag handa ka na.",
                            "Nabendahan nang mahigpit. Handa nang umalis kapag handa ka na.",
                            "Tumigil na ang dugo. Handa nang lumabas.",
                            "Ligtas na ang benda. Makakalakad na ako ngayon.",
                            "Bumisa 'yon. Nakatayo na ulit ako.",
                            "Nabalot na nang maayos. Manguna ka na.",
                            "Maayos na ang sugat. Handa sa utos mo.",
                            "Kumakapit ang benda. Kilos na tayo.",
                            "Malinis na nabalutan. Handa na akong sumunod.",
                            "Maayos na ang lahat. Tara na sa daan.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "medical.distress.treatment.bandage",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "bandage",
            ["sourceId"] = "medical.distress.treatment.bandage",
            ["sourcePath"] = "adopters/hoomans/dialogue/medical_event_treatment/medical_distress_treatment_bandage.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalEventTreatment",
        ["namespace"] = "medical.distress.treatment",
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
                                        "The wound is treated. I can move when you are ready.",
                                        "Bandaged up tight. Good to go when you are.",
                                        "Bleeding has stopped. Ready to step out.",
                                        "Dressings are secure. I can walk now.",
                                        "That did the trick. I'm back on my feet.",
                                        "Wrapped up properly. Lead on.",
                                        "Wound is stabilized. Ready for your call.",
                                        "Bandage is holding. Let's get moving.",
                                        "Cleanly wrapped. I'm ready to follow.",
                                        "All patched up. Let's hit the road.",
                                    },
                                    ["TL"] = {
                                        "Nagamot na ang sugat. Makakakilos na ako kapag handa ka na.",
                                        "Nabendahan nang mahigpit. Handa nang umalis kapag handa ka na.",
                                        "Tumigil na ang dugo. Handa nang lumabas.",
                                        "Ligtas na ang benda. Makakalakad na ako ngayon.",
                                        "Bumisa 'yon. Nakatayo na ulit ako.",
                                        "Nabalot na nang maayos. Manguna ka na.",
                                        "Maayos na ang sugat. Handa sa utos mo.",
                                        "Kumakapit ang benda. Kilos na tayo.",
                                        "Malinis na nabalutan. Handa na akong sumunod.",
                                        "Maayos na ang lahat. Tara na sa daan.",
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
            ["responsePlanID"] = "medical.distress.treatment.bandage",
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
                            ["fallback"] = "The wound is treated. I can move when you are ready.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.medical.distress.treatment.bandage.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/medical_event_treatment/medical_distress_treatment_bandage.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "The wound is treated. I can move when you are ready.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.treatment.bandage.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "The wound is treated. I can move when you are ready.",
                        "Bandaged up tight. Good to go when you are.",
                        "Bleeding has stopped. Ready to step out.",
                        "Dressings are secure. I can walk now.",
                        "That did the trick. I'm back on my feet.",
                        "Wrapped up properly. Lead on.",
                        "Wound is stabilized. Ready for your call.",
                        "Bandage is holding. Let's get moving.",
                        "Cleanly wrapped. I'm ready to follow.",
                        "All patched up. Let's hit the road.",
                    },
                    ["TL"] = {
                        "Nagamot na ang sugat. Makakakilos na ako kapag handa ka na.",
                        "Nabendahan nang mahigpit. Handa nang umalis kapag handa ka na.",
                        "Tumigil na ang dugo. Handa nang lumabas.",
                        "Ligtas na ang benda. Makakalakad na ako ngayon.",
                        "Bumisa 'yon. Nakatayo na ulit ako.",
                        "Nabalot na nang maayos. Manguna ka na.",
                        "Maayos na ang sugat. Handa sa utos mo.",
                        "Kumakapit ang benda. Kilos na tayo.",
                        "Malinis na nabalutan. Handa na akong sumunod.",
                        "Maayos na ang lahat. Tara na sa daan.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_treatment",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress.treatment.default",
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
                                ["fallback"] = "Thank you. That treatment helped.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.medical.distress.treatment.default.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Thank you. That treatment helped.",
                                        "Feeling much better. I appreciate the aid.",
                                        "Much better now. Thank you for patching me up.",
                                        "Pain is subsiding. Thanks for taking care of it.",
                                        "Good work on that treatment. I'm indebted to you.",
                                        "That took the edge off. Thank you.",
                                        "I can function again. Thanks for the quick aid.",
                                        "Appreciate the medical help. I owe you one.",
                                        "Thanks, that helped a lot. Ready to move.",
                                        "You saved my skin with that aid. Thank you.",
                                    },
                                    ["TL"] = {
                                        "Salamat. Malaking tulong ang panggagamot na 'yon.",
                                        "Medyo maayos na pakiramdam ko. Salamat sa tulong.",
                                        "Mas maayos na ngayon. Salamat sa paggamot sa akin.",
                                        "Humuhupa na ang sakit. Salamat sa pag-asikaso no'n.",
                                        "Magaling ang panggagamot mo. May utang na loob ako sa'yo.",
                                        "Nabawasan ang kirot. Salamat sa'yo.",
                                        "Makakagalaw na ulit ako. Salamat sa mabilis na lunas.",
                                        "Salamat sa tulong medikal. May utang ako sa'yo.",
                                        "Salamat, malaking tulong 'yon. Handa nang kumilos.",
                                        "Iniligtas mo ang buhay ko sa lunas na 'yon. Maraming salamat.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.distress.treatment",
            ["textRoles"] = {
                {
                    ["fallback"] = "Thank you. That treatment helped.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.treatment.default.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Thank you. That treatment helped.",
                            "Feeling much better. I appreciate the aid.",
                            "Much better now. Thank you for patching me up.",
                            "Pain is subsiding. Thanks for taking care of it.",
                            "Good work on that treatment. I'm indebted to you.",
                            "That took the edge off. Thank you.",
                            "I can function again. Thanks for the quick aid.",
                            "Appreciate the medical help. I owe you one.",
                            "Thanks, that helped a lot. Ready to move.",
                            "You saved my skin with that aid. Thank you.",
                        },
                        ["TL"] = {
                            "Salamat. Malaking tulong ang panggagamot na 'yon.",
                            "Medyo maayos na pakiramdam ko. Salamat sa tulong.",
                            "Mas maayos na ngayon. Salamat sa paggamot sa akin.",
                            "Humuhupa na ang sakit. Salamat sa pag-asikaso no'n.",
                            "Magaling ang panggagamot mo. May utang na loob ako sa'yo.",
                            "Nabawasan ang kirot. Salamat sa'yo.",
                            "Makakagalaw na ulit ako. Salamat sa mabilis na lunas.",
                            "Salamat sa tulong medikal. May utang ako sa'yo.",
                            "Salamat, malaking tulong 'yon. Handa nang kumilos.",
                            "Iniligtas mo ang buhay ko sa lunas na 'yon. Maraming salamat.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "medical.distress.treatment.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "default",
            ["sourceId"] = "medical.distress.treatment.default",
            ["sourcePath"] = "adopters/hoomans/dialogue/medical_event_treatment/medical_distress_treatment_default.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalEventTreatment",
        ["namespace"] = "medical.distress.treatment",
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
                                        "Thank you. That treatment helped.",
                                        "Feeling much better. I appreciate the aid.",
                                        "Much better now. Thank you for patching me up.",
                                        "Pain is subsiding. Thanks for taking care of it.",
                                        "Good work on that treatment. I'm indebted to you.",
                                        "That took the edge off. Thank you.",
                                        "I can function again. Thanks for the quick aid.",
                                        "Appreciate the medical help. I owe you one.",
                                        "Thanks, that helped a lot. Ready to move.",
                                        "You saved my skin with that aid. Thank you.",
                                    },
                                    ["TL"] = {
                                        "Salamat. Malaking tulong ang panggagamot na 'yon.",
                                        "Medyo maayos na pakiramdam ko. Salamat sa tulong.",
                                        "Mas maayos na ngayon. Salamat sa paggamot sa akin.",
                                        "Humuhupa na ang sakit. Salamat sa pag-asikaso no'n.",
                                        "Magaling ang panggagamot mo. May utang na loob ako sa'yo.",
                                        "Nabawasan ang kirot. Salamat sa'yo.",
                                        "Makakagalaw na ulit ako. Salamat sa mabilis na lunas.",
                                        "Salamat sa tulong medikal. May utang ako sa'yo.",
                                        "Salamat, malaking tulong 'yon. Handa nang kumilos.",
                                        "Iniligtas mo ang buhay ko sa lunas na 'yon. Maraming salamat.",
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
            ["responsePlanID"] = "medical.distress.treatment.default",
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
                            ["fallback"] = "Thank you. That treatment helped.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.medical.distress.treatment.default.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/medical_event_treatment/medical_distress_treatment_default.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Thank you. That treatment helped.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.treatment.default.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Thank you. That treatment helped.",
                        "Feeling much better. I appreciate the aid.",
                        "Much better now. Thank you for patching me up.",
                        "Pain is subsiding. Thanks for taking care of it.",
                        "Good work on that treatment. I'm indebted to you.",
                        "That took the edge off. Thank you.",
                        "I can function again. Thanks for the quick aid.",
                        "Appreciate the medical help. I owe you one.",
                        "Thanks, that helped a lot. Ready to move.",
                        "You saved my skin with that aid. Thank you.",
                    },
                    ["TL"] = {
                        "Salamat. Malaking tulong ang panggagamot na 'yon.",
                        "Medyo maayos na pakiramdam ko. Salamat sa tulong.",
                        "Mas maayos na ngayon. Salamat sa paggamot sa akin.",
                        "Humuhupa na ang sakit. Salamat sa pag-asikaso no'n.",
                        "Magaling ang panggagamot mo. May utang na loob ako sa'yo.",
                        "Nabawasan ang kirot. Salamat sa'yo.",
                        "Makakagalaw na ulit ako. Salamat sa mabilis na lunas.",
                        "Salamat sa tulong medikal. May utang ako sa'yo.",
                        "Salamat, malaking tulong 'yon. Handa nang kumilos.",
                        "Iniligtas mo ang buhay ko sa lunas na 'yon. Maraming salamat.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
